import 'package:dcli/dcli.dart';
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
    start('security create-keychain -p "${_password ?? ''}" $where');
    print("Created keychain $where");
  }

  /// Unlock the keychain, especially important on CI
  ///
  /// This should be done right before calling xcodebuild, it locks automatically after 5min
  ///
  /// Following: https://docs.github.com/en/actions/deployment/deploying-xcode-applications/installing-an-apple-certificate-on-macos-runners-for-xcode-development
  void unlock() {
    final file = this.file;
    if (file == null) {
      start('security unlock-keychain -p "${_password ?? ''}"');
      print('Unlocked keychain "login"');
    } else {
      // prevent the keychain from locking after 5min
      start(
        'security set-keychain-settings -lut ${const Duration(hours: 2).inSeconds} ${file.absolute.path}',
      );
      start(
        'security unlock-keychain -p "${_password ?? ''}" ${file.absolute.path}',
      );
      print('Unlocked keychain "$name" at ${file.absolute.path}');
    }
  }

  /// Sets this keychain as default so that Xcode will use it
  /// https://stackoverflow.com/questions/16550594/jenkins-xcode-build-works-codesign-fails/19550453#19550453
  void setAsDefault() {
    final file = this.file;
    if (file == null) {
      throw 'login keychain cannot be set as default, because the location is unknown';
    }
    assert(file.extension == '.keychain');

    // make sure Xcode uses this keychain
    // Set the search list to the specified keychains
    start('security list-keychains -s ${file.absolute.path}');
    //  Set the default keychain to the specified keychain
    start('security default-keychain -s ${file.absolute.path}');
  }

  void addPkcs12Certificate(File certificate, {String? password = ''}) {
    startFromArgs('security', [
      'import', //  import inputfile [-k keychain] [-t type] [-f format] [-w] [-P passphrase] [options...]
      certificate.absolute.path,
      '-A', // Allow any application to access the imported key without warning (insecure, not recommended!)
      ...[
        '-t', // Type = pub|priv|session|cert|agg
        'agg' // agg is one of the aggregate types (pkcs12 and PEM sequence)
      ],
      if (password != null) ...[
        '-P', // Specify wrapping passphrase immediately (default is secure passphrase via GUI)
        password
      ],
      if (file != null) ...[
        '-k', // Target keychain to import into
        file!.absolute.path,
      ],
    ]);
  }
}
