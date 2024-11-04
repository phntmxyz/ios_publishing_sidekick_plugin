import 'dart:io';

import 'package:dcli/dcli.dart';

P12CertificateInfo readP12CertificateInfo(
  File certificate, {
  String? password,
}) {
  final certInfo = _opensslPkcs12(certificate, password: password);

  final friendlyNameRegEx = RegExp('friendlyName: (.*)');
  final friendlyName = friendlyNameRegEx.firstMatch(certInfo)?.group(1);
  final localKeyIDRegEx = RegExp('localKeyID: (.*)');
  final localKeyID = localKeyIDRegEx.firstMatch(certInfo)?.group(1);
  return P12CertificateInfo(
    friendlyName: friendlyName!,
    localKeyId: localKeyID!,
  );
}

String _opensslPkcs12(File certificate, {String? password}) {
  final command =
      'openssl pkcs12 -info -in ${certificate.absolute.path} -clcerts -nokeys -passin pass:${password ?? ''}';

  final normalProgress = Progress.capture();
  try {
    start(command, progress: normalProgress);
    return normalProgress.out;
  } catch (normalE) {
    // Apple sometimes uses an older version of openssl which can't be read by
    // newer versions unless the -legacy flag is set.
    // The flag is not supported by older openssl versions, so we have to try twice
    final legacyProgress = Progress.capture();
    try {
      start('$command -legacy', progress: legacyProgress);
      return legacyProgress.out;
    } catch (legacyE) {
      print('Failed to read certificate with openssl:');
      print('Without -legacy flag:\n$normalE\n');
      print('With -legacy flag:\n$legacyE\n');
      rethrow;
    }
  }
}

class P12CertificateInfo {
  final String friendlyName;
  final String localKeyId;

  const P12CertificateInfo({
    required this.friendlyName,
    required this.localKeyId,
  });

  @override
  String toString() {
    return 'P12CertificateInfo{friendlyName: $friendlyName, localKeyId: $localKeyId}';
  }
}

extension on Progress {
  String get out => lines.join('\n');
}
