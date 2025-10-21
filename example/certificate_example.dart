// ignore_for_file: unused_local_variable, avoid_print

import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

/// Examples of reading and extracting information from P12 certificates.
void main() {
  // Example 1: Reading Certificate Information
  readingCertificateInformation();

  // Example 2: Validating Certificates
  validateCertificate(File('certificates/distribution.p12'), 'password');
}

/// Read certificate info from P12 file.
void readingCertificateInformation() {
  // Read certificate info
  final certInfo = readP12CertificateInfo(
    File('certificates/distribution.p12'),
    password: 'certificate-password',
  );

  print('Certificate Name: ${certInfo.friendlyName}');
  print('Local Key ID: ${certInfo.localKeyId}');

  // Without password
  final devCertInfo = readP12CertificateInfo(
    File('certificates/development.p12'),
  );

  print('Development Certificate: ${devCertInfo.friendlyName}');
}

/// Check certificate details before using.
File validateCertificate(File certFile, String? password) {
  try {
    final info = readP12CertificateInfo(certFile, password: password);

    if (info.friendlyName.contains('Distribution')) {
      print('✓ Valid distribution certificate: ${info.friendlyName}');
      return certFile;
    } else {
      throw Exception('Expected distribution certificate');
    }
  } catch (e, stackTrace) {
    print('Certificate validation failed: $e');
    print(stackTrace);
    rethrow;
  }
}
