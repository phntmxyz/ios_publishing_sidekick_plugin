// ignore_for_file: unused_local_variable, avoid_print, dead_code

import 'dart:io';

import 'package:phntmxyz_ios_publishing_sidekick_plugin/phntmxyz_ios_publishing_sidekick_plugin.dart';

/// Examples of creating and managing macOS keychains for code signing.
///
/// ⚠️ **WARNING**: Running these examples may modify or overwrite your macOS keychains!
/// These examples are for demonstration purposes only. Do NOT run this code directly
/// on your development machine without understanding the implications.
///
/// The examples below will:
/// - Create new keychains that may conflict with existing ones
/// - Potentially modify your default keychain settings
/// - Import certificates that could affect code signing
///
/// **Recommended usage**:
/// - Read these examples to understand the API
/// - Adapt them carefully for your specific CI/CD environment
/// - Test in a sandboxed environment first
/// - Use unique keychain names to avoid conflicts
void main() {
  // Safety check: Prevent accidental execution
  throw UnsupportedError(
    'This example should not be run directly! '
    'It may modify your macOS keychains. '
    'Please read the code and adapt it for your specific use case. '
    'If you really want to run this example, comment out this safety check.',
  );

  // Example 1: Creating and Configuring a Keychain
  creatingAndConfiguringKeychain();

  // Example 2: Using Different Keychain Types
  usingDifferentKeychainTypes();

  // Example 3: Adding Certificates to Keychain
  addingCertificatesToKeychain();

  // Example 4: CI/CD Keychain Setup
  setupCIKeychain(File('certificates/distribution.p12'), 'cert-password');
}

/// Create a custom keychain.
void creatingAndConfiguringKeychain() {
  // Create a custom keychain
  final keychain = Keychain(name: 'build-keychain');
  keychain.password = 'super-secret-password';

  // Check if keychain exists
  if (keychain.exists()) {
    print('Keychain already exists');
  }

  // Create keychain (override if exists)
  keychain.create(override: true);

  // Unlock the keychain
  keychain.unlock();

  // Set as default keychain for Xcode
  keychain.setAsDefault();
}

/// Use different types of keychains.
void usingDifferentKeychainTypes() {
  // Use login keychain
  final loginKeychain = Keychain.login();
  loginKeychain.unlock();

  // Use keychain from specific file
  final customKeychain = Keychain.file(
    file: File('/path/to/custom.keychain'),
  );
  customKeychain.password = 'password';
  customKeychain.unlock();
}

/// Add P12 certificates to keychain.
void addingCertificatesToKeychain() {
  // Add a P12 certificate to keychain
  final keychain = Keychain(name: 'build-keychain');
  keychain.password = 'keychain-password';
  keychain.create(override: true);
  keychain.unlock();

  keychain.addPkcs12Certificate(
    File('certificates/distribution.p12'),
    password: 'certificate-password',
  );

  // Add certificate without password
  keychain.addPkcs12Certificate(
    File('certificates/development.p12'),
  );
}

/// Complete CI setup.
void setupCIKeychain(File certificate, String certPassword) {
  final keychain = Keychain(name: 'ci-keychain');
  keychain.password = 'temporary-ci-password';

  // Clean setup
  keychain.create(override: true);
  keychain.setAsDefault();
  keychain.unlock();

  // Import certificate
  keychain.addPkcs12Certificate(
    certificate,
    password: certPassword,
  );

  print('CI keychain ready for code signing');
}
