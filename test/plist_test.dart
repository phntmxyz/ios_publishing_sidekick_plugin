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

    group('setArrayValue', () {
      test('updates array with single value successfully', () {
        final plist = XcodePlist(testPlist);

        plist.setArrayValue('com.apple.security.application-groups',
            ['group.com.newapp.share']);

        final content = testPlist.readAsStringSync();
        expect(content,
            contains('<key>com.apple.security.application-groups</key>'));
        expect(content, contains('<array>'));
        expect(content, contains('<string>group.com.newapp.share</string>'));
        expect(content, contains('</array>'));
      });

      test('updates array with multiple values successfully', () {
        final plist = XcodePlist(testPlist);

        plist.setArrayValue('com.apple.security.application-groups', [
          'group.com.example.app',
          'group.com.example.share',
          'group.com.example.widget'
        ]);

        final content = testPlist.readAsStringSync();
        expect(content,
            contains('<key>com.apple.security.application-groups</key>'));
        expect(content, contains('<string>group.com.example.app</string>'));
        expect(content, contains('<string>group.com.example.share</string>'));
        expect(content, contains('<string>group.com.example.widget</string>'));
      });

      test('preserves other plist entries', () {
        final plist = XcodePlist(testPlist);

        plist.setArrayValue('com.apple.security.application-groups',
            ['group.com.newapp.share']);

        final content = testPlist.readAsStringSync();
        expect(content, contains('<key>CFBundleIdentifier</key>'));
        expect(content, contains('<key>AppGroupId</key>'));
        expect(content, contains('<key>NSExtension</key>'));
      });

      test('throws error when key is missing', () {
        final plist = XcodePlist(testPlist);

        expect(
          () => plist.setArrayValue('NonExistentKey', ['value']),
          throwsA(contains("plist doesn't contain key 'NonExistentKey'")),
        );
      });

      test('converts string value to array with single value', () {
        final plist = XcodePlist(testPlist);

        // AppGroupId is initially a string value
        final contentBefore = testPlist.readAsStringSync();
        expect(contentBefore, contains('<key>AppGroupId</key>'));
        expect(contentBefore,
            contains(r'<string>$(RECEIVE_SHARE_INTENT_GROUP_ID)</string>'));
        expect(
            contentBefore, isNot(contains('<key>AppGroupId</key>\n\t<array>')));

        // Convert to array
        plist.setArrayValue('AppGroupId', ['group.com.example.app']);

        final contentAfter = testPlist.readAsStringSync();
        expect(contentAfter, contains('<key>AppGroupId</key>'));
        expect(contentAfter, contains('<array>'));
        expect(
            contentAfter, contains('<string>group.com.example.app</string>'));
        expect(contentAfter, contains('</array>'));
        // Old string value should be gone
        expect(
            contentAfter,
            isNot(contains(
                r'<string>$(RECEIVE_SHARE_INTENT_GROUP_ID)</string>')));
      });

      test('converts string value to array with multiple values', () {
        final plist = XcodePlist(testPlist);

        // AppGroupId is initially a string value
        final contentBefore = testPlist.readAsStringSync();
        expect(contentBefore,
            contains(r'<string>$(RECEIVE_SHARE_INTENT_GROUP_ID)</string>'));

        // Convert to array with multiple values
        plist.setArrayValue('AppGroupId', [
          'group.com.example.app',
          'group.com.example.share',
        ]);

        final contentAfter = testPlist.readAsStringSync();
        expect(contentAfter, contains('<key>AppGroupId</key>'));
        expect(contentAfter, contains('<array>'));
        expect(
            contentAfter, contains('<string>group.com.example.app</string>'));
        expect(
            contentAfter, contains('<string>group.com.example.share</string>'));
        expect(contentAfter, contains('</array>'));
      });

      test('converts integer value to array', () {
        // Create plist with integer value
        testPlist.writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SomeNumber</key>
	<integer>42</integer>
</dict>
</plist>''');

        final plist = XcodePlist(testPlist);
        plist.setArrayValue('SomeNumber', ['value1', 'value2']);

        final content = testPlist.readAsStringSync();
        expect(content, contains('<key>SomeNumber</key>'));
        expect(content, contains('<array>'));
        expect(content, contains('<string>value1</string>'));
        expect(content, contains('<string>value2</string>'));
        expect(content, isNot(contains('<integer>42</integer>')));
      });

      test('converts boolean value to array', () {
        // Create plist with boolean value
        testPlist.writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SomeFlag</key>
	<true/>
</dict>
</plist>''');

        final plist = XcodePlist(testPlist);
        plist.setArrayValue('SomeFlag', ['option1', 'option2']);

        final content = testPlist.readAsStringSync();
        expect(content, contains('<key>SomeFlag</key>'));
        expect(content, contains('<array>'));
        expect(content, contains('<string>option1</string>'));
        expect(content, contains('<string>option2</string>'));
        expect(content, isNot(contains('<true/>')));
      });

      test('converts dict value to array', () {
        final plist = XcodePlist(testPlist);

        // NSExtension is a dict in the sample plist
        plist.setArrayValue('NSExtension', ['item1', 'item2']);

        final content = testPlist.readAsStringSync();
        expect(content, contains('<key>NSExtension</key>'));
        expect(content, contains('<array>'));
        expect(content, contains('<string>item1</string>'));
        expect(content, contains('<string>item2</string>'));
        // Dict content should be gone
        expect(content, isNot(contains('<key>NSExtensionAttributes</key>')));
      });

      test('handles empty array', () {
        final plist = XcodePlist(testPlist);

        plist.setArrayValue('com.apple.security.application-groups', []);

        final content = testPlist.readAsStringSync();
        expect(content,
            contains('<key>com.apple.security.application-groups</key>'));
        expect(content, contains('<array>'));
        expect(content, contains('</array>'));
      });

      test('handles values with special characters', () {
        final plist = XcodePlist(testPlist);

        plist.setArrayValue('com.apple.security.application-groups',
            [r'$(RECEIVE_SHARE_INTENT_GROUP_ID)']);

        final content = testPlist.readAsStringSync();
        print(content);
        expect(content,
            contains(r'<string>$(RECEIVE_SHARE_INTENT_GROUP_ID)</string>'));
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
