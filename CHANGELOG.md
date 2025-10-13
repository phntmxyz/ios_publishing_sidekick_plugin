# Changelog

## 2.0.0
- Make `readP12CertificateInfo` async
- Fix port leak in `readP12CertificateInfo` which prevented the Dart VM from exiting (cli hangs after completion)

## 1.0.0
- `buildIpa()` is now async
- Update to sidekick_core 3.0.0

## 0.5.0
- Add missing awaits

## 0.4.0
- Update minimum Dart SDK to 3.5.0
- Update Sidekick Core to 3.0.0-preview.5
- Update dcli to 7.0.2

## 0.3.0
- Deprecate `ExportMethod.adHoc` in favor of new `ExportMethod.releaseTesting`
- Add timeout to keychain commands (default 60s)
- Always add -P "" (no password) when importing certificates into the keychain. This prevents a password prompt (hang on CI)
- More keychain logging in case of an error

## 0.2.5
- Unlock keychain before importing the certificate

## 0.2.4

- Always set the `DEVELOPMENT_TEAM`
- New: `XcodePbxproj` methods: `setCodeSignStyle` and `setDevelopmentTeam`

## 0.2.3

- Add certificatePassword to `buildIpa`
- Add `ExportMethod.appStoreConnect`, deprecate `ExportMethod.appStore`

## 0.2.2

- add `archiveSilenceTimeout` to `buildIpa`

## 0.2.1

- Unlock keychain after long builds before signing #6
- Support for OpenSSL 3.1.0 with the `-legacy` flag #8

## 0.2.0

- Update to Dart 3

## 0.1.0

- manual signing of the iOS App
- Installer for sidekick 1.0.0