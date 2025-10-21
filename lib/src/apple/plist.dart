import 'package:sidekick_core/sidekick_core.dart';

class XcodePlist {
  final File file;
  XcodePlist(this.file);

  /// Sets the App Group ID in the plist file
  void setAppGroupId(String appGroupId) {
    setStringValue('AppGroupId', appGroupId);
  }

  /// Sets a string value for a given key in the plist
  ///
  /// If the key currently has any other value type (integer, real, boolean, dict, array),
  /// it will be converted to a string.
  void setStringValue(String key, String value) {
    _setValue(key, '<string>$value</string>');
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

  /// Sets an array of string values for a given key in the plist
  ///
  /// If the key currently has any other value type (string, integer, real, boolean, dict),
  /// it will be converted to an array. If the key already has an array value, it will be replaced.
  void setArrayValue(String key, List<String> values) {
    final arrayItems =
        values.map((value) => '\t\t<string>$value</string>').join('\n');
    final replacement = '<array>\n$arrayItems\n\t</array>';
    _setValue(key, replacement);
  }

  /// Internal method to set any value type for a given key in the plist
  ///
  /// This matches the key followed by any XML node and replaces it with the new value.
  /// The [newValue] should be the complete XML element (e.g., `<string>foo</string>`).
  void _setValue(String key, String newValue) {
    file.verifyExistsOrThrow();

    print('Setting "$key" in ${file.path}');
    final content = file.readAsStringSync();

    // Match key followed by the next XML node (any type)
    // This matches either:
    //   - Self-closing tags: <true/>, <false/>
    //   - Tags with content: <string>...</string>, <dict>...</dict>, etc.
    final keyValueRegex = RegExp(
      '<key>${RegExp.escape(key)}</key>\\s*'
      '(?:<[^>]+/>|<(\\w+)(?:\\s[^>]*)?>.*?</\\1>)',
      multiLine: true,
      dotAll: true,
    );

    if (!keyValueRegex.hasMatch(content)) {
      throw "plist doesn't contain key '$key' with a value";
    }

    final replacement = '<key>$key</key>\n\t$newValue';
    final updated = content.replaceAll(keyValueRegex, replacement);

    file.writeAsStringSync(updated);
  }
}

extension XcodePlistFile on File {
  XcodePlist asXcodePlist() {
    return XcodePlist(this);
  }
}
