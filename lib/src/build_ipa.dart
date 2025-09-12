import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;

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
      print('Adding provisioning profile: ${entry.key} -> ${entry.value.name} (${entry.value.uuid})');
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
    // LETZTE CHANCE: Set target-specific Provisioning Profiles in pbxproj HIER!
    if (additionalProvisioningProfiles != null) {
      _setTargetSpecificProvisioningProfiles(pbxproj, provisioningProfile, additionalProvisioningProfiles);
    } else {
      print('Main App will use: $bundleIdentifier with ${provisioningProfile.name}');
    }

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

/// Sets target-specific provisioning profiles for Runner and ShareExtension
void _setTargetSpecificProvisioningProfiles(
  XcodePbxproj pbxproj, 
  ProvisioningProfile mainProfile, 
  Map<String, ProvisioningProfile> additionalProfiles
) {
  
  String content = pbxproj.file.readAsStringSync();
  final lines = content.split('\n');
  
  // Set Runner provisioning profiles
  for (int i = 0; i < lines.length; i++) {
    if (!lines[i].contains('PROVISIONING_PROFILE_SPECIFIER')) continue;
    
    bool isRunner = false;
    for (int j = Math.max(0, i - 10); j < Math.min(lines.length, i + 10); j++) {
      if (lines[j].contains('name = Runner') || lines[j].contains('/* Runner */')) {
        isRunner = true;
        break;
      }
    }
    
    if (isRunner) {
      lines[i] = _replaceProvisioningProfile(lines[i], mainProfile.name);
    }
  }
  
  // Add ShareExtension provisioning profiles
  for (final entry in additionalProfiles.entries) {
    if (entry.key.contains('ShareExtension')) {
      _addShareExtensionProvisioningProfile(lines, entry.value.name);
      break;
    }
  }
  
  pbxproj.file.writeAsStringSync(lines.join('\n'));
}

/// Adds provisioning profile settings to ShareExtension build configurations
void _addShareExtensionProvisioningProfile(List<String> lines, String profileName) {
  
  // Finde alle ShareExtension buildSettings Sectionen
  for (int i = 0; i < lines.length; i++) {
    // Suche nach ShareExtension buildSettings
    if (lines[i].contains('buildSettings = {')) {
      // Prüfe ob das eine ShareExtension Section ist
      bool isShareExtensionSection = false;
      
      // Schaue 20 Zeilen vorher und nachher nach ShareExtension
      for (int j = Math.max(0, i - 20); j < Math.min(lines.length, i + 20); j++) {
        if (lines[j].contains('ShareExtension') && 
            (lines[j].contains('Debug') || lines[j].contains('Release') || lines[j].contains('Profile'))) {
          isShareExtensionSection = true;
          break;
        }
      }
      
      if (isShareExtensionSection) {
        // Finde das richtige ShareExtension Bundle ID aus targetBundleIds
        String? shareExtensionBundleId;
        // TODO: targetBundleIds von außen übergeben - für jetzt hardcode firebase
        shareExtensionBundleId = 'xyz.phntm.vodafone.noascan.firebase.ShareExtension';
        
        // 1. ERSETZE EXISTIERENDE BUNDLE IDs IN DIESER SECTION
        for (int k = i; k < lines.length; k++) {
          if (lines[k].contains('}') && !lines[k].contains('{')) break; // Ende der Section
          
          if (lines[k].contains('PRODUCT_BUNDLE_IDENTIFIER') && shareExtensionBundleId != null) {
            lines[k] = lines[k].replaceAll(
              RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*;'),
              'PRODUCT_BUNDLE_IDENTIFIER = $shareExtensionBundleId;'
            );
            print('✅ Updated ShareExtension Bundle ID at line ${k + 1}: $shareExtensionBundleId');
          }
          
          if (lines[k].contains('CODE_SIGN_STYLE')) {
            lines[k] = lines[k].replaceAll(
              RegExp(r'CODE_SIGN_STYLE = [^;]*;'),
              'CODE_SIGN_STYLE = Manual;'
            );
          }
        }
        
        // 2. FÜGE PROVISIONING PROFILE HINZU (falls nicht existiert)
        int endBrace = -1;
        int braceCount = 0;
        for (int k = i; k < lines.length; k++) {
          if (lines[k].contains('{')) braceCount++;
          if (lines[k].contains('}')) {
            braceCount--;
            if (braceCount == 0) {
              endBrace = k;
              break;
            }
          }
        }
        
        if (endBrace > i) {
          // Prüfe ob PROVISIONING_PROFILE_SPECIFIER schon existiert
          bool hasProvisioningProfile = false;
          for (int k = i; k < endBrace; k++) {
            if (lines[k].contains('PROVISIONING_PROFILE_SPECIFIER')) {
              hasProvisioningProfile = true;
              lines[k] = _replaceProvisioningProfile(lines[k], profileName);
              break;
            }
          }
          
          if (!hasProvisioningProfile) {
            lines.insert(endBrace, '\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "$profileName";');
            print('✅ Added ShareExtension provisioning profile at line ${endBrace + 1}: $profileName');
          }
        }
      }
    }
  }
}

/// Helper: Ersetzt Provisioning Profile in einer Zeile ohne Regex
String _replaceProvisioningProfile(String line, String newProfileName) {
  if (!line.contains('PROVISIONING_PROFILE_SPECIFIER = ')) return line;
  
  final startIndex = line.indexOf('PROVISIONING_PROFILE_SPECIFIER = ');
  final endIndex = line.indexOf(';', startIndex);
  
  if (endIndex == -1) return line;
  
  return line.substring(0, startIndex) + 
         'PROVISIONING_PROFILE_SPECIFIER = "$newProfileName"' + 
         line.substring(endIndex);
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

  void restartTimeoutTimer() {
    timeoutTimer?.cancel();
    if (completer.isCompleted) return;
    // xcodebuild prints a lot, being silent for a while is not a good sign
    timeoutTimer = Timer(silenceTimeout, () {
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
    // KEINE GLOBALE PROVISIONING_PROFILE - pbxproj hat die richtigen target-spezifischen!
    'CODE_SIGN_IDENTITY=${certificateInfo.friendlyName}',
    'DEVELOPMENT_TEAM=${provisioningProfile.teamIdentifier}',
    // KEIN GLOBALES PRODUCT_BUNDLE_IDENTIFIER - würde alle Targets überschreiben!
    // pbxproj hat die richtigen target-spezifischen Bundle IDs
  ];
  
  // Target-spezifische Bundle IDs für ALLE Targets hinzufügen (statt globalem Parameter)
  args.add('Runner:PRODUCT_BUNDLE_IDENTIFIER=$bundleIdentifier');
  print('Setting Bundle ID for Runner: $bundleIdentifier');
  
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
  await process.exitCode.then((exitCode) {
    if (exitCode == 0) {
      timeoutTimer?.cancel();
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
