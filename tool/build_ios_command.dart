// language=Dart
const String buildIosCommand = r'''
import 'package:phntm_release_ios_sidekick_plugin/phntm_release_ios_sidekick_plugin.dart';
import 'package:sidekick_core/sidekick_core.dart';

class BuildIosCommand extends Command {
  @override
  String get description => 'Build the application for iOS';

  @override
  String get name => 'build-ios';

  late final Directory _releaseDir = mainProject!.buildDir.directory('release');

  @override
  Future<void> run() async {
    if (!Platform.isMacOS) {
      throw "building the iOS app only works on macOS, "
          "not ${Platform.operatingSystem}";
    }

    final distribution = argResults!['distribution'] as String?;
    print('Building iOS app for distribution $distribution');
    if (!mainProject!.buildDir.existsSync()) {
      mainProject!.buildDir.createSync();
    }
    if (_releaseDir.existsSync()) {
      _releaseDir.deleteSync(recursive: true);
    }

    flutter(
      ['build', 'ios', '--config-only'],
      workingDirectory: mainProject!.root,
    );

    // TODO locate your provisioning profile
    final provisioningProfile = mainProject!.root
        .file('ios/appstore.mobileprovision.gpg')
        .asProvisioningProfile();
    // TODO locate your signing certificate
    final certificate =
    mainProject!.root.file('ios/ios_distribution_certificate.p12.gpg');

    // // Alternatively load the file from a secure location, i.e. sidekick_vault
    // // <cli> sidekick plugins install sidekick_vault
    // late final SidekickVault vault = SidekickVault(
    //   location: mainProject!.root.directory('ios/vault'),
    //   environmentVariableName: 'ios_vault',
    // );
    // final provisioningProfile =
    //     vault.loadFile('appstore.mobileprovision.gpg').asProvisioningProfile();
    // final certificate = vault.loadFile('ios_distribution_certificate.p12.gpg');

    final ipa = buildIpa(
      // TODO set your bundle identifier
      bundleIdentifier: 'com.example.app',
      provisioningProfile: provisioningProfile,
      certificate: certificate,
      method: ExportMethod.appStore,
      newKeychain: env['CI'] == 'true',
    );

    _copyIpaToReleaseDir(ipa);
  }

  /// Place the ipa properly named in the /build/release directory
  File _copyIpaToReleaseDir(File ipaFile) {
    final File versionFile = mainProject!.pubspec;
    final pubSpec = PubSpec.fromFile(versionFile.absolute.path);
    final version = pubSpec.version;
    _releaseDir.createSync(recursive: true);
    final releaseIpa = _releaseDir.file('${pubSpec.name}-$version.ipa');
    ipaFile.copySync(releaseIpa.absolute.path);
    return releaseIpa;
  }
}
''';
