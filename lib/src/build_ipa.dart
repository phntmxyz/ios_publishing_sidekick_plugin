import 'dart:async';
import 'dart:convert';

import 'package:dcli/dcli.dart';
import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/apple/export_options.dart';
import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/apple/keychain.dart';
import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/apple/p12.dart';
import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/apple/pbxproj.dart';
import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/apple/plist_writer.dart';
import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/apple/provisioning_profile.dart';
import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/util/git_utils.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Manually signs and archives a iOS project
///
/// Fastlane is great, but doing it manually is quite easy and spares us from having to install ruby
/// https://zach.codes/ios-builds-using-github-actions-without-fastlane/
///
/// [newKeychain] defaults to `false` but should be set to `true` on CI
///
/// [additionalProvisioningProfiles] is an optional map of bundle identifiers to provisioning profiles
/// for additional targets (e.g., app extensions like ShareExtension). The keys are the bundle identifiers
/// and the values are the corresponding provisioning profiles.
///
/// [targetBundleIds] is an optional map of target names to bundle identifiers. This allows you to
/// override the bundle identifier for specific targets during the build. The keys are the target names
/// (e.g., 'ShareExtension') and the values are the bundle identifiers to use for those targets.
///
/// Adjust [archiveSilenceTimeout] depending on your CI system. It is the time of the
/// `xcodebuild archive` process not outputting anything to stdout or stderr.
/// When it stops outputting (because it waits for a password input in the UI),
/// a [XcodeBuildArchiveTimeoutException] is thrown.
Future<File> buildIpa({
  required File certificate,
  String? certificatePassword,
  required ProvisioningProfile provisioningProfile,
  required ExportMethod method,
  required String bundleIdentifier,
  Map<String, ProvisioningProfile>? additionalProvisioningProfiles,
  Map<String, String>? targetBundleIds,
  bool? newKeychain,
  DartPackage? package,
  Duration archiveSilenceTimeout = const Duration(minutes: 3),
}) async {
  if (bundleIdentifier.contains('_')) {
    throw 'Bundle identifier must not contain underscores\n'
        'See https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleidentifier';
  }

  final project = package ?? mainProject!;

  installProvisioningProfile(provisioningProfile);
  final certificateInfo =
      readP12CertificateInfo(certificate, password: certificatePassword);

  final keyChain = () {
    final bool isCi = env['CI'] == 'true';
    if (newKeychain == true || isCi) {
      return Keychain(name: project.name)
        ..create(override: true)
        ..setAsDefault();
    }
    return Keychain.login();
  }();
  keyChain.unlock();
  keyChain.addPkcs12Certificate(certificate, password: certificatePassword);

  print('Building the ${project.name} iOS app using:');
  print('signingCertificate: ${certificateInfo.friendlyName}');
  print(
    'provisioningProfile: ${provisioningProfile.name} (${provisioningProfile.uuid})',
  );

  print('Adjusting Xcode project.pbxproj file');
  final pbxproj = project.root
      .file('ios/Runner.xcodeproj/project.pbxproj')
      .asXcodePbxproj();
  final revertLocalChanges = !pbxproj.file.hasLocalChanges();

  // Build provisioning profiles map for all targets
  final provisioningProfilesMap = <String, String>{
    bundleIdentifier: provisioningProfile.uuid,
  };

  // Add additional provisioning profiles (e.g., for ShareExtension)
  if (additionalProvisioningProfiles != null) {
    for (final entry in additionalProvisioningProfiles.entries) {
      provisioningProfilesMap[entry.key] = entry.value.uuid;
      print(
          'Adding provisioning profile: ${entry.key} -> ${entry.value.name} (${entry.value.uuid})');
    }
  }

  // See "xcodebuild -h" for available exportOptionsPlist keys.
  final exportOptions = {
    'compileBitcode': true,
    'destination': 'export',
    'method': method.value,
    'provisioningProfiles': provisioningProfilesMap,
    'signingCertificate': certificateInfo.friendlyName,
    'signingStyle': 'manual',
    'stripSwiftSymbols': true,
    'teamID': provisioningProfile.teamIdentifier,
    'thinning': '<none>',
  }.asPlist();

  final exportOptionsFile = project.buildDir.file('exportOptions.plist');
  exportOptionsFile.writeAsStringSync(exportOptions);

  final archive = project.buildDir.file('ios/archive.xcarchive');
  final exportDir = project.buildDir.directory('ios/ipa/Runner');

  try {
    // Archive
    try {
      await _xcodeBuildArchive(
        xcodeWorkspace: project.root.file('ios/Runner.xcworkspace'),
        archiveOutput: archive,
        provisioningProfile: provisioningProfile,
        certificateInfo: certificateInfo,
        bundleIdentifier: bundleIdentifier,
        targetBundleIds: targetBundleIds,
        silenceTimeout: archiveSilenceTimeout,
      );
    } on XcodeBuildArchiveTimeoutException catch (_) {
      print(red('Xcode build archive stopped responding, trying again.'));
      print(
        "Make sure to use newKeychain=true with Github Actions. Use newKeychain: env['CI'] == 'true'",
      );
      rethrow;
    }

    // unlock keychain again, in case the build took too long
    keyChain.unlock();

    // Export ipa
    startFromArgs(
      'xcodebuild',
      [
        '-exportArchive',
        ...['-archivePath', archive.path],
        ...['-exportOptionsPlist', exportOptionsFile.path],
        ...['-exportPath', exportDir.path],
      ],
      workingDirectory: project.root.absolute.path,
    );
  } finally {
    // Clean up
    if (newKeychain == true) {
      await keyChain.file?.delete();
    }
    if (revertLocalChanges) {
      try {
        pbxproj.file.discardLocalChanges();
      } catch (e) {
        printerr('Failed to revert changes of ${pbxproj.file.path}');
      }
    }
  }

  final ipa = exportDir
      .listSync()
      .whereType<File>()
      .firstWhere((file) => file.name.endsWith('.ipa'));

  return ipa;
}

