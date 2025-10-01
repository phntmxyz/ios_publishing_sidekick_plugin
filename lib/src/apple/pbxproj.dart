import 'package:sidekick_core/sidekick_core.dart';

class XcodePbxproj {
  final File file;
  XcodePbxproj(this.file);

  /// Changes PRODUCT_BUNDLE_IDENTIFIER of all configurations
  void setBundleIdentifier(String bundleIdentifier) {
    file.verifyExistsOrThrow();

    print('Changing PRODUCT_BUNDLE_IDENTIFIER to "$bundleIdentifier"');
    final content = file.readAsStringSync();
    final bundleIdentifierRegex = RegExp('PRODUCT_BUNDLE_IDENTIFIER =.*;');
    final match = bundleIdentifierRegex.hasMatch(content);
    if (!match) {
      throw "project.pbxproj doesn't contain 'PRODUCT_BUNDLE_IDENTIFIER'";
    }
    final update = content.replaceAll(
      bundleIdentifierRegex,
      'PRODUCT_BUNDLE_IDENTIFIER = $bundleIdentifier;',
    );
    file.writeAsStringSync(update);
  }

  /// Changes PRODUCT_NAME of all configurations
  void setProvisioningProfileSpecifier(String provisioningProfileName) {
    file.verifyExistsOrThrow();

    print(
      'Changing PROVISIONING_PROFILE_SPECIFIER to "$provisioningProfileName"',
    );
    final content = file.readAsStringSync();
    final bundleIdentifierRegex = RegExp('PROVISIONING_PROFILE_SPECIFIER =.*;');
    final match = bundleIdentifierRegex.hasMatch(content);
    if (!match) {
      throw "project.pbxproj doesn't contain 'PROVISIONING_PROFILE_SPECIFIER'";
    }
    final update = content.replaceAll(
      bundleIdentifierRegex,
      'PROVISIONING_PROFILE_SPECIFIER = "$provisioningProfileName";',
    );
    file.writeAsStringSync(update);
  }

  /// Changes CODE_SIGN_STYLE of all configurations
  void setCodeSignStyle(String style) {
    file.verifyExistsOrThrow();

    print('Changing CODE_SIGN_STYLE to "$style"');
    final content = file.readAsStringSync();
    final bundleIdentifierRegex = RegExp('CODE_SIGN_STYLE =.*;');
    final match = bundleIdentifierRegex.hasMatch(content);
    if (!match) {
      throw "project.pbxproj doesn't contain 'CODE_SIGN_STYLE'";
    }
    final update = content.replaceAll(
      bundleIdentifierRegex,
      'CODE_SIGN_STYLE = $style;',
    );
    file.writeAsStringSync(update);
  }

  /// Changes DEVELOPMENT_TEAM of all configurations
  void setDevelopmentTeam(String team) {
    file.verifyExistsOrThrow();

    print('Changing DEVELOPMENT_TEAM to "$team"');
    final content = file.readAsStringSync();
    final bundleIdentifierRegex = RegExp('DEVELOPMENT_TEAM =.*;');
    final match = bundleIdentifierRegex.hasMatch(content);
    if (!match) {
      throw "project.pbxproj doesn't contain 'DEVELOPMENT_TEAM'";
    }
    final update = content.replaceAll(
      bundleIdentifierRegex,
      'DEVELOPMENT_TEAM = $team;',
    );
    file.writeAsStringSync(update);
  }

  /// Sets Bundle ID for Main App (Runner) target only - DEPRECATED, use setBundleIdentifier instead
  void setMainAppBundleIdentifier(String bundleIdentifier) {
    // Just delegate to the working setBundleIdentifier method
    setBundleIdentifier(bundleIdentifier);
  }

  /// Sets Bundle ID for ShareExtension target only
  void setShareExtensionBundleIdentifier(String bundleIdentifier) {
    file.verifyExistsOrThrow();

    print('Setting ShareExtension Bundle ID to "$bundleIdentifier"');
    final content = file.readAsStringSync();

    // Find and replace any Bundle ID that ends with .ShareExtension
    final updated = content.replaceAllMapped(RegExp(r'(PRODUCT_BUNDLE_IDENTIFIER = )[^;]*\.ShareExtension;'),
        (match) => '${match.group(1)}$bundleIdentifier;');

    file.writeAsStringSync(updated);
  }

