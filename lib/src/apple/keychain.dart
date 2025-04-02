import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/util/start_timeout.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Represents the keychain on macos
class Keychain {
  final String? name;
  final File? file;

  Keychain({
    required this.name,
  }) :
        // do not save it in `~/Library/Keychains` because accessing this directory
        // will open a modal window (popup)
        file = File('${env['HOME']}/$name.keychain');

  Keychain.file({required this.file}) : name = null;

  /// Default macos keychain
  Keychain.login()
      : name = null,
        file = null;

  bool exists() {
    if (file == null) return true;
    return file!.existsSync();
  }

  String? _password;
  // ignore: avoid_setters_without_getters
  set password(String password) {
    _password = password;
  }

  void create({bool override = false}) {
    if (file == null) {
      throw 'login keychain already exists';
    }
    final where = file!.absolute.path;
    if (exists()) {
      if (!override) {
        throw 'keychain $where already exists';
      }
      File(where).deleteSync();
    }
    startWithTimeout('security create-keychain -p "${_password ?? ''}" $where');
    print("Created keychain $where");
  }

  /// Unlock the keychain, especially important on CI
  ///
  /// This should be done right before calling xcodebuild, it locks automatically after 5min
  ///
  /// Following: https://docs.github.com/en/actions/deployment/deploying-xcode-applications/installing-an-apple-certificate-on-macos-runners-for-xcode-development
  void unlock() {
    final file = this.file;
    print('Unlock keychain called');
    print('File: ${file?.absolute.path ?? 'login'}');

    if (file == null) {
      print('Unlocking keychain "login"');
      try {
        print('Running: security unlock-keychain');
        startWithTimeout('security unlock-keychain -p "${_password ?? ''}"');
        print('Unlocked keychain "login" successfully');
      } catch (e) {
        print('Failed to unlock login keychain: $e');
        rethrow;
      }
    } else {
      print('Unlocking keychain ${file.absolute.path}');
      // prevent the keychain from locking after 5min
      try {
        final unlockSeconds = const Duration(hours: 2).inSeconds;
        print('Setting keychain timeout to $unlockSeconds seconds');
        startWithTimeout(
          'security set-keychain-settings -lut ${const Duration(hours: 2).inSeconds} ${file.absolute.path}',
        );
        print('Set keychain ${file.absolute.path} to unlock after 2h');
      } catch (e) {
        print('Failed to set keychain settings: $e');
        rethrow;
      }

      try {
        print('Running: security unlock-keychain');
        startWithTimeout(
          'security unlock-keychain -p "${_password ?? ''}" ${file.absolute.path}',
        );
        print('Unlocked keychain "$name" at ${file.absolute.path}');
      } catch (e) {
        print('Failed to unlock keychain: $e');
        rethrow;
      }
    }
    print('Unlock keychain completed');
  }

  /// Sets this keychain as default so that Xcode will use it
  /// https://stackoverflow.com/questions/16550594/jenkins-xcode-build-works-codesign-fails/19550453#19550453
  void setAsDefault() {
    final file = this.file;
    if (file == null) {
      throw 'login keychain cannot be set as default, because the location is unknown';
    }
    assert(file.extension == '.keychain');
    print('Setting keychain ${file.absolute.path} as default');

    // make sure Xcode uses this keychain
    // Set the search list to the specified keychains
    startWithTimeout('security list-keychains -s ${file.absolute.path}');
    //  Set the default keychain to the specified keychain
    startWithTimeout('security default-keychain -s ${file.absolute.path}');

    print('Set keychain ${file.absolute.path} as default');
  }

  void addPkcs12Certificate(File certificate, {String? password = ''}) {
    print('Adding certificate: ${certificate.absolute.path}');
    print('Target keychain: ${file?.absolute.path ?? 'login (default)'}');

    // Log whether a password is being used
    final hasPassword = password != null && password.isNotEmpty;
    print(
      'Using certificate password: ${hasPassword ? 'yes' : 'no (empty password)'}',
    );

    // Ensure the certificate is properly formatted and valid
    if (!certificate.existsSync()) {
      throw 'Certificate file does not exist: ${certificate.absolute.path}';
    }

    // Build the security command arguments
    final securityArgs = [
      'import', //  import inputfile [-k keychain] [-t type] [-f format] [-w] [-P passphrase] [options...]
      certificate.absolute.path,
      '-A', // Allow any application to access the imported key without warning (insecure, not recommended!)
      ...[
        '-t', // Type = pub|priv|session|cert|agg
        'agg', // agg is one of the aggregate types (pkcs12 and PEM sequence)
      ],
      // Always include -P flag, even with empty password
      // This prevents security from prompting for password via GUI
      '-P',
      password ?? '',
      if (file != null) ...[
        '-k', // Target keychain to import into
        file!.absolute.path,
      ],
    ];

    try {
      // Use our custom wrapper with timeout functionality if timeout is provided
      final result = startFromArgsWithTimeout('security', securityArgs);

      if (result.exitCode != 0) {
        throw 'Security import failed with exit code ${result.exitCode}';
      }
      print('Added certificate to keychain successfully');
    } catch (e) {
      print('Failed to add certificate: $e');
      rethrow;
    }
    print('Certificate import completed');
  }
}
