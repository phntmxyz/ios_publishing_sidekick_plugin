import 'dart:io';

import 'package:dcli/dcli.dart';

P12CertificateInfo readP12CertificateInfo(File phntmCertificate) {
  final progress = Progress.capture();
  start(
    'openssl pkcs12 -info -in ${phntmCertificate.absolute.path} -clcerts -nokeys -passin pass:',
    progress: progress,
  );
  final certInfo = progress.lines.join('\n');

  final friendlyNameRegEx = RegExp('friendlyName: (.*)');
  final friendlyName = friendlyNameRegEx.firstMatch(certInfo)?.group(1);
  final localKeyIDRegEx = RegExp('localKeyID: (.*)');
  final localKeyID = localKeyIDRegEx.firstMatch(certInfo)?.group(1);
  return P12CertificateInfo(
    friendlyName: friendlyName!,
    localKeyId: localKeyID!,
  );
}

class P12CertificateInfo {
  final String friendlyName;
  final String localKeyId;

  const P12CertificateInfo({
    required this.friendlyName,
    required this.localKeyId,
  });
}
