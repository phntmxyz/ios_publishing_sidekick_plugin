import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';
import 'package:pubspec_manager/pubspec_manager.dart';
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

    print('Building iOS app (ipa)');
    if (!mainProject!.buildDir.existsSync()) {
      mainProject!.buildDir.createSync();
    }
    if (_releaseDir.existsSync()) {
      _releaseDir.deleteSync(recursive: true);
    }

    // Load iOS dependencies and build dart source
    flutter(
      [
        'build',
        'ios',
        '--config-only',
      ],
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

    // Build the ipa with manual signing
    final ipa = await buildIpa(
      // TODO set your bundle identifier
      bundleIdentifier: 'com.example.app',
      provisioningProfile: provisioningProfile,
      certificate: certificate,
      method: ExportMethod.appStoreConnect,
      newKeychain: env['CI'] == 'true',
    );

    _copyIpaToReleaseDir(ipa);
  }

  /// Place the ipa properly named in the /build/release directory
  File _copyIpaToReleaseDir(File ipaFile) {
    final File versionFile = mainProject!.pubspec;
    final pubSpec = PubSpec.loadFromPath(versionFile.absolute.path);
    final version = pubSpec.version;
    _releaseDir.createSync(recursive: true);
    final releaseIpa = _releaseDir.file('${pubSpec.name}-$version.ipa');
    ipaFile.copySync(releaseIpa.absolute.path);
    return releaseIpa;
  }
}