  /// Sets Provisioning Profile for Main App (Runner) target only
  void setMainAppProvisioningProfile(String provisioningProfileName) {
    file.verifyExistsOrThrow();

    print('Setting Main App Provisioning Profile to "$provisioningProfileName"');
    final content = file.readAsStringSync();

    // Target Runner target specifically
    final runnerTargetRegex = RegExp(
      r'(\/\* Begin XCBuildConfiguration section \*\/.*?name = Runner;.*?buildSettings = \{.*?)(PROVISIONING_PROFILE_SPECIFIER = [^;]*;)',
      dotAll: true,
    );

    final match = runnerTargetRegex.firstMatch(content);
    if (match == null) {
      throw "Could not find Runner target PROVISIONING_PROFILE_SPECIFIER in project.pbxproj";
    }

    final updated = content.replaceAllMapped(runnerTargetRegex, (match) {
      return '${match.group(1)}PROVISIONING_PROFILE_SPECIFIER = "$provisioningProfileName";';
    });

    file.writeAsStringSync(updated);
  }

  /// Sets Provisioning Profile for ShareExtension target only
  void setShareExtensionProvisioningProfile(String provisioningProfileName) {
    file.verifyExistsOrThrow();

    print('Setting ShareExtension Provisioning Profile to "$provisioningProfileName"');
    final content = file.readAsStringSync();

    // Target ShareExtension target specifically
    final shareExtTargetRegex = RegExp(
      r'(\/\* Begin XCBuildConfiguration section \*\/.*?name = ShareExtension;.*?buildSettings = \{.*?)(PROVISIONING_PROFILE_SPECIFIER = [^;]*;)',
      dotAll: true,
    );

    final match = shareExtTargetRegex.firstMatch(content);
    if (match == null) {
      throw "Could not find ShareExtension target PROVISIONING_PROFILE_SPECIFIER in project.pbxproj";
    }

    final updated = content.replaceAllMapped(shareExtTargetRegex, (match) {
      return '${match.group(1)}PROVISIONING_PROFILE_SPECIFIER = "$provisioningProfileName";';
    });

    file.writeAsStringSync(updated);
  }

  /// Sets App Group for all targets
  void setAppGroup(String appGroupId) {
    file.verifyExistsOrThrow();

    print('Setting App Group to "$appGroupId"');
    final content = file.readAsStringSync();
    final appGroupRegex = RegExp('RECEIVE_SHARE_INTENT_GROUP_ID = [^;]*;');
    final match = appGroupRegex.hasMatch(content);
    if (!match) {
      throw "project.pbxproj doesn't contain 'RECEIVE_SHARE_INTENT_GROUP_ID'";
    }
    final updated = content.replaceAll(
      appGroupRegex,
      // TODO Remove, this is a custom property
      'RECEIVE_SHARE_INTENT_GROUP_ID = $appGroupId;',
    );
    file.writeAsStringSync(updated);
  }

  /// Sets Bundle ID for Runner target only (more precise than setBundleIdentifier)
  void setRunnerBundleIdentifier(String bundleIdentifier) {
    file.verifyExistsOrThrow();

    print('Setting Runner Bundle ID to "$bundleIdentifier"');
    final content = file.readAsStringSync();

    // Target Runner configurations specifically
    final updated = content.replaceAllMapped(
        RegExp(r'(name = (?:Debug|Release|Profile);.*?buildSettings = \{.*?)(PRODUCT_BUNDLE_IDENTIFIER = )[^;]*;',
            dotAll: true), (match) {
      final section = match.group(0)!;
      // Only replace if this is a Runner section (not ShareExtension)
      if (section.contains('ShareExtension')) {
        return match.group(0)!; // Don't change ShareExtension
      }
      return '${match.group(1)}${match.group(2)}$bundleIdentifier;';
    });

    file.writeAsStringSync(updated);
  }

