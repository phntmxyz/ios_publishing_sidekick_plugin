// ignore_for_file: unused_local_variable, avoid_print

import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

/// Examples of building iOS applications (IPAs).
void main() async {
  // Example 1: Simple IPA Build
  await simpleIpaBuild();

  // Example 2: Advanced IPA Build with Extensions
  await advancedIpaBuildWithExtensions();

  // Example 3: Different Export Methods
  await differentExportMethods();

  // Example 4: CI/CD Build Example
  await buildForCI();
}

/// Basic App Store build.
Future<void> simpleIpaBuild() async {
  final ipa = await buildIpa(
    certificate: File('certificates/distribution.p12'),
    certificatePassword: 'cert-password',
    provisioningProfile:
        File('profiles/AppStore.mobileprovision').asProvisioningProfile(),
    method: ExportMethod.appStoreConnect,
    bundleIdentifier: 'com.example.myapp',
  );

  print('IPA created: ${ipa.path}');
}

/// Build with App Extensions.
Future<void> advancedIpaBuildWithExtensions() async {
  final mainProfile =
      File('profiles/AppStore.mobileprovision').asProvisioningProfile();
  final shareProfile =
      File('profiles/ShareExtension.mobileprovision').asProvisioningProfile();
  final notificationProfile =
      File('profiles/NotificationService.mobileprovision')
          .asProvisioningProfile();

  final ipa = await buildIpa(
    certificate: File('certificates/distribution.p12'),
    certificatePassword: 'cert-password',
    provisioningProfile: mainProfile,
    method: ExportMethod.appStoreConnect,
    bundleIdentifier: 'com.example.myapp',

    // Additional provisioning profiles for extensions
    additionalProvisioningProfiles: {
      'com.example.myapp.ShareExtension': shareProfile,
      'com.example.myapp.NotificationService': notificationProfile,
    },

    // Map extension target names to bundle IDs
    targetBundleIds: {
      'ShareExtension': 'com.example.myapp.ShareExtension',
      'NotificationService': 'com.example.myapp.NotificationService',
    },

    // Create fresh keychain on CI
    newKeychain: true,

    // Custom archive timeout
    archiveSilenceTimeout: const Duration(minutes: 5),
  );

  print('IPA with extensions created: ${ipa.path}');
}

/// Examples of different export methods.
Future<void> differentExportMethods() async {
  // Placeholder profiles for demonstration
  final appStoreProfile =
      File('profiles/AppStore.mobileprovision').asProvisioningProfile();
  final adHocProfile =
      File('profiles/AdHoc.mobileprovision').asProvisioningProfile();
  final enterpriseProfile =
      File('profiles/Enterprise.mobileprovision').asProvisioningProfile();
  final developmentProfile =
      File('profiles/Development.mobileprovision').asProvisioningProfile();

  // App Store Connect
  final appStoreIpa = await buildIpa(
    certificate: File('certs/distribution.p12'),
    certificatePassword: 'password',
    provisioningProfile: appStoreProfile,
    method: ExportMethod.appStoreConnect,
    bundleIdentifier: 'com.example.myapp',
  );

  // Ad Hoc (Testing)
  final adHocIpa = await buildIpa(
    certificate: File('certs/distribution.p12'),
    certificatePassword: 'password',
    provisioningProfile: adHocProfile,
    method: ExportMethod.releaseTesting,
    bundleIdentifier: 'com.example.myapp',
  );

  // Enterprise Distribution
  final enterpriseIpa = await buildIpa(
    certificate: File('certs/enterprise.p12'),
    certificatePassword: 'password',
    provisioningProfile: enterpriseProfile,
    method: ExportMethod.enterprise,
    bundleIdentifier: 'com.example.myapp',
  );

  // Development (for device testing)
  final devIpa = await buildIpa(
    certificate: File('certs/development.p12'),
    certificatePassword: 'password',
    provisioningProfile: developmentProfile,
    method: ExportMethod.package,
    bundleIdentifier: 'com.example.myapp',
  );
}

/// CI/CD build example.
Future<void> buildForCI() async {
  // Check if running on CI
  final isCI = Platform.environment['CI'] == 'true';

  try {
    final ipa = await buildIpa(
      certificate: File(Platform.environment['P12_CERTIFICATE_PATH']!),
      certificatePassword: Platform.environment['P12_PASSWORD'],
      provisioningProfile:
          File(Platform.environment['PROVISIONING_PROFILE_PATH']!)
              .asProvisioningProfile(),
      method: ExportMethod.appStoreConnect,
      bundleIdentifier: Platform.environment['BUNDLE_ID']!,
      newKeychain: isCI, // Clean keychain on CI
      archiveSilenceTimeout:
          const Duration(minutes: 10), // Longer timeout for CI
    );

    print('✓ Build successful: ${ipa.path}');

    // Upload to App Store Connect (using separate tool)
    // await uploadToAppStore(ipa);
  } on XcodeBuildArchiveTimeoutException catch (e, stackTrace) {
    print('Build timed out: $e');
    print(stackTrace);
    exit(1);
  } catch (e, stackTrace) {
    print('Build failed: $e');
    print(stackTrace);
    exit(1);
  }
}
