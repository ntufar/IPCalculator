# Changelog

All notable changes to this project will be documented in this file.

## [1.0.3] - 2026-06-01

### Added
- New adaptive app icon with network topology design (purple theme)
- 512px Play Store icon and 1024x500 feature graphic
- Round icon support for modern Android launchers

### Changed
- Migrated launcher icon from flat PNGs to mipmap-based adaptive icon
- Updated AndroidManifest to reference mipmap icons

## [1.0.2] - 2026-06-01

### Added
- Styled IP rollers with individual rounded backgrounds for each octet picker
- Custom dot separators between IP octets (replaced plain text dots)
- Styled CIDR "/" separator chip
- Primary-color selection dividers on NumberPickers

### Changed
- Elevated IP roller card for subtle depth
- Improved NumberPicker visual styling with theme overlay
- Increased vertical padding in picker row for better touch targets

## [1.0.1] - 2026-06-01

### Added
- CI/CD pipeline for automatic Play Store Internal Testing deployment on version tags
- Landing page and privacy policy (GitHub Pages)
- Release signing configuration with keystore

### Changed
- Modernized project: migrated from Eclipse/ADT to Gradle + Kotlin DSL
- Migrated UI to Material 3 (Material Design Components)
- Migrated to ViewBinding for type-safe view access
- Updated target SDK to 36 (Android 15)

## [1.0.0] - 2013-08-05

### Added
- Initial IP Calculator with CIDR input via NumberPicker rollers
- Subnet mask, broadcast address, wildcard mask calculation
- Host address range and number of hosts display
- Binary netmask representation