/// xcodebuild archive but with timeout in case it hangs
Future<void> _xcodeBuildArchive({
  required File xcodeWorkspace,
  required File archiveOutput,
  required ProvisioningProfile provisioningProfile,
  required P12CertificateInfo certificateInfo,
  required String bundleIdentifier,
  Map<String, String>? targetBundleIds,
  Duration silenceTimeout = const Duration(minutes: 3),
}) async {
  final completer = Completer<void>();
  Timer? timeoutTimer;
  Process? process;
  StreamSubscription<String>? stdoutSubscription;
  StreamSubscription<String>? stderrSubscription;

  void cleanup() {
    if (timeoutTimer != null) {
      timeoutTimer?.cancel();
    }
    if (stdoutSubscription != null) {
      stdoutSubscription.cancel();
    }
    if (stderrSubscription != null) {
      stderrSubscription.cancel();
    }
  }

  void restartTimeoutTimer() {
    timeoutTimer?.cancel();
    if (completer.isCompleted) return;
    // xcodebuild prints a lot, being silent for a while is not a good sign
    timeoutTimer = Timer(silenceTimeout, () {
      cleanup();
      completer.completeError(XcodeBuildArchiveTimeoutException());
      process?.kill();
    });
  }

  final args = [
    'archive',
    ...['-workspace', xcodeWorkspace.path],
    ...['-scheme', 'Runner'],
    ...['-sdk', 'iphoneos'],
    ...['-configuration', 'Release'],
    ...['-archivePath', archiveOutput.path],
    'CODE_SIGN_STYLE=Manual',
    'CODE_SIGN_IDENTITY=${certificateInfo.friendlyName}',
    'DEVELOPMENT_TEAM=${provisioningProfile.teamIdentifier}',
  ];

  // Override bundle identifier for the main Runner target
  // We pass build settings in the format TargetName:BUILD_SETTING=value to xcodebuild.
  // This allows us to set different bundle identifiers for different targets in a single build.
  args.add('Runner:PRODUCT_BUNDLE_IDENTIFIER=$bundleIdentifier');
  print('Setting Bundle ID for Runner: $bundleIdentifier');

  // Override bundle identifiers for additional targets (e.g., app extensions)
  if (targetBundleIds != null) {
    for (final entry in targetBundleIds.entries) {
      args.add('${entry.key}:PRODUCT_BUNDLE_IDENTIFIER=${entry.value}');
      print('Setting Bundle ID for ${entry.key}: ${entry.value}');
    }
  }

  print("xcodebuild ${args.join(' ')}");
  process = await Process.start(
    'xcodebuild',
    args,
    workingDirectory: xcodeWorkspace.parent.path,
  );
  stdoutSubscription = process.stdout.transform(utf8.decoder).listen((line) {
    if (completer.isCompleted) return;
    print(line);
    restartTimeoutTimer();
  });
  stderrSubscription = process.stderr.transform(utf8.decoder).listen((line) {
    if (completer.isCompleted) return;
    printerr(line);
    restartTimeoutTimer();
  });
  await process.exitCode.then((exitCode) {
    cleanup();
    if (exitCode == 0) {
      completer.complete();
    } else {
      completer
          .completeError('xcodebuild archive failed with exit code $exitCode');
    }
  });
  return completer.future;
}

class XcodeBuildArchiveTimeoutException implements Exception {
  XcodeBuildArchiveTimeoutException();
}
