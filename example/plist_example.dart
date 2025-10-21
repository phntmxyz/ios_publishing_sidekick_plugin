// ignore_for_file: unused_local_variable, avoid_print

import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

/// Examples of modifying iOS Info.plist files programmatically.
void main() {
  // Example 1: Setting String Values
  settingStringValues();

  // Example 2: Setting Array Values
  settingArrayValues();

  // Example 3: Creating Plist from Map
  creatingPlistFromMap();
}

/// Load a plist file and set various string values.
void settingStringValues() {
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
}

/// Set array of values in plist.
void settingArrayValues() {
  final plist = File('ios/Runner/Info.plist').asXcodePlist();

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
}

/// Convert a Map to plist XML.
void creatingPlistFromMap() {
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
}
