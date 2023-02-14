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
  final project = package ?? mainProject!;

  installProvisioningProfile(provisioningProfile);
  final certificateInfo = readP12CertificateInfo(certificate);

  final keyChain = newKeychain == true
      ? (Keychain(name: 'invo')
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

    // Archive app
    startFromArgs(
      'xcodebuild',
      [
        'archive',
        ...['-workspace', project.root.file('ios/Runner.xcworkspace').path],
        ...['-scheme', 'Runner'],
        ...['-sdk', 'iphoneos'],
        ...['-configuration', 'Release'],
        ...['-archivePath', archive.path],
        'CODE_SIGN_STYLE=Manual',
        'PROVISIONING_PROFILE="${provisioningProfile.uuid}"',
        'CODE_SIGN_IDENTITY=${certificateInfo.friendlyName}',
      ],
      workingDirectory: project.root.absolute.path,
    );

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
