// ignore_for_file: unused_local_variable, avoid_print

import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

/// Examples of modifying Xcode project files (project.pbxproj).
void main() {
  // Example 1: Basic Configuration
  basicConfiguration();

  // Example 2: App Extension Configuration
  appExtensionConfiguration();

  // Example 3: Reading Build Settings
  readingBuildSettings();
}

/// Configure basic Xcode project settings.
void basicConfiguration() {
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
}

/// Configure app extensions.
void appExtensionConfiguration() {
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').asXcodePbxproj();

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
}

/// Read build settings from project.
void readingBuildSettings() {
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').asXcodePbxproj();

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
}
