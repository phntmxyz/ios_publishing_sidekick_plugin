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
File buildIpa({
  required File certificate,
  required ProvisioningProfile provisioningProfile,
  required ExportMethod method,
  required String bundleIdentifier,
  bool? newKeychain,
  DartPackage? package,
}) {
  if (bundleIdentifier.contains('_')) {
    throw 'Bundle identifier must not contain underscores\n'
        'See https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleidentifier';
  }

  final project = package ?? mainProject!;

  installProvisioningProfile(provisioningProfile);
  final certificateInfo = readP12CertificateInfo(certificate);

  final keyChain = newKeychain == true
      ? (Keychain(name: project.name)
        ..create(override: true)
        ..setAsDefault())
      : Keychain.login();
  keyChain.addPkcs12Certificate(certificate);
  keyChain.unlock();

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

  // See "xcodebuild -h" for available exportOptionsPlist keys.
  final exportOptions = {
    'compileBitcode': true,
    'destination': 'export',
    'method': method.value,
    'provisioningProfiles': {
      bundleIdentifier: provisioningProfile.uuid,
    },
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
    pbxproj.setBundleIdentifier(bundleIdentifier);
    pbxproj.setProvisioningProfileSpecifier(provisioningProfile.name);

    /// xcodebuild archive but with timeout in case it hangs
    Future<void> xcodeBuildArchive() async {
      final completer = Completer<void>();
      Timer? timeoutTimer;
      Process? process;
      void restartTimeoutTimer() {
        timeoutTimer?.cancel();
        if (completer.isCompleted) return;
        // xcodebuild prints a lot, being silent for a while is not a good sign
        timeoutTimer = Timer(const Duration(minutes: 3), () {
          completer.completeError(XcodeBuildArchiveTimeoutException());
          process?.kill();
        });
      }

      final args = [
        'archive',
        ...['-workspace', project.root.file('ios/Runner.xcworkspace').path],
        ...['-scheme', 'Runner'],
        ...['-sdk', 'iphoneos'],
        ...['-configuration', 'Release'],
        ...['-archivePath', archive.path],
        'CODE_SIGN_STYLE=Manual',
        'PROVISIONING_PROFILE="${provisioningProfile.uuid}"',
        'CODE_SIGN_IDENTITY=${certificateInfo.friendlyName}',
      ];

      print("xcodebuild ${args.join(' ')}");
      process = await Process.start(
        'xcodebuild',
        args,
        workingDirectory: project.root.absolute.path,
      );
      process.stdout.transform(utf8.decoder).listen((line) {
        if (completer.isCompleted) return;
        print(line);
        restartTimeoutTimer();
      });
      process.stderr.transform(utf8.decoder).listen((line) {
        if (completer.isCompleted) return;
        printerr(line);
        restartTimeoutTimer();
      });
      process.exitCode.then((exitCode) {
        if (exitCode == 0) {
          timeoutTimer?.cancel();
          completer.complete();
        } else {
          completer.completeError(
              'xcodebuild archive failed with exit code $exitCode');
        }
      });
      return completer.future;
    }

    // Archive
    try {
      waitForEx(xcodeBuildArchive());
    } on XcodeBuildArchiveTimeoutException catch (_) {
      print(red('Xcode build archive stopped responding, trying again.'));
      print(
        "Make sure to use newKeychain=true with Github Actions. Use newKeychain: env['CI'] == 'true', ",
      );
      // try again, it is usually faster the second time.
      // Hopefully fast enough to run before the keychain locks
      keyChain.unlock();
      waitForEx(xcodeBuildArchive());
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
      keyChain.file?.delete();
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

class XcodeBuildArchiveTimeoutException implements Exception {
  XcodeBuildArchiveTimeoutException();
}
