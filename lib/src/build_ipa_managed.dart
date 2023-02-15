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
File buildIpaManaged({
  DartPackage? package,
  required String bundleIdentifier,
  required String developmentTeam,
  required String appleApiToken,
}) {
  final keyChain = Keychain.login();
  keyChain.unlock();

  print('Adjusting Xcode project.pbxproj file');
  final pbxproj = mainProject!.root
      .file('ios/Runner.xcodeproj/project.pbxproj')
      .asXcodePbxproj();
  final revertLocalChanges = !pbxproj.file.hasLocalChanges();

  // See "xcodebuild -h" for available exportOptionsPlist keys.
  final exportOptions = {
    'compileBitcode': true,
    'destination': 'export',
    'method': 'development',
    'signingStyle': 'automatic',
    'stripSwiftSymbols': true,
    'thinning': '<none>',
  }.asPlist();

  final exportOptionsFile = mainProject!.buildDir.file('exportOptions.plist');
  exportOptionsFile.writeAsStringSync(exportOptions);

  final archive = mainProject!.buildDir.file('ios/archive.xcarchive');
  final exportDir = mainProject!.buildDir.directory('ios/ipa/Runner');

  try {
    pbxproj.setBundleIdentifier(bundleIdentifier);
    pbxproj.setDevelopmentTeam(developmentTeam);

    // Archive app
    startFromArgs(
      'xcodebuild',
      [
        'archive',
        ...[
          '-workspace',
          mainProject!.root.file('ios/Runner.xcworkspace').path
        ],
        ...['-scheme', 'Runner'],
        ...['-sdk', 'iphoneos'],
        ...['-configuration', 'Release'],
        ...['-archivePath', archive.path],
        'CODE_SIGN_STYLE=Automatic',
      ],
      workingDirectory: mainProject!.root.absolute.path,
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
      workingDirectory: mainProject!.root.absolute.path,
    );
  } finally {
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
