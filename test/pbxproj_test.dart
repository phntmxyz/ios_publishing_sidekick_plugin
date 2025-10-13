import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/apple/pbxproj.dart';
import 'package:test/test.dart';
// ignore: depend_on_referenced_packages
import 'package:test_api/src/backend/invoker.dart' show Invoker;

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
      // Store original Release bundle ID (not currently used but kept for reference)
      // final originalReleaseMatch = RegExp(
      //   r'3431A0632DCB8D4A007C5167 \/\* Release \*\/ = \{.*?PRODUCT_BUNDLE_IDENTIFIER = ([^;]*);',
      //   dotAll: true,
      // ).firstMatch(originalContent);
      // final originalReleaseBundleId = originalReleaseMatch?.group(1);

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
      addTearDown(() {
        if (Invoker.current!.liveTest.state.result.toString().contains('failure')) {
          print(sampleFile.readAsStringSync());
        }
      });
      printOnFailure("updated sample_project.pbxproj:\n${testPbxproj.readAsStringSync()}");
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

    test('does not affect Runner target provisioning profile', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      // Get original Runner Debug buildSettings
      final originalBuildSettings = pbxproj.getBuildSettings(
        targetName: 'Runner',
        buildConfiguration: 'Debug',
      );
      expect(originalBuildSettings, isNotNull);
      expect(originalBuildSettings!.contains('PROVISIONING_PROFILE_SPECIFIER'), false,
          reason: 'Runner Debug should not have PROVISIONING_PROFILE_SPECIFIER initially');

      pbxproj.setExtensionProvisioningProfile(
        extensionName: 'ShareExtension',
        provisioningProfileName: 'New Share Extension Profile',
      );

      // Check Runner Debug configuration is unchanged (still doesn't have PROVISIONING_PROFILE_SPECIFIER)
      final updatedBuildSettings = pbxproj.getBuildSettings(
        targetName: 'Runner',
        buildConfiguration: 'Debug',
      );
      expect(updatedBuildSettings, isNotNull);
      expect(updatedBuildSettings!.contains('PROVISIONING_PROFILE_SPECIFIER'), false,
          reason: 'Runner Debug should still not have PROVISIONING_PROFILE_SPECIFIER after modifying ShareExtension');
    });

    test('automatically adds PROVISIONING_PROFILE_SPECIFIER if it does not exist', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      // Verify PROVISIONING_PROFILE_SPECIFIER doesn't exist in ShareExtension Debug config
      final beforeContent = testPbxproj.readAsStringSync();
      final beforeMatch = RegExp(
        r'3431A0622DCB8D4A007C5167 /\* Debug \*/ = \{.*?buildSettings = \{.*?PROVISIONING_PROFILE_SPECIFIER',
        dotAll: true,
      ).hasMatch(beforeContent);
      expect(beforeMatch, false, reason: 'PROVISIONING_PROFILE_SPECIFIER should not exist initially');

      // Set provisioning profile - it should be added automatically
      pbxproj.setExtensionProvisioningProfile(
        extensionName: 'ShareExtension',
        provisioningProfileName: 'Auto Added Profile',
        buildConfiguration: 'Debug',
      );

      // Verify it was added
      final afterContent = testPbxproj.readAsStringSync();
      final debugMatch = RegExp(
        r'3431A0622DCB8D4A007C5167 /\* Debug \*/ = \{.*?PROVISIONING_PROFILE_SPECIFIER = ([^;]*);',
        dotAll: true,
      ).firstMatch(afterContent);
      expect(debugMatch?.group(1), '"Auto Added Profile"');
    });

    test('adds PROVISIONING_PROFILE_SPECIFIER inside buildSettings block with correct structure', () {
      final pbxproj = XcodePbxproj(testPbxproj);

      pbxproj.setExtensionProvisioningProfile(
        extensionName: 'ShareExtension',
        provisioningProfileName: 'Test Profile',
        buildConfiguration: 'Debug',
      );

      // Use helper method to get buildSettings
      final buildSettingsContent = pbxproj.getBuildSettings(
        targetName: 'ShareExtension',
        buildConfiguration: 'Debug',
      );
      expect(buildSettingsContent, isNotNull, reason: 'Should find ShareExtension Debug buildSettings');

      // Verify PROVISIONING_PROFILE_SPECIFIER is in buildSettings
      expect(buildSettingsContent!.contains('PROVISIONING_PROFILE_SPECIFIER = "Test Profile";'), true,
          reason: 'PROVISIONING_PROFILE_SPECIFIER should be inside buildSettings block');

      // Verify proper indentation (4 tabs before the property)
      expect(buildSettingsContent.contains('\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "Test Profile";'), true,
          reason: 'PROVISIONING_PROFILE_SPECIFIER should have correct indentation (4 tabs)');

      // Verify that "name = Debug;" is NOT in buildSettings content (it should be outside)
      expect(buildSettingsContent.contains('name = Debug;'), false,
          reason: 'name = Debug; should be outside buildSettings block');
    });
  });
}
