/// ExportOptionsPlist method
//
/// Describes how Xcode should export the archive.
enum ExportMethod {
  adHoc('ad-hoc'),
  appStore('app-store'),
  validation('validation'),
  package('package'),
  enterprise('enterprise'),
  developerId('developer-id'),
  macApplication('mac-application');

  final String value;
  const ExportMethod(this.value);
}
