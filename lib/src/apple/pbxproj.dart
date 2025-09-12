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
    final updated = content.replaceAllMapped(
        RegExp(r'(PRODUCT_BUNDLE_IDENTIFIER = )[^;]*\.ShareExtension;'),
        (match) => '${match.group(1)}$bundleIdentifier;');

    file.writeAsStringSync(updated);
  }

  /// Sets Provisioning Profile for Main App (Runner) target only
  void setMainAppProvisioningProfile(String provisioningProfileName) {
    file.verifyExistsOrThrow();

    print(
        'Setting Main App Provisioning Profile to "$provisioningProfileName"');
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

    print(
        'Setting ShareExtension Provisioning Profile to "$provisioningProfileName"');
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
        RegExp(
            r'(name = (?:Debug|Release|Profile);.*?buildSettings = \{.*?)(PRODUCT_BUNDLE_IDENTIFIER = )[^;]*;',
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

  /// Sets Bundle ID and App Group for ShareExtension target only
  void configureShareExtension({
    required String bundleIdentifier,
    required String appGroup,
    String? provisioningProfile,
  }) {
    file.verifyExistsOrThrow();

    print(
        'Configuring ShareExtension with Bundle ID "$bundleIdentifier" and App Group "$appGroup"');
    final content = file.readAsStringSync();
    final lines = content.split('\n');

    bool inShareExtensionSection = false;
    bool inBuildSettings = false;
    int braceDepth = 0;

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];

      // Detect ShareExtension section
      if (line.contains('name = ShareExtension') ||
          (line.contains('Debug') && inShareExtensionSection) ||
          (line.contains('Release') && inShareExtensionSection) ||
          (line.contains('Profile') && inShareExtensionSection)) {
        inShareExtensionSection = true;
      }

      // Track buildSettings sections
      if (line.contains('buildSettings = {') && inShareExtensionSection) {
        inBuildSettings = true;
        braceDepth = 1;
      } else if (inBuildSettings) {
        if (line.contains('{')) braceDepth++;
        if (line.contains('}')) {
          braceDepth--;
          if (braceDepth == 0) {
            inBuildSettings = false;
            inShareExtensionSection = false;
          }
        }
      }

      // Update settings within ShareExtension buildSettings
      if (inBuildSettings && inShareExtensionSection) {
        if (line.contains('PRODUCT_BUNDLE_IDENTIFIER')) {
          lines[i] = line.replaceAll(
              RegExp('PRODUCT_BUNDLE_IDENTIFIER = [^;]*;'),
              'PRODUCT_BUNDLE_IDENTIFIER = $bundleIdentifier;');
        }
        if (line.contains('RECEIVE_SHARE_INTENT_GROUP_ID')) {
          lines[i] = line.replaceAll(
              RegExp('RECEIVE_SHARE_INTENT_GROUP_ID = [^;]*;'),
              'RECEIVE_SHARE_INTENT_GROUP_ID = $appGroup;');
        }
        if (provisioningProfile != null &&
            line.contains('PROVISIONING_PROFILE_SPECIFIER')) {
          lines[i] = line.replaceAll(
              RegExp('PROVISIONING_PROFILE_SPECIFIER = [^;]*;'),
              'PROVISIONING_PROFILE_SPECIFIER = "$provisioningProfile";');
        }
        if (line.contains('CODE_SIGN_STYLE')) {
          lines[i] = line.replaceAll(
              RegExp('CODE_SIGN_STYLE = [^;]*;'), 'CODE_SIGN_STYLE = Manual;');
        }
      }
    }

    file.writeAsStringSync(lines.join('\n'));
  }
}

extension XcodePbxprojFile on File {
  XcodePbxproj asXcodePbxproj() {
    return XcodePbxproj(this);
  }
}
