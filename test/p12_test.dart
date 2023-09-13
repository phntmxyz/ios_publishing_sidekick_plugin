import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/src/apple/p12.dart';
import 'package:test/test.dart';

void main() {
  test('read friendlyName with openssl 3.1.2', () {
    final cert = File('test/resources/certificate_openssl_3_1_2.p12');
    final info = readP12CertificateInfo(cert);
    expect(info.friendlyName, 'iPhone Distribution: PHNTM');
  });

  test('read friendlyName with libressl 3.3.6', () {
    final cert = File('test/resources/certificate_libressl_3_3_6.p12');
    final info = readP12CertificateInfo(cert);
    expect(info.friendlyName, 'iPhone Distribution: PHNTM');
  });
}
