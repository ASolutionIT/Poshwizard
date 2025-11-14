# PoshWizard Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Removed
- **Add-WizardDropdownFromCsv**: Use `Import-Csv` + `Add-WizardDropdown` instead

### Changed
- **Documentation**: Updated cmdlet naming, added Common Pitfalls section, simplified CSV loading guidance

## [1.4.3] - 2025-10-31

### Added
- **Password Validation**: `-ValidationPattern` and `-ValidationMessage` parameters for `Add-WizardPassword`

### Fixed
- **Logging**: Scripts now use original script name for log files (not temp GUID)
- **Timestamps**: Log files include seconds (`yyyy-MM-dd_HHmmss`)
- **Documentation**: Corrected Mandatory parameter guidance

## [1.4.2] - 2025-10-30

### Fixed
- **CRITICAL**: Fixed "Error: One or more errors occurred" when navigating backwards with multiple dynamic dependencies
- Solution: Changed dependent parameter refresh to sequential execution

### Added
- `Demo-DynamicControls.ps1` - Showcase of cascading dynamic controls

## [1.4.1] - 2025-10-25

### Changed
- **BREAKING**: Removed `Add-WizardDynamicDropdown` (consolidated into `Add-WizardDropdown`)
- **NEW**: `Add-WizardDropdown` and `Add-WizardListBox` now support `-ScriptBlock` parameter
- **NEW**: Both controls support `-DependsOn` parameter for explicit dependencies
- Auto-detection of dependencies from `param()` blocks

## [1.4.0] - 2025-10-18

### Added
- **Path Controls**: `Filter`, `DialogTitle`, and `ValidateExists` parameters
- File extension filtering (`"*.ps1"` or `"*.log;*.txt"`)
- Custom dialog titles for better UX

## [1.3.0] - 2025-10-14

### Added
- **Dynamic Parameter Safeguards**: Timeout protection (30s), result limits (1000 items)
- **Progress Indicators**: Automatic progress overlay for operations exceeding 500ms
- **Enhanced Error Messages**: Detailed CSV and script block errors with suggestions

---

## [1.2.0] - 2025-10-13

### Added
- **Hybrid Control Approach**: Optional explicit attributes (e.g., `[WizardTextBox(MaxLength=...)]`)
- **Dynamic Parameters**: `[WizardDataSource]` attribute for cascading dropdowns
- **Modern Folder Selector**: Vista-style picker with breadcrumb navigation

### Fixed
- Folder selector dialog not showing
- Step icon overwriting for multi-parameter steps
- CSV dropdown parameter binding

---

## [1.1.0] - 2025-10-08

### Added
- **New Controls**: Numeric spinner, Date picker, Option group, Multi-line text, ListBox, Cards
- **Visual Improvements**: Fluent Design system, shadows, hover animations

---

## [1.0.0] - Initial Release

### Core Features
- Native Verb-Noun PowerShell cmdlets for wizard creation
- Live execution console with real-time streaming
- Light/dark theme support
- WPF-based modern UI
- No third-party dependencies

### Controls
- TextBox, Password, CheckBox, Toggle, Dropdown, File/Folder selectors, Cards

### Architecture
- .NET Framework 4.8 WPF application
- PowerShell 5.1 compatible

---

## Version Numbering

- **Major.Minor.Patch** format
- **Major:** Breaking changes
- **Minor:** New features (backwards compatible)
- **Patch:** Bug fixes and minor improvements
