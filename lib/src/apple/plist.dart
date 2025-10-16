import 'package:sidekick_core/sidekick_core.dart';

class XcodePlist {
  final File file;
  XcodePlist(this.file);

  /// Sets the App Group ID in the plist file
  void setAppGroupId(String appGroupId) {
    setStringValue('AppGroupId', appGroupId);
  }

  /// Sets a string value for a given key in the plist
  void setStringValue(String key, String value) {
    file.verifyExistsOrThrow();

    print('Setting "$key" to "$value" in ${file.path}');
    final content = file.readAsStringSync();

    // Match key-value pair in plist
    // <key>YourKey</key>
    // <string>value</string>
    final keyValueRegex = RegExp(
      '<key>${RegExp.escape(key)}</key>\\s*<string>[^<]*</string>',
      multiLine: true,
    );

    final match = keyValueRegex.hasMatch(content);
    if (!match) {
      throw "plist doesn't contain key '$key' with a string value";
    }

    final updated = content.replaceAll(
      keyValueRegex,
      '<key>$key</key>\n\t<string>$value</string>',
    );

    file.writeAsStringSync(updated);
  }

  /// Sets the CFBundleIdentifier in the plist
  void setBundleIdentifier(String bundleIdentifier) {
    setStringValue('CFBundleIdentifier', bundleIdentifier);
  }

  /// Sets the CFBundleDisplayName in the plist
  void setBundleDisplayName(String displayName) {
    setStringValue('CFBundleDisplayName', displayName);
  }

  /// Sets the CFBundleName in the plist
  void setBundleName(String bundleName) {
    setStringValue('CFBundleName', bundleName);
  }
}

extension XcodePlistFile on File {
  XcodePlist asXcodePlist() {
    return XcodePlist(this);
  }
}
