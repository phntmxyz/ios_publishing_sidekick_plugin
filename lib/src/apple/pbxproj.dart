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

  /// Private helper to find build configurations for a target.
  /// Returns a list of (configId, configName) pairs.
  List<({String configId, String configName})> _findBuildConfigs({
    required String content,
    required String targetName,
  }) {
    // Step 1: Find PBXNativeTarget with matching targetName and extract buildConfigurationList ID
    final targetRegex = RegExp(
      r'\/\* ' +
          RegExp.escape(targetName) +
          r' \*\/ = \{[^}]*isa = PBXNativeTarget;[^}]*buildConfigurationList = ([A-F0-9]+)',
      dotAll: true,
    );
    final targetMatch = targetRegex.firstMatch(content);
    if (targetMatch == null) {
      return [];
    }
    final configListId = targetMatch.group(1)!;

    // Step 2: Find XCConfigurationList with that ID and extract build configuration IDs
    final configListRegex = RegExp(
      configListId +
          r' \/\* Build configuration list[^}]*buildConfigurations = \([^)]*\)',
      dotAll: true,
    );
    final configListMatch = configListRegex.firstMatch(content);
    if (configListMatch == null) {
      return [];
    }

    // Extract build configuration IDs (e.g., "3431A0622DCB8D4A007C5167 /* Debug */")
    final buildConfigRegex =
        RegExp(r'([A-F0-9]+) \/\* (Debug|Release|Profile) \*\/');
    final buildConfigs = buildConfigRegex.allMatches(configListMatch.group(0)!);

    return buildConfigs
        .map((match) => (
              configId: match.group(1)!,
              configName: match.group(2)!,
            ))
        .toList();
  }

  /// Gets the buildSettings content for a specific target and build configuration.
  ///
  /// Returns the plain string content of the buildSettings block (without the surrounding braces).
  /// Returns null if the target or configuration is not found.
  ///
  /// [targetName] is the name of the target (e.g., "Runner", "ShareExtension").
  /// [buildConfiguration] specifies which configuration to get ("Debug", "Release", or "Profile").
  ///
  /// Example:
  /// ```dart
  /// final settings = pbxproj.getBuildSettings(
  ///   targetName: 'ShareExtension',
  ///   buildConfiguration: 'Debug',
  /// );
  /// print(settings); // Prints the buildSettings content
  /// ```
  String? getBuildSettings({
    required String targetName,
    required String buildConfiguration,
  }) {
    file.verifyExistsOrThrow();
    final content = file.readAsStringSync();

    final configs = _findBuildConfigs(content: content, targetName: targetName);

    // Find the matching configuration
    for (final config in configs) {
      if (config.configName == buildConfiguration) {
        // Find XCBuildConfiguration block and extract buildSettings
        final buildConfigBlockRegex = RegExp(
          config.configId +
              r' \/\* ' +
              config.configName +
              r' \*\/ = \{[^}]*isa = XCBuildConfiguration;[^}]*buildSettings = \{(.*?)\n\t\t\t\};',
          dotAll: true,
        );

        final match = buildConfigBlockRegex.firstMatch(content);
        if (match != null) {
          return match.group(1)!;
        }
      }
    }

    return null;
  }

  /// Private helper to update buildSettings for a specific target and configuration.
  /// Returns the updated content string.
  String _updateBuildSettings({
    required String content,
    required String targetName,
    required String buildConfiguration,
    required String Function(String oldBuildSettings) updateFunction,
  }) {
    final configs = _findBuildConfigs(content: content, targetName: targetName);

    // Find the matching configuration
    for (final config in configs) {
      if (config.configName == buildConfiguration) {
        // Find XCBuildConfiguration block and extract buildSettings
        final buildConfigBlockRegex = RegExp(
          config.configId +
              r' \/\* ' +
              config.configName +
              r' \*\/ = \{[^}]*isa = XCBuildConfiguration;[^}]*buildSettings = \{(.*?)\n\t\t\t\};',
          dotAll: true,
        );

        final match = buildConfigBlockRegex.firstMatch(content);
        if (match != null) {
          final oldBuildSettings = match.group(1)!;
          final newBuildSettings = updateFunction(oldBuildSettings);
          final replacement =
              match.group(0)!.replaceFirst(oldBuildSettings, newBuildSettings);
          return content.replaceFirst(match.group(0)!, replacement);
        }
      }
    }

    return content;
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

    print(
        'Setting Bundle ID for extension "$extensionName" to "$bundleIdentifier"');
    var content = file.readAsStringSync();

    // Use helper to find build configurations
    final buildConfigs =
        _findBuildConfigs(content: content, targetName: extensionName);

    if (buildConfigs.isEmpty) {
      throw 'Could not find PBXNativeTarget with name "$extensionName" in project.pbxproj';
    }

    // Update PRODUCT_BUNDLE_IDENTIFIER for each matching configuration
    for (final config in buildConfigs) {
      // Skip if buildConfiguration is specified and doesn't match
      if (buildConfiguration != null &&
          config.configName != buildConfiguration) {
        continue;
      }

      // Use helper to update buildSettings
      content = _updateBuildSettings(
        content: content,
        targetName: extensionName,
        buildConfiguration: config.configName,
        updateFunction: (oldBuildSettings) {
          // If PRODUCT_BUNDLE_IDENTIFIER doesn't exist, throw error
          if (!oldBuildSettings.contains('PRODUCT_BUNDLE_IDENTIFIER')) {
            throw 'PRODUCT_BUNDLE_IDENTIFIER not found in build configuration "${config.configName}" for extension "$extensionName"';
          }

          // Replace PRODUCT_BUNDLE_IDENTIFIER value
          return oldBuildSettings.replaceAll(
            RegExp('PRODUCT_BUNDLE_IDENTIFIER = [^;]*;'),
            'PRODUCT_BUNDLE_IDENTIFIER = $bundleIdentifier;',
          );
        },
      );
    }

    file.writeAsStringSync(content);
  }

  /// Sets the PROVISIONING_PROFILE_SPECIFIER for a specific extension target.
  ///
  /// This method finds the extension target by [extensionName] and updates its
  /// provisioning profile specifier in the project.pbxproj file.
  ///
  /// If PROVISIONING_PROFILE_SPECIFIER doesn't exist in the build configuration,
  /// it will be automatically added.
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
  /// - The update fails for any reason
  void setExtensionProvisioningProfile({
    required String extensionName,
    required String provisioningProfileName,
    String? buildConfiguration,
  }) {
    file.verifyExistsOrThrow();

    print(
        'Setting Provisioning Profile for extension "$extensionName" to "$provisioningProfileName"');
    var content = file.readAsStringSync();

    // Use helper to find build configurations
    final buildConfigs =
        _findBuildConfigs(content: content, targetName: extensionName);

    if (buildConfigs.isEmpty) {
      throw 'Could not find PBXNativeTarget with name "$extensionName" in project.pbxproj';
    }

    // Update PROVISIONING_PROFILE_SPECIFIER for each matching configuration
    for (final config in buildConfigs) {
      // Skip if buildConfiguration is specified and doesn't match
      if (buildConfiguration != null &&
          config.configName != buildConfiguration) {
        continue;
      }

      // Use helper to update buildSettings
      content = _updateBuildSettings(
        content: content,
        targetName: extensionName,
        buildConfiguration: config.configName,
        updateFunction: (oldBuildSettings) {
          if (oldBuildSettings.contains('PROVISIONING_PROFILE_SPECIFIER')) {
            // Replace existing PROVISIONING_PROFILE_SPECIFIER
            return oldBuildSettings.replaceAll(
              RegExp('PROVISIONING_PROFILE_SPECIFIER = [^;]*;'),
              'PROVISIONING_PROFILE_SPECIFIER = "$provisioningProfileName";',
            );
          } else {
            // Add PROVISIONING_PROFILE_SPECIFIER if it doesn't exist
            // Add it at the end of the buildSettings block with proper indentation
            return '$oldBuildSettings\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "$provisioningProfileName";';
          }
        },
      );
    }

    file.writeAsStringSync(content);
  }
}

extension XcodePbxprojFile on File {
  XcodePbxproj asXcodePbxproj() {
    return XcodePbxproj(this);
  }
}
