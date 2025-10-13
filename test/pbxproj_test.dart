import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/apple/pbxproj.dart';
import 'package:test/test.dart';

void main() {
  group('setExtensionBundleIdentifier', () {
    late Directory tempDir;
    late File testPbxproj;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pbxproj_test_');
      testPbxproj = File('${tempDir.path}/project.pbxproj');

      // Copy the sample pbxproj file to temp directory
      final sampleFile = File('test/resources/sample_project.pbxproj');
      testPbxproj.writeAsStringSync(sampleFile.readAsStringSync());
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('updates all build configurations when buildConfiguration is not specified', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      pbxproj.setExtensionBundleIdentifier(
        extensionName: 'ShareExtension',
        bundleIdentifier: 'com.newapp.ShareExtension',
      );

      final content = testPbxproj.readAsStringSync();

      // Check Debug configuration
      expect(
        content,
        contains('3431A0622DCB8D4A007C5167 /* Debug */ = {'),
      );
      final debugMatch = RegExp(
        r'3431A0622DCB8D4A007C5167 \/\* Debug \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(debugMatch?.group(1), 'com.newapp.ShareExtension');

      // Check Release configuration
      final releaseMatch = RegExp(
        r'3431A0632DCB8D4A007C5167 \/\* Release \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(releaseMatch?.group(1), 'com.newapp.ShareExtension');

      // Check Profile configuration
      final profileMatch = RegExp(
        r'3431A0642DCB8D4A007C5167 \/\* Profile \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(profileMatch?.group(1), 'com.newapp.ShareExtension');
    });

    test('updates only specified build configuration', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      // Get original values
      final originalContent = testPbxproj.readAsStringSync();
      final originalReleaseMatch = RegExp(
        r'3431A0632DCB8D4A007C5167 \/\* Release \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(originalContent);
      final originalReleaseBundleId = originalReleaseMatch?.group(1);

      final originalDebugMatch = RegExp(
        r'3431A0622DCB8D4A007C5167 \/\* Debug \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(originalContent);
      final originalDebugBundleId = originalDebugMatch?.group(1);

      // Update only Release configuration
      pbxproj.setExtensionBundleIdentifier(
        extensionName: 'ShareExtension',
        bundleIdentifier: 'com.release.ShareExtension',
        buildConfiguration: 'Release',
      );

      final content = testPbxproj.readAsStringSync();

      // Check Release configuration was updated
      final releaseMatch = RegExp(
        r'3431A0632DCB8D4A007C5167 \/\* Release \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(releaseMatch?.group(1), 'com.release.ShareExtension');

      // Check Debug configuration was NOT updated
      final debugMatch = RegExp(
        r'3431A0622DCB8D4A007C5167 \/\* Debug \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(debugMatch?.group(1), originalDebugBundleId);

      // Check Profile configuration was NOT updated
      final profileMatch = RegExp(
        r'3431A0642DCB8D4A007C5167 \/\* Profile \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(profileMatch?.group(1), isNot('com.release.ShareExtension'));
    });

    test('throws error when extension target is not found', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      expect(
        () => pbxproj.setExtensionBundleIdentifier(
          extensionName: 'NonExistentExtension',
          bundleIdentifier: 'com.test.Extension',
        ),
        throwsA(contains('Could not find PBXNativeTarget with name "NonExistentExtension"')),
      );
    });

    test('preserves other build settings', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      // Get original content
      final originalContent = testPbxproj.readAsStringSync();

      pbxproj.setExtensionBundleIdentifier(
        extensionName: 'ShareExtension',
        bundleIdentifier: 'com.newapp.ShareExtension',
      );

      final newContent = testPbxproj.readAsStringSync();

      // Check that other settings are preserved
      expect(newContent, contains('DEVELOPMENT_TEAM = 7M6S7TXG8N;'));
      expect(newContent, contains('SWIFT_VERSION = 5.0;'));
      expect(newContent, contains('CODE_SIGN_IDENTITY = "Apple Development";'));
      expect(newContent, contains('RECEIVE_SHARE_INTENT_GROUP_ID = group.xyz.phntm.vodafone.noascan.firebase;'));
    });

    test('does not affect Runner target bundle identifier', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      pbxproj.setExtensionBundleIdentifier(
        extensionName: 'ShareExtension',
        bundleIdentifier: 'com.newapp.ShareExtension',
      );

      final content = testPbxproj.readAsStringSync();

      // Check Runner Debug configuration is unchanged
      final runnerDebugMatch = RegExp(
        r'97C147061CF9000F007C117D \/\* Debug \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(runnerDebugMatch?.group(1), 'com.example.runner');

      // Check Runner Release configuration is unchanged
      final runnerReleaseMatch = RegExp(
        r'97C147071CF9000F007C117D \/\* Release \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(runnerReleaseMatch?.group(1), 'com.example.runner');
    });

    test('handles bundle identifiers with special characters', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      pbxproj.setExtensionBundleIdentifier(
        extensionName: 'ShareExtension',
        bundleIdentifier: 'com.example-app.share.extension',
      );

      final content = testPbxproj.readAsStringSync();

      final debugMatch = RegExp(
        r'3431A0622DCB8D4A007C5167 \/\* Debug \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(debugMatch?.group(1), 'com.example-app.share.extension');
    });
  });

  group('setExtensionProvisioningProfile', () {
    late Directory tempDir;
    late File testPbxproj;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pbxproj_test_');
      testPbxproj = File('${tempDir.path}/project.pbxproj');

      // Copy the sample pbxproj file to temp directory
      final sampleFile = File('test/resources/sample_project.pbxproj');
      testPbxproj.writeAsStringSync(sampleFile.readAsStringSync());
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('updates all build configurations when buildConfiguration is not specified', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      pbxproj.setExtensionProvisioningProfile(
        extensionName: 'ShareExtension',
        provisioningProfileName: 'My New Share Extension Profile',
      );

      final content = testPbxproj.readAsStringSync();

      // Check Debug configuration
      final debugMatch = RegExp(
        r'3431A0622DCB8D4A007C5167 \/\* Debug \*\/ = \{.*?PROVISIONING_PROFILE_SPECIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(debugMatch?.group(1), '"My New Share Extension Profile"');

      // Check Release configuration
      final releaseMatch = RegExp(
        r'3431A0632DCB8D4A007C5167 \/\* Release \*\/ = \{.*?PROVISIONING_PROFILE_SPECIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(releaseMatch?.group(1), '"My New Share Extension Profile"');

      // Check Profile configuration
      final profileMatch = RegExp(
        r'3431A0642DCB8D4A007C5167 \/\* Profile \*\/ = \{.*?PROVISIONING_PROFILE_SPECIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(profileMatch?.group(1), '"My New Share Extension Profile"');
    });

    test('updates only specified build configuration', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      // Get original values
      final originalContent = testPbxproj.readAsStringSync();
      final originalReleaseMatch = RegExp(
        r'3431A0632DCB8D4A007C5167 \/\* Release \*\/ = \{.*?PROVISIONING_PROFILE_SPECIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(originalContent);
      final originalReleaseProfile = originalReleaseMatch?.group(1);

      final originalDebugMatch = RegExp(
        r'3431A0622DCB8D4A007C5167 \/\* Debug \*\/ = \{.*?PROVISIONING_PROFILE_SPECIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(originalContent);
      final originalDebugProfile = originalDebugMatch?.group(1);

      // Update only Release configuration
      pbxproj.setExtensionProvisioningProfile(
        extensionName: 'ShareExtension',
        provisioningProfileName: 'Release Only Profile',
        buildConfiguration: 'Release',
      );

      final content = testPbxproj.readAsStringSync();

      // Check Release configuration was updated
      final releaseMatch = RegExp(
        r'3431A0632DCB8D4A007C5167 \/\* Release \*\/ = \{.*?PROVISIONING_PROFILE_SPECIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(releaseMatch?.group(1), '"Release Only Profile"');

      // Check Debug configuration was NOT updated
      final debugMatch = RegExp(
        r'3431A0622DCB8D4A007C5167 \/\* Debug \*\/ = \{.*?PROVISIONING_PROFILE_SPECIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(debugMatch?.group(1), originalDebugProfile);

      // Check Profile configuration was NOT updated
      final profileMatch = RegExp(
        r'3431A0642DCB8D4A007C5167 \/\* Profile \*\/ = \{.*?PROVISIONING_PROFILE_SPECIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(profileMatch?.group(1), isNot('"Release Only Profile"'));
    });

    test('throws error when extension target is not found', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      expect(
        () => pbxproj.setExtensionProvisioningProfile(
          extensionName: 'NonExistentExtension',
          provisioningProfileName: 'Test Profile',
        ),
        throwsA(contains('Could not find PBXNativeTarget with name "NonExistentExtension"')),
      );
    });

    test('preserves other build settings', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      pbxproj.setExtensionProvisioningProfile(
        extensionName: 'ShareExtension',
        provisioningProfileName: 'New Profile',
      );

      final newContent = testPbxproj.readAsStringSync();

      // Check that other settings are preserved
      expect(newContent, contains('DEVELOPMENT_TEAM = 7M6S7TXG8N;'));
      expect(newContent, contains('SWIFT_VERSION = 5.0;'));
      expect(newContent, contains('CODE_SIGN_IDENTITY = "Apple Development";'));
      expect(newContent, contains('RECEIVE_SHARE_INTENT_GROUP_ID = group.xyz.phntm.vodafone.noascan.firebase;'));
    });

    test('does not affect Runner target bundle identifier', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      // Get original Runner bundle identifier
      final originalContent = testPbxproj.readAsStringSync();
      final originalRunnerMatch = RegExp(
        r'97C147061CF9000F007C117D \/\* Debug \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(originalContent);
      final originalRunnerBundleId = originalRunnerMatch?.group(1);

      pbxproj.setExtensionProvisioningProfile(
        extensionName: 'ShareExtension',
        provisioningProfileName: 'New Share Extension Profile',
      );

      final content = testPbxproj.readAsStringSync();

      // Check Runner Debug configuration bundle identifier is unchanged
      final runnerDebugMatch = RegExp(
        r'97C147061CF9000F007C117D \/\* Debug \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(content);
      expect(runnerDebugMatch?.group(1), originalRunnerBundleId);
      expect(runnerDebugMatch?.group(1), 'com.example.runner');
    });
  });
}
