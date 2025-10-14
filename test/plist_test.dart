import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/apple/plist.dart';
import 'package:test/test.dart';

void main() {
  group('XcodePlist', () {
    late Directory tempDir;
    late File testPlist;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('plist_test_');
      testPlist = File('${tempDir.path}/Info.plist');

      // Copy the sample plist file to temp directory
      final sampleFile = File('test/resources/sample_info.plist');
      testPlist.writeAsStringSync(sampleFile.readAsStringSync());
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('setAppGroupId', () {
      test('updates app group id successfully', () {
        final plist = XcodePlist(testPlist);

        plist.setAppGroupId('group.com.newapp.share');

        final content = testPlist.readAsStringSync();
        expect(content, contains('<string>group.com.newapp.share</string>'));
        expect(content, contains('<key>AppGroupId</key>'));
      });

      test('preserves other plist entries', () {
        final plist = XcodePlist(testPlist);

        plist.setAppGroupId('group.com.newapp.share');

        final content = testPlist.readAsStringSync();
        expect(content, contains('<key>CFBundleIdentifier</key>'));
        expect(content, contains('<key>CFBundleDisplayName</key>'));
        expect(content, contains('<key>NSExtension</key>'));
      });

      test('throws error when app groups key is missing', () {
        // Create a plist without app groups
        testPlist.writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>com.example.app</string>
</dict>
</plist>''');

        final plist = XcodePlist(testPlist);

        expect(
          () => plist.setAppGroupId('group.test'),
          throwsA(contains("plist doesn't contain key 'AppGroupId'")),
        );
      });

      test('handles app group ids with special characters', () {
        final plist = XcodePlist(testPlist);

        plist.setAppGroupId('group.com.example-app.share');

        final content = testPlist.readAsStringSync();
        expect(
            content, contains('<string>group.com.example-app.share</string>'));
      });
    });

    group('setBundleIdentifier', () {
      test('updates bundle identifier successfully', () {
        final plist = XcodePlist(testPlist);

        plist.setBundleIdentifier('com.newapp.ShareExtension');

        final content = testPlist.readAsStringSync();
        expect(content, contains('<key>CFBundleIdentifier</key>'));
        expect(content, contains('<string>com.newapp.ShareExtension</string>'));
      });

      test('preserves other plist entries', () {
        final plist = XcodePlist(testPlist);

        plist.setBundleIdentifier('com.newapp.ShareExtension');

        final content = testPlist.readAsStringSync();
        expect(content, contains('<key>CFBundleDisplayName</key>'));
        expect(content, contains('<string>ShareExtension</string>'));
      });

      test('throws error when CFBundleIdentifier key is missing', () {
        testPlist.writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleVersion</key>
	<string>1</string>
</dict>
</plist>''');

        final plist = XcodePlist(testPlist);

        expect(
          () => plist.setBundleIdentifier('com.test'),
          throwsA(contains("plist doesn't contain key 'CFBundleIdentifier'")),
        );
      });
    });

    group('setBundleDisplayName', () {
      test('updates bundle display name successfully', () {
        final plist = XcodePlist(testPlist);

        plist.setBundleDisplayName('My Share Extension');

        final content = testPlist.readAsStringSync();
        expect(content, contains('<key>CFBundleDisplayName</key>'));
        expect(content, contains('<string>My Share Extension</string>'));
      });

      test('throws error when CFBundleDisplayName key is missing', () {
        testPlist.writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleVersion</key>
	<string>1</string>
</dict>
</plist>''');

        final plist = XcodePlist(testPlist);

        expect(
          () => plist.setBundleDisplayName('Test'),
          throwsA(contains("plist doesn't contain key 'CFBundleDisplayName'")),
        );
      });
    });

    group('setBundleName', () {
      test('updates bundle name successfully', () {
        final plist = XcodePlist(testPlist);

        plist.setBundleName('MyProductName');

        final content = testPlist.readAsStringSync();
        expect(content, contains('<key>CFBundleName</key>'));
        expect(content, contains('<string>MyProductName</string>'));
      });
    });

    group('setStringValue', () {
      test('updates arbitrary string value successfully', () {
        final plist = XcodePlist(testPlist);

        plist.setStringValue('CFBundleVersion', '2.0');

        final content = testPlist.readAsStringSync();
        expect(content, contains('<key>CFBundleVersion</key>'));
        expect(content, contains('<string>2.0</string>'));
      });

      test('throws error when key is missing', () {
        final plist = XcodePlist(testPlist);

        expect(
          () => plist.setStringValue('NonExistentKey', 'value'),
          throwsA(contains("plist doesn't contain key 'NonExistentKey'")),
        );
      });
    });

    group('extension method', () {
      test('asXcodePlist creates XcodePlist instance', () {
        final plist = testPlist.asXcodePlist();
        expect(plist, isA<XcodePlist>());
        expect(plist.file.path, testPlist.path);
      });
    });
  });
}
