# Examples

This directory contains comprehensive, compilable examples for all APIs in the `phntmxyz_ios_publishing_sidekick_plugin` package.

## Quick Start

The most important function is `buildIpa()` - see [build_ipa_example.dart](build_ipa_example.dart) for complete build workflows.

## Example Files

### Core Functionality

- **[build_ipa_example.dart](build_ipa_example.dart)** - Building IPAs (most important!)
  - Simple App Store builds
  - Advanced builds with extensions
  - Different export methods (App Store, Ad Hoc, Enterprise, Development)
  - CI/CD build examples

- **[complete_workflows_example.dart](complete_workflows_example.dart)** - Complete workflows
  - Full publishing workflow
  - Multi-target apps with extensions
  - Combining plist, pbxproj, and build operations

### Configuration Helpers (Optional)

- **[plist_example.dart](plist_example.dart)** - Plist management
  - Setting string values (bundle ID, display name, etc.)
  - Setting array values (app groups, URL schemes, background modes)
  - Creating plist from Map

- **[xcode_project_example.dart](xcode_project_example.dart)** - Xcode project configuration
  - Basic configuration (bundle ID, provisioning, code signing)
  - App extension configuration
  - Reading build settings

- **[keychain_example.dart](keychain_example.dart)** - Keychain management
  - Creating and configuring keychains
  - Using different keychain types
  - Adding certificates to keychain
  - CI/CD keychain setup

- **[certificate_example.dart](certificate_example.dart)** - Certificate handling
  - Reading certificate information
  - Validating certificates

- **[provisioning_profile_example.dart](provisioning_profile_example.dart)** - Provisioning profiles
  - Reading profile information
  - Installing profiles
  - Validating expiration

## Running Examples

These examples are meant to demonstrate API usage and may not run successfully without:
- Valid certificates (.p12 files)
- Valid provisioning profiles (.mobileprovision files)
- Proper Xcode project structure
- macOS environment with Xcode installed

To check that examples compile:

```bash
puro dart analyze example/
```

## Learning Path

If you're new to this package, we recommend reading the examples in this order:

1. **Start here**: [build_ipa_example.dart](build_ipa_example.dart) - Understand the main `buildIpa()` function
2. **Then**: [complete_workflows_example.dart](complete_workflows_example.dart) - See complete real-world workflows
3. **Optional**: Explore the configuration helpers (plist, pbxproj, keychain, etc.) if you need advanced customization

Most users will only need `buildIpa()` and won't need to use the configuration helpers directly!
