// ignore_for_file: unused_local_variable, avoid_print

import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

/// Complete workflow examples for iOS publishing.
void main() async {
  // Example 1: Full Publishing Workflow
  await publishApp(
    bundleId: 'com.example.myapp',
    version: '1.0.0',
    buildNumber: '42',
  );

  // Example 2: Multi-Target App with Extensions
  await buildAppWithExtensions();
}

/// Full publishing workflow.
Future<File> publishApp({
  required String bundleId,
  required String version,
  required String buildNumber,
}) async {
  print('Starting iOS build for version $version ($buildNumber)');

  // 1. Update Info.plist
  final infoPlist = File('ios/Runner/Info.plist').asXcodePlist();
  infoPlist.setBundleIdentifier(bundleId);
  infoPlist.setStringValue('CFBundleShortVersionString', version);
  infoPlist.setStringValue('CFBundleVersion', buildNumber);

  // 2. Update pbxproj
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').asXcodePbxproj();
  pbxproj.setBundleIdentifier(bundleId);
  pbxproj.setCodeSignStyle('Manual');
  pbxproj.setProvisioningProfileSpecifier('My App Store Profile');

  // 3. Load provisioning profile
  final profile =
      File('profiles/AppStore.mobileprovision').asProvisioningProfile();

  // 4. Validate profile
  final daysValid = profile.expirationDate.difference(DateTime.now()).inDays;
  if (daysValid < 0) {
    throw Exception('Provisioning profile expired!');
  }
  print('✓ Profile valid for $daysValid days');

  // 5. Install profile
  installProvisioningProfile(profile);

  // 6. Build IPA
  final ipa = await buildIpa(
    certificate: File('certificates/distribution.p12'),
    certificatePassword: Platform.environment['CERT_PASSWORD'],
    provisioningProfile: profile,
    method: ExportMethod.appStoreConnect,
    bundleIdentifier: bundleId,
  );

  print('✓ Successfully built: ${ipa.path}');
  return ipa;
}

/// Build app with extensions.
Future<File> buildAppWithExtensions() async {
  const bundleId = 'com.example.myapp';

  // Configure main app plist
  final appPlist = File('ios/Runner/Info.plist').asXcodePlist();
  appPlist.setBundleIdentifier(bundleId);
  appPlist.setAppGroupId('group.$bundleId');
  appPlist.setArrayValue('com.apple.security.application-groups', [
    'group.$bundleId',
  ]);

  // Configure Share Extension plist
  final sharePlist = File('ios/ShareExtension/Info.plist').asXcodePlist();
  sharePlist.setBundleIdentifier('$bundleId.ShareExtension');
  sharePlist.setAppGroupId('group.$bundleId');
  sharePlist.setArrayValue('com.apple.security.application-groups', [
    'group.$bundleId',
  ]);

  // Configure pbxproj
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').asXcodePbxproj();
  pbxproj.setBundleIdentifier(bundleId);
  pbxproj.setExtensionBundleIdentifier(
    extensionName: 'ShareExtension',
    bundleIdentifier: '$bundleId.ShareExtension',
  );
  pbxproj.setExtensionProvisioningProfile(
    extensionName: 'ShareExtension',
    provisioningProfileName: 'Share Extension Profile',
  );

  // Load profiles
  final mainProfile =
      File('profiles/AppStore.mobileprovision').asProvisioningProfile();
  final shareProfile =
      File('profiles/ShareExtension.mobileprovision').asProvisioningProfile();

  // Build
  return await buildIpa(
    certificate: File('certificates/distribution.p12'),
    certificatePassword: Platform.environment['CERT_PASSWORD'],
    provisioningProfile: mainProfile,
    method: ExportMethod.appStoreConnect,
    bundleIdentifier: bundleId,
    additionalProvisioningProfiles: {
      '$bundleId.ShareExtension': shareProfile,
    },
    targetBundleIds: {
      'ShareExtension': '$bundleId.ShareExtension',
    },
  );
}