  /// Sets the PRODUCT_BUNDLE_IDENTIFIER for a specific extension target.
  ///
  /// This method finds the extension target by [extensionName] and updates its
  /// bundle identifier in the project.pbxproj file.
  ///
  /// [extensionName] is the name of the extension target (e.g., "ShareExtension").
  /// [bundleIdentifier] is the new bundle identifier to set (e.g., "com.example.app.ShareExtension").
  /// [buildConfiguration] optionally specifies which configuration to update ("Debug", "Release", or "Profile").
  /// If null, all configurations are updated.
  ///
  /// Example:
  /// ```dart
  /// // Update all configurations
  /// pbxproj.setExtensionBundleIdentifier(
  ///   extensionName: 'ShareExtension',
  ///   bundleIdentifier: 'com.example.app.ShareExtension',
  /// );
  ///
  /// // Update only Release configuration
  /// pbxproj.setExtensionBundleIdentifier(
  ///   extensionName: 'ShareExtension',
  ///   bundleIdentifier: 'com.example.app.ShareExtension',
  ///   buildConfiguration: 'Release',
  /// );
  /// ```
  ///
  /// Throws an error if:
  /// - The extension target with [extensionName] is not found
  /// - The PRODUCT_BUNDLE_IDENTIFIER property doesn't exist in the configuration
  /// - The update fails for any reason
  void setExtensionBundleIdentifier({
    required String extensionName,
    required String bundleIdentifier,
    String? buildConfiguration,
  }) {
    file.verifyExistsOrThrow();

    print('Setting Bundle ID for extension "$extensionName" to "$bundleIdentifier"');
    final content = file.readAsStringSync();

    // Step 1: Find PBXNativeTarget with matching extensionName and extract buildConfigurationList ID
    final targetRegex = RegExp(
      r'\/\* ' + RegExp.escape(extensionName) + r' \*\/ = \{[^}]*isa = PBXNativeTarget;[^}]*buildConfigurationList = ([A-F0-9]+)',
      dotAll: true,
    );
    final targetMatch = targetRegex.firstMatch(content);
    if (targetMatch == null) {
      throw 'Could not find PBXNativeTarget with name "$extensionName" in project.pbxproj';
    }
    final configListId = targetMatch.group(1)!;

    // Step 2: Find XCConfigurationList with that ID and extract build configuration IDs
    final configListRegex = RegExp(
      configListId + r' \/\* Build configuration list[^}]*buildConfigurations = \([^)]*\)',
      dotAll: true,
    );
    final configListMatch = configListRegex.firstMatch(content);
    if (configListMatch == null) {
      throw 'Could not find XCConfigurationList with ID "$configListId" in project.pbxproj';
    }

    // Extract build configuration IDs (e.g., "3431A0622DCB8D4A007C5167 /* Debug */")
    final buildConfigRegex = RegExp(r'([A-F0-9]+) \/\* (Debug|Release|Profile) \*\/');
    final buildConfigs = buildConfigRegex.allMatches(configListMatch.group(0)!);

    if (buildConfigs.isEmpty) {
      throw 'Could not find any build configurations for extension "$extensionName"';
    }

    // Step 3: For each build configuration (or specific one), update PRODUCT_BUNDLE_IDENTIFIER
    var updated = content;
    for (final configMatch in buildConfigs) {
      final configId = configMatch.group(1)!;
      final configName = configMatch.group(2)!;

      // Skip if buildConfiguration is specified and doesn't match
      if (buildConfiguration != null && configName != buildConfiguration) {
        continue;
      }

      // Find XCBuildConfiguration block and update PRODUCT_BUNDLE_IDENTIFIER
      final buildConfigBlockRegex = RegExp(
        configId + r' \/\* ' + configName + r' \*\/ = \{[^}]*isa = XCBuildConfiguration;[^}]*buildSettings = \{(.*?)\n\t\t\};',
        dotAll: true,
      );

      updated = updated.replaceAllMapped(buildConfigBlockRegex, (match) {
        final buildSettingsContent = match.group(1)!;
        final updatedBuildSettings = buildSettingsContent.replaceAll(
          RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*;'),
          'PRODUCT_BUNDLE_IDENTIFIER = $bundleIdentifier;',
        );

        // If PRODUCT_BUNDLE_IDENTIFIER doesn't exist, we need to add it
        if (!buildSettingsContent.contains('PRODUCT_BUNDLE_IDENTIFIER')) {
          throw 'PRODUCT_BUNDLE_IDENTIFIER not found in build configuration "$configName" for extension "$extensionName"';
        }

        return match.group(0)!.replaceFirst(buildSettingsContent, updatedBuildSettings);
      });
    }

    if (updated == content) {
      throw 'Failed to update PRODUCT_BUNDLE_IDENTIFIER for extension "$extensionName"';
    }

    file.writeAsStringSync(updated);
  }

