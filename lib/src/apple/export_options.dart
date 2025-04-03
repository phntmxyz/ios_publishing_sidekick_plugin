/// ExportOptionsPlist method
///
/// Describes how Xcode should export the archive.
enum ExportMethod {
  @Deprecated('Use releaseTesting instead')
  adHoc('ad-hoc'),

  releaseTesting('release-testing'),

  @Deprecated('Use appStoreConnect instead')
  appStore('app-store'),

  appStoreConnect('app-store-connect'),

  validation('validation'),

  package('package'),

  enterprise('enterprise'),

  developerId('developer-id'),

  macApplication('mac-application');

  final String value;
  const ExportMethod(this.value);
}
