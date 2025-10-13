import 'dart:io';

Future<P12CertificateInfo> readP12CertificateInfo(
  File certificate, {
  String? password,
}) async {
  final certInfo = await _opensslPkcs12(certificate, password: password);

  final friendlyNameRegEx = RegExp('friendlyName: (.*)');
  final friendlyName = friendlyNameRegEx.firstMatch(certInfo)?.group(1);
  final localKeyIDRegEx = RegExp('localKeyID: (.*)');
  final localKeyID = localKeyIDRegEx.firstMatch(certInfo)?.group(1);
  return P12CertificateInfo(
    friendlyName: friendlyName!,
    localKeyId: localKeyID!,
  );
}

Future<String> _opensslPkcs12(File certificate, {String? password}) async {
  final baseArgs = [
    'pkcs12',
    '-info',
    '-in',
    certificate.absolute.path,
    '-clcerts',
    '-nokeys',
    '-passin',
    'pass:${password ?? ''}',
  ];

  try {
    final result = await Process.run('openssl', baseArgs);
    if (result.exitCode == 0) {
      return result.stdout as String;
    }
    throw Exception('openssl failed with exit code ${result.exitCode}: ${result.stderr}');
  } catch (normalE) {
    // Apple sometimes uses an older version of openssl which can't be read by
    // newer versions unless the -legacy flag is set.
    // The flag is not supported by older openssl versions, so we have to try twice
    try {
      final result = await Process.run('openssl', [...baseArgs, '-legacy']);
      if (result.exitCode == 0) {
        return result.stdout as String;
      }
      throw Exception('openssl with -legacy failed with exit code ${result.exitCode}: ${result.stderr}');
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
