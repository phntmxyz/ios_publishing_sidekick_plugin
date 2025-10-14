import 'dart:io';

import 'package:dcli/dcli.dart';

/// Extracts certificate information from a P12 (PKCS#12) certificate file.
///
/// Uses OpenSSL to read the [certificate] and extract the friendly name and local key ID.
/// Automatically handles legacy Apple certificates by retrying with the `-legacy` flag if needed.
///
/// The optional [password] is used to decrypt the certificate (defaults to empty string).
///
/// Throws when OpenSSL fails to read the certificate.
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
  start(command, progress: normalProgress, nothrow: true);

  if (normalProgress.exitCode == 0) {
    return normalProgress.out;
  }

  // Apple sometimes uses an older version of openssl which can't be read by
  // newer versions unless the -legacy flag is set.
  // The flag is not supported by older openssl versions, so we have to try twice
  final legacyProgress = Progress.capture();
  start('$command -legacy', progress: legacyProgress, nothrow: true);

  if (legacyProgress.exitCode == 0) {
    return legacyProgress.out;
  }

  // Both attempts failed
  print(
    'Failed to read certificate with openssl:\n'
    'Without -legacy flag (exit code ${normalProgress.exitCode}):\n'
    '${normalProgress.out}\n'
    'With -legacy flag (exit code ${legacyProgress.exitCode}):\n'
    '${legacyProgress.out}\n',
  );
  throw Exception(
    'openssl failed to read certificate. '
    'Exit codes: '
    'normal=${normalProgress.exitCode}, '
    'legacy=${legacyProgress.exitCode}',
  );
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
