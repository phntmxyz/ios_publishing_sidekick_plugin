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
      (match) => '${match.group(1)}$bundleIdentifier;'
    );
    
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
      'RECEIVE_SHARE_INTENT_GROUP_ID = $appGroupId;',
    );
    file.writeAsStringSync(updated);
  }
}

extension XcodePbxprojFile on File {
  XcodePbxproj asXcodePbxproj() {
    return XcodePbxproj(this);
  }
}
