# Changelog

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