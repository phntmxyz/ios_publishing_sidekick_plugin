# PHNTM iOS Publishing Sidekick Plugin

A comprehensive Dart plugin for iOS app publishing, providing tools for managing Xcode projects, provisioning profiles, certificates, keychains, and building IPAs. Part of the [sidekick CLI](https://pub.dev/packages/sidekick) ecosystem.

## Features

- 🔧 **Xcode Project Management**: Modify `pbxproj` and plist files programmatically
- 🔐 **Keychain Management**: Create, unlock, and manage macOS keychains
- 📜 **Certificate Handling**: Import and read P12 certificates
- 📱 **Provisioning Profiles**: Install and inspect provisioning profiles
- 📦 **IPA Building**: Complete workflow for building and exporting IPAs
- 🎯 **Extension Support**: Configure App Extensions (Share Extensions, etc.)
- 🤖 **CI/CD Ready**: Designed for automated builds on continuous integration

## Installation

### Install your sidekick CLI

```bash
# Install sidekick globally
dart pub global activate sidekick

# Generate custom sidekick CLI
sidekick init
```

### Install phntmxyz_ios_publishing_sidekick_plugin

```bash
<cli> sidekick plugins install phntmxyz_ios_publishing_sidekick_plugin
```

### As a package dependency

```yaml
dependencies:
  phntmxyz_ios_publishing_sidekick_plugin: ^1.0.0
```

## Quick Start

The most important function in this package is `buildIpa()` - it handles the complete workflow for building iOS applications. All other APIs are optional helpers for advanced configuration.

**See [example/](example/) directory for complete, compilable code examples.**

## API Reference & Examples

### 1. Building IPAs (Most Important!)

Complete workflow for building iOS applications. This is the main function you'll use.

**📄 See [example/build_ipa_example.dart](example/build_ipa_example.dart) for complete examples.**

#### Simple IPA Build

```dart
import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

// Basic App Store build
final ipa = await buildIpa(
  certificate: File('certificates/distribution.p12'),
  certificatePassword: 'cert-password',
  provisioningProfile: File('profiles/AppStore.mobileprovision').asProvisioningProfile(),
  method: ExportMethod.appStoreConnect,
  bundleIdentifier: 'com.example.myapp',
);

print('IPA created: ${ipa.path}');
```

#### Advanced IPA Build with Extensions

```dart
// Build with App Extensions
final mainProfile = File('profiles/AppStore.mobileprovision').asProvisioningProfile();
final shareProfile = File('profiles/ShareExtension.mobileprovision').asProvisioningProfile();
final notificationProfile = File('profiles/NotificationService.mobileprovision').asProvisioningProfile();

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
  archiveSilenceTimeout: Duration(minutes: 5),
);

print('IPA with extensions created: ${ipa.path}');
```

#### Export Methods

```dart
// All available export methods:

ExportMethod.appStoreConnect    // For App Store Connect upload
ExportMethod.releaseTesting     // Ad Hoc distribution for testing
ExportMethod.validation         // Validate without exporting
ExportMethod.package            // Development package
ExportMethod.enterprise         // Enterprise distribution
ExportMethod.developerId        // Developer ID signed
ExportMethod.macApplication     // Mac application

// Deprecated (use alternatives):
// ExportMethod.adHoc → use releaseTesting
// ExportMethod.appStore → use appStoreConnect
```

### 2. Plist Management (Optional Configuration)

Modify iOS Info.plist files programmatically.

**📄 See [example/plist_example.dart](example/plist_example.dart) for complete examples.**

#### Setting String Values

```dart
import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

// Load a plist file
final plist = File('ios/Runner/Info.plist').asXcodePlist();

// Set bundle identifier
plist.setBundleIdentifier('com.example.myapp');

// Set display name
plist.setBundleDisplayName('My Awesome App');

// Set bundle name
plist.setBundleName('MyApp');

// Set App Group ID
plist.setAppGroupId('group.com.example.myapp');

// Set any custom string value
plist.setStringValue('CustomKey', 'CustomValue');
plist.setStringValue('UIBackgroundModes', 'remote-notification');
```

#### Setting Array Values

```dart
// Set array of values (e.g., app groups)
plist.setArrayValue('com.apple.security.application-groups', [
  'group.com.example.app',
  'group.com.example.app.share',
]);

// Set URL schemes
plist.setArrayValue('CFBundleURLSchemes', [
  'myapp',
  'myappscheme',
]);

// Set background modes
plist.setArrayValue('UIBackgroundModes', [
  'fetch',
  'remote-notification',
  'processing',
]);
```

#### Creating Plist from Map

```dart
// Convert a Map to plist XML
final exportOptions = {
  'method': 'app-store-connect',
  'teamID': 'ABC123DEF4',
  'uploadSymbols': true,
  'signingStyle': 'manual',
  'provisioningProfiles': {
    'com.example.app': 'My App Store Profile',
    'com.example.app.ShareExtension': 'Share Extension Profile',
  },
};

final plistXml = exportOptions.asPlist();
File('ExportOptions.plist').writeAsStringSync(plistXml);
```

### 3. Xcode Project Configuration (Optional Configuration)

Modify `project.pbxproj` files to configure build settings.

**📄 See [example/xcode_project_example.dart](example/xcode_project_example.dart) for complete examples.**

#### Basic Configuration

```dart
import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

// Load the Xcode project file
final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').asXcodePbxproj();

// Set bundle identifier for all targets
pbxproj.setBundleIdentifier('com.example.myapp');

// Set provisioning profile for all targets
pbxproj.setProvisioningProfileSpecifier('My App Store Profile');

// Set code signing style
pbxproj.setCodeSignStyle('Manual'); // or 'Automatic'

// Set development team
pbxproj.setDevelopmentTeam('ABC123DEF4');
```

#### App Extension Configuration

```dart
// Configure a Share Extension
pbxproj.setExtensionBundleIdentifier(
  extensionName: 'ShareExtension',
  bundleIdentifier: 'com.example.myapp.ShareExtension',
);

pbxproj.setExtensionProvisioningProfile(
  extensionName: 'ShareExtension',
  provisioningProfileName: 'Share Extension Profile',
);

// Configure for specific build configuration only
pbxproj.setExtensionBundleIdentifier(
  extensionName: 'ShareExtension',
  bundleIdentifier: 'com.example.myapp.ShareExtension',
  buildConfiguration: 'Release', // Only affects Release builds
);

// Configure multiple extensions
pbxproj.setExtensionBundleIdentifier(
  extensionName: 'NotificationService',
  bundleIdentifier: 'com.example.myapp.NotificationService',
);

pbxproj.setExtensionProvisioningProfile(
  extensionName: 'NotificationService',
  provisioningProfileName: 'Notification Service Profile',
);
```

#### Reading Build Settings

```dart
// Get build settings for a specific target and configuration
final settings = pbxproj.getBuildSettings(
  targetName: 'ShareExtension',
  buildConfiguration: 'Release',
);

if (settings != null) {
  print('Build settings for ShareExtension (Release):');
  print(settings);
}

// Check Debug configuration
final debugSettings = pbxproj.getBuildSettings(
  targetName: 'Runner',
  buildConfiguration: 'Debug',
);
```

### 4. Keychain Management (Optional Configuration)

Create and manage macOS keychains for code signing.

**📄 See [example/keychain_example.dart](example/keychain_example.dart) for complete examples.**

#### Creating and Configuring a Keychain

```dart
import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

// Create a custom keychain
final keychain = Keychain(name: 'build-keychain');
keychain.password = 'super-secret-password';

// Check if keychain exists
if (keychain.exists()) {
  print('Keychain already exists');
}

// Create keychain (override if exists)
keychain.create(override: true);

// Unlock the keychain
keychain.unlock();

// Set as default keychain for Xcode
keychain.setAsDefault();
```

#### Using Different Keychain Types

```dart
// Use login keychain
final loginKeychain = Keychain.login();
loginKeychain.unlock();

// Use keychain from specific file
final customKeychain = Keychain.file(
  file: File('/path/to/custom.keychain'),
);
customKeychain.password = 'password';
customKeychain.unlock();
```

#### Adding Certificates to Keychain

```dart
// Add a P12 certificate to keychain
final keychain = Keychain(name: 'build-keychain');
keychain.password = 'keychain-password';
keychain.create(override: true);
keychain.unlock();

keychain.addPkcs12Certificate(
  File('certificates/distribution.p12'),
  password: 'certificate-password',
);

// Add certificate without password
keychain.addPkcs12Certificate(
  File('certificates/development.p12'),
  password: '', // Empty password
);
```

#### CI/CD Keychain Setup

```dart
// Complete CI setup
void setupCIKeychain(File certificate, String certPassword) {
  final keychain = Keychain(name: 'ci-keychain');
  keychain.password = 'temporary-ci-password';

  // Clean setup
  keychain.create(override: true);
  keychain.setAsDefault();
  keychain.unlock();

  // Import certificate
  keychain.addPkcs12Certificate(
    certificate,
    password: certPassword,
  );

  print('CI keychain ready for code signing');
}
```

### 5. Certificate Management (Optional Configuration)

Read and extract information from P12 certificates.

**📄 See [example/certificate_example.dart](example/certificate_example.dart) for complete examples.**

#### Reading Certificate Information

```dart
import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

// Read certificate info
final certInfo = readP12CertificateInfo(
  File('certificates/distribution.p12'),
  password: 'certificate-password',
);

print('Certificate Name: ${certInfo.friendlyName}');
print('Local Key ID: ${certInfo.localKeyId}');

// Without password
final devCertInfo = readP12CertificateInfo(
  File('certificates/development.p12'),
);

print('Development Certificate: ${devCertInfo.friendlyName}');
```

#### Validating Certificates

```dart
// Check certificate details before using
File validateCertificate(File certFile, String? password) {
  try {
    final info = readP12CertificateInfo(certFile, password: password);

    if (info.friendlyName.contains('Distribution')) {
      print('✓ Valid distribution certificate: ${info.friendlyName}');
      return certFile;
    } else {
      throw Exception('Expected distribution certificate');
    }
  } catch (e, stackTrace) {
    print('Certificate validation failed: $e');
    print(stackTrace);
    rethrow;
  }
}
```

### 6. Provisioning Profile Management (Optional Configuration)

Install and inspect provisioning profiles.

**📄 See [example/provisioning_profile_example.dart](example/provisioning_profile_example.dart) for complete examples.**

#### Reading Provisioning Profile Information

```dart
import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

// Load provisioning profile
final profile = File('profiles/AppStore.mobileprovision').asProvisioningProfile();

// Access profile information
print('Profile Name: ${profile.name}');
print('UUID: ${profile.uuid}');
print('Team ID: ${profile.teamIdentifier}');
print('Team Name: ${profile.teamName}');
print('App ID Name: ${profile.appIdName}');
print('Platforms: ${profile.platform}');
print('Created: ${profile.creationDate}');
print('Expires: ${profile.expirationDate}');
print('Days Valid: ${profile.timeToLive}');
print('Version: ${profile.version}');
print('Xcode Managed: ${profile.isXcodeManaged}');

// Check provisioned devices (for Ad Hoc/Development profiles)
if (profile.provisionedDevices.isNotEmpty) {
  print('Devices:');
  for (final device in profile.provisionedDevices) {
    print('  - $device');
  }
}
```

#### Installing Provisioning Profiles

```dart
// Install a provisioning profile
final profile = File('profiles/AppStore.mobileprovision').asProvisioningProfile();
installProvisioningProfile(profile);
print('Installed profile: ${profile.name}');

// Install multiple profiles
final profiles = [
  'profiles/AppStore.mobileprovision',
  'profiles/ShareExtension.mobileprovision',
  'profiles/NotificationService.mobileprovision',
];

for (final profilePath in profiles) {
  final profile = File(profilePath).asProvisioningProfile();
  installProvisioningProfile(profile);
  print('✓ Installed: ${profile.name}');
}
```

#### Validating Profile Expiration

```dart
// Check if profile is still valid
void validateProfileExpiration(ProvisioningProfile profile) {
  final now = DateTime.now();
  final daysUntilExpiration = profile.expirationDate.difference(now).inDays;

  if (daysUntilExpiration < 0) {
    throw Exception('Profile "${profile.name}" expired on ${profile.expirationDate}');
  } else if (daysUntilExpiration < 7) {
    print('⚠️  Warning: Profile expires in $daysUntilExpiration days');
  } else {
    print('✓ Profile valid for $daysUntilExpiration days');
  }
}

// Usage
final profile = File('profile.mobileprovision').asProvisioningProfile();
validateProfileExpiration(profile);
```

### 7. Complete Workflow Examples

**📄 See [example/complete_workflows_example.dart](example/complete_workflows_example.dart) for complete examples.**

#### Full Publishing Workflow

```dart
import 'dart:io';
import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

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
  final profile = File('profiles/AppStore.mobileprovision').asProvisioningProfile();

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
```

#### Multi-Target App with Extensions

```dart
Future<File> buildAppWithExtensions() async {
  final bundleId = 'com.example.myapp';

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
  final mainProfile = File('profiles/AppStore.mobileprovision').asProvisioningProfile();
  final shareProfile = File('profiles/ShareExtension.mobileprovision').asProvisioningProfile();

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
```

## Error Handling

Handle common errors when building IPAs:

```dart
try {
  final ipa = await buildIpa(
    certificate: File('cert.p12'),
    provisioningProfile: profile,
    method: ExportMethod.appStoreConnect,
    bundleIdentifier: 'com.example.app',
  );
} on XcodeBuildArchiveTimeoutException catch (e, stackTrace) {
  // Build timed out
  print('Xcode archive timed out: $e');
  print(stackTrace);
} on CommandTimeoutException catch (e, stackTrace) {
  // Generic command timeout
  print('Command timed out: $e');
  print(stackTrace);
} catch (e, stackTrace) {
  // Other errors
  print('Build failed: $e');
  print(stackTrace);
}
```

## Environment Variables

Commonly used environment variables:

```bash
# CI detection
export CI=true

# Certificate and provisioning
export P12_CERTIFICATE_PATH=/path/to/cert.p12
export P12_PASSWORD=certificate-password
export PROVISIONING_PROFILE_PATH=/path/to/profile.mobileprovision

# App configuration
export BUNDLE_ID=com.example.myapp
export APP_VERSION=1.0.0
export BUILD_NUMBER=42
```

## Best Practices

1. **Always validate provisioning profiles** before building
2. **Use environment variables** for sensitive data (passwords, paths)
3. **Create fresh keychains on CI** to avoid conflicts
4. **Set appropriate timeouts** for long-running builds
5. **Capture stack traces** in error handling
6. **Clean up after builds** (keychains, temporary files)
7. **Use bundle identifier validation** (no underscores)
8. **Check certificate expiration dates**
9. **Test with different export methods** (validation, ad-hoc, app-store)
10. **Version control your provisioning profiles** and keep them updated

## Resources

- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Provisioning Profile Format](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)
- [Property List (plist) Format](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/)
- [App Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/)

## Troubleshooting

### Common Issues

**Build timeout errors:**
- Increase `archiveSilenceTimeout` parameter
- Check Xcode build logs for stuck operations
- Verify provisioning profiles are not expired

**Keychain access denied:**
- Ensure keychain is unlocked before adding certificates
- Use `setAsDefault()` to make keychain accessible to Xcode
- On CI, always create fresh keychains

**Code signing errors:**
- Verify bundle identifiers match provisioning profiles exactly
- Check certificate and provisioning profile team IDs match
- Ensure all extensions have proper provisioning profiles

**Extension configuration issues:**
- Verify extension target names match exactly
- Check that extension bundle IDs follow pattern: `{main-bundle-id}.{extension-name}`
- Ensure app groups are configured in both app and extension plists

## License

```
Copyright 2022 PHNTM GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

```
      