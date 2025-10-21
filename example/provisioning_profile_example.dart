// ignore_for_file: unused_local_variable, avoid_print

import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

/// Examples of installing and inspecting provisioning profiles.
void main() {
  // Example 1: Reading Provisioning Profile Information
  readingProvisioningProfileInformation();

  // Example 2: Installing Provisioning Profiles
  installingProvisioningProfiles();

  // Example 3: Validating Profile Expiration
  validateProfileExpiration(
    File('profile.mobileprovision').asProvisioningProfile(),
  );
}

/// Load provisioning profile and access information.
void readingProvisioningProfileInformation() {
  // Load provisioning profile
  final profile =
      File('profiles/AppStore.mobileprovision').asProvisioningProfile();

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
}

/// Install provisioning profiles.
void installingProvisioningProfiles() {
  // Install a provisioning profile
  final profile =
      File('profiles/AppStore.mobileprovision').asProvisioningProfile();
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
}

/// Check if profile is still valid.
void validateProfileExpiration(ProvisioningProfile profile) {
  final now = DateTime.now();
  final daysUntilExpiration = profile.expirationDate.difference(now).inDays;

  if (daysUntilExpiration < 0) {
    throw Exception(
        'Profile "${profile.name}" expired on ${profile.expirationDate}');
  } else if (daysUntilExpiration < 7) {
    print('⚠️  Warning: Profile expires in $daysUntilExpiration days');
  } else {
    print('✓ Profile valid for $daysUntilExpiration days');
  }
}
