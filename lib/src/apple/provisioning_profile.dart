import 'package:dcli/dcli.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:plist_parser/plist_parser.dart';
import 'package:sidekick_core/sidekick_core.dart';

class ProvisioningProfile {
  final File file;

  ProvisioningProfile({
    required this.file,
  });

  File? _clearTextFile;

  File get clearTextFile {
    if (_clearTextFile == null || !_clearTextFile!.existsSync()) {
      final out = file.parent.file('${file.name}.plist');
      // Convert Cryptographic Message Syntax (CMS) to plain text (https://datatracker.ietf.org/doc/html/rfc3852)
      final p = startFromArgs('security', [
        'cms',
        '-D',
        '-i',
        file.absolute.path,
        '-o',
        out.absolute.path,
      ]);
      if (p.exitCode != 0) {
        throw "decrypting provisioning profile failed with exit code ${p.exitCode}";
      }
      if (!out.existsSync()) {
        throw "couldn't find decrypted provisioning profile";
      }
      _clearTextFile = out;
    }
    return _clearTextFile!;
  }

  Map<dynamic, dynamic>? _plistData;

  Map<dynamic, dynamic> get plistData {
    _plistData ??= PlistParser().parse(clearTextFile.readAsStringSync());

    return _plistData!;
  }

  String get uuid => pick(plistData, 'UUID').asStringOrThrow();

  String get teamIdentifier =>
      pick(plistData, 'TeamIdentifier', 0).asStringOrThrow();

  String get applicationIdentifierPrefix =>
      pick(plistData, 'ApplicationIdentifierPrefix', 0).asStringOrThrow();

  String get teamName => pick(plistData, 'TeamName').asStringOrThrow();

  List<String> get platform =>
      pick(plistData, 'Platform').asListOrEmpty((it) => it.asStringOrThrow());

  DateTime get creationDate =>
      pick(plistData, 'CreationDate').asDateTimeOrThrow();

  DateTime get expirationDate =>
      pick(plistData, 'ExpirationDate').asDateTimeOrThrow();

  bool get isXcodeManaged => pick(plistData, 'IsXcodeManaged').asBoolOrThrow();

  String get provisioningProfileId =>
      pick(plistData, 'provisioningProfileId').asStringOrThrow();

  String get appIdName => pick(plistData, 'AppIDName').asStringOrThrow();

  String get name => pick(plistData, 'Name').asStringOrThrow();

  int get timeToLive => pick(plistData, 'TimeToLive').asIntOrThrow();

  int get version => pick(plistData, 'Version').asIntOrThrow();

  List<String> get provisionedDevices => pick(plistData, 'ProvisionedDevices')
      .asListOrEmpty((it) => it.asStringOrThrow());

  // more fields
  // DER-Encoded-Profile
  // PPQCheck
  // Entitlements
  // PPQCheck
}

extension ProvisioningProfileFile on File {
  ProvisioningProfile asProvisioningProfile() {
    return ProvisioningProfile(file: this);
  }
}

/// Installs the provisioning profile on the dev machine
void installProvisioningProfile(ProvisioningProfile provisioningProfile) {
  final installedProvisioningProfile = File(
    '${env['HOME']}/Library/MobileDevice/Provisioning Profiles/${provisioningProfile.uuid}.mobileprovision',
  );

  // copy fails for some reason manually writing the file works
  // https://zach.codes/ios-builds-using-github-actions-without-fastlane/#add-cert-profile-to-the-repo
  if (!installedProvisioningProfile.existsSync()) {
    installedProvisioningProfile.createSync(recursive: true);
  }
  installedProvisioningProfile
      .writeAsBytesSync(provisioningProfile.file.readAsBytesSync());

  print(
    'Installed provisioning profile "${provisioningProfile.name}" (${provisioningProfile.uuid})',
  );
}