  /// Sets the PROVISIONING_PROFILE_SPECIFIER for a specific extension target.
  ///
  /// This method finds the extension target by [extensionName] and updates its
  /// provisioning profile specifier in the project.pbxproj file.
  ///
  /// [extensionName] is the name of the extension target (e.g., "ShareExtension").
  /// [provisioningProfileName] is the provisioning profile name to set.
  /// [buildConfiguration] optionally specifies which configuration to update ("Debug", "Release", or "Profile").
  /// If null, all configurations are updated.
  ///
  /// Example:
  /// ```dart
  /// // Update all configurations
  /// pbxproj.setExtensionProvisioningProfile(
  ///   extensionName: 'ShareExtension',
  ///   provisioningProfileName: 'My Share Extension Profile',
  /// );
  ///
  /// // Update only Release configuration
  /// pbxproj.setExtensionProvisioningProfile(
  ///   extensionName: 'ShareExtension',
  ///   provisioningProfileName: 'My Share Extension Profile',
  ///   buildConfiguration: 'Release',
  /// );
  /// ```
  ///
  /// Throws an error if:
  /// - The extension target with [extensionName] is not found
  /// - The PROVISIONING_PROFILE_SPECIFIER property doesn't exist in the configuration
  /// - The update fails for any reason
  void setExtensionProvisioningProfile({
    required String extensionName,
    required String provisioningProfileName,
    String? buildConfiguration,
  }) {
    file.verifyExistsOrThrow();

    print('Setting Provisioning Profile for extension "$extensionName" to "$provisioningProfileName"');
    final content = file.readAsStringSync();

    // Step 1: Find PBXNativeTarget with matching extensionName and extract buildConfigurationList ID
    final targetRegex = RegExp(
      r'\/\* ' + RegExp.escape(extensionName) + r' \*\/ = \{[^}]*isa = PBXNativeTarget;[^}]*buildConfigurationList = ([A-F0-9]+)',
      dotAll: true,
    );
    final targetMatch = targetRegex.firstMatch(content);
    if (targetMatch == null) {
      throw 'Could not find PBXNativeTarget with name "$extensionName" in project.pbxproj';
    }
    final configListId = targetMatch.group(1)!;

    // Step 2: Find XCConfigurationList with that ID and extract build configuration IDs
    final configListRegex = RegExp(
      configListId + r' \/\* Build configuration list[^}]*buildConfigurations = \([^)]*\)',
      dotAll: true,
    );
    final configListMatch = configListRegex.firstMatch(content);
    if (configListMatch == null) {
      throw 'Could not find XCConfigurationList with ID "$configListId" in project.pbxproj';
    }

    // Extract build configuration IDs (e.g., "3431A0622DCB8D4A007C5167 /* Debug */")
    final buildConfigRegex = RegExp(r'([A-F0-9]+) \/\* (Debug|Release|Profile) \*\/');
    final buildConfigs = buildConfigRegex.allMatches(configListMatch.group(0)!);

    if (buildConfigs.isEmpty) {
      throw 'Could not find any build configurations for extension "$extensionName"';
    }

    // Step 3: For each build configuration (or specific one), update PROVISIONING_PROFILE_SPECIFIER
    var updated = content;
    for (final configMatch in buildConfigs) {
      final configId = configMatch.group(1)!;
      final configName = configMatch.group(2)!;

      // Skip if buildConfiguration is specified and doesn't match
      if (buildConfiguration != null && configName != buildConfiguration) {
        continue;
      }

      // Find XCBuildConfiguration block and update PROVISIONING_PROFILE_SPECIFIER
      final buildConfigBlockRegex = RegExp(
        configId + r' \/\* ' + configName + r' \*\/ = \{[^}]*isa = XCBuildConfiguration;[^}]*buildSettings = \{(.*?)\n\t\t\};',
        dotAll: true,
      );

      updated = updated.replaceAllMapped(buildConfigBlockRegex, (match) {
        final buildSettingsContent = match.group(1)!;
        final updatedBuildSettings = buildSettingsContent.replaceAll(
          RegExp(r'PROVISIONING_PROFILE_SPECIFIER = [^;]*;'),
          'PROVISIONING_PROFILE_SPECIFIER = "$provisioningProfileName";',
        );

        // If PROVISIONING_PROFILE_SPECIFIER doesn't exist, we need to add it
        if (!buildSettingsContent.contains('PROVISIONING_PROFILE_SPECIFIER')) {
          throw 'PROVISIONING_PROFILE_SPECIFIER not found in build configuration "$configName" for extension "$extensionName"';
        }

        return match.group(0)!.replaceFirst(buildSettingsContent, updatedBuildSettings);
      });
    }

    if (updated == content) {
      throw 'Failed to update PROVISIONING_PROFILE_SPECIFIER for extension "$extensionName"';
    }

    file.writeAsStringSync(updated);
  }
}

extension XcodePbxprojFile on File {
  XcodePbxproj asXcodePbxproj() {
    return XcodePbxproj(this);
  }
}
