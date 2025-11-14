@{
    RootModule = 'PoshWizard.psm1'
    ModuleVersion = '1.4.3'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'A Solution IT LLC'
    CompanyName = 'A Solution IT LLC'
    Copyright = '(c) 2025 A Solution IT LLC. All rights reserved.'
    Description = 'PowerShell module for creating interactive wizards with native UI using Verb-Noun functions. Includes hybrid control approach, dynamic parameters, and modern dialogs.'
    
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.8'
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Core functions
        'New-PoshWizard',
        'Show-PoshWizard',
        'Export-WizardScript',
        
        # Step management
        'Add-WizardStep',
        
        # Input controls
        'Add-WizardTextBox',
        'Add-WizardPassword',
        'Add-WizardCheckbox',
        'Add-WizardToggle',
        'Add-WizardDropdown',
        'Add-WizardListBox',
        'Add-WizardFilePath',
        'Add-WizardFolderPath',
        'Add-WizardNumeric',
        'Add-WizardDate',
        'Add-WizardOptionGroup',
        'Add-WizardMultiLine',
        
        # Display controls
        'Add-WizardCard',
        
        # Configuration
        'Set-WizardBranding',
        'Set-WizardTheme',
        
        # Security and execution helpers
        'Invoke-PoshWizardExe'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    # File list for packaging - commented out to avoid path issues during development
    # FileList = @(
    #     'PoshWizard.psd1',
    #     'PoshWizard.psm1',
    #     'PoshWizard.IntelliSense.psm1',
    #     'bin\PoshWizard.exe',
    #     'Public\*.ps1',
    #     'Private\*.ps1',
    #     'Classes\*.ps1'
    # )
    
    PrivateData = @{
        PSData = @{
            Tags = @('Wizard', 'GUI', 'Forms', 'Interactive', 'PowerShell', 'WPF', 'UI')
            LicenseUri = 'https://github.com/PoshWizard/PoshWizard/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PoshWizard/PoshWizard'
            IconUri = 'https://github.com/PoshWizard/PoshWizard/blob/main/Assets/wizard_icon.png'
            ReleaseNotes = @'
v1.4.0 - Path Control Enhancements & Dynamic Dropdown Features (October 2025)

NEW FEATURES:
- FILE FILTERING: Simple extension-based filtering for file pickers
  * Filter parameter accepts "*.ps1" or "*.log;*.txt" format
  * Auto-converts to Windows dialog format internally
  * Shows only matching files in browse dialog
  
- DIALOG TITLES: Custom titles for file/folder picker dialogs
  * DialogTitle parameter for Add-WizardFilePath and Add-WizardFolderPath
  * Improves UX with context-specific prompts
  
- PATH VALIDATION: ValidateExists parameter for path controls
  * Validates selected paths exist before allowing progression
  * Prevents errors from invalid path input
  
- CACHE DURATION: Performance caching for dynamic dropdowns
  * CacheDuration parameter (in seconds) for Add-WizardDynamicDropdown
  * Avoids repeated execution of expensive operations
  * Improves performance for API calls, AD queries, etc.
  
- FALLBACK VALUES: Graceful degradation for dynamic dropdowns
  * FallbackValues parameter provides default values
  * Used when script block execution fails
  * Ensures wizard remains functional when external dependencies unavailable

BUG FIXES:
- File dialog filter now properly parses from WizardFilePath/WizardFolderPath attributes
- Dialog titles correctly applied to path selector dialogs
- Path filtering conversion handles both simple and complex filter formats
- ShowOpenFileDialog signature updated to accept filter and title parameters

v1.2.0 - Hybrid Controls & Dynamic Parameters (October 2025)

NEW FEATURES:
- HYBRID CONTROL APPROACH: Optional explicit attributes for enhanced features
  * [WizardTextBox(MaxLength, Placeholder)] - Enhanced text input with character limits and hints
  * [WizardPassword(ShowRevealButton, MinLength)] - Enhanced password with min length validation
  * [WizardCheckBox(CheckedLabel, UncheckedLabel)] - Enhanced checkbox with custom labels
  * Backwards compatible - all controls work WITHOUT explicit attributes (type-based defaults)
  
- DYNAMIC PARAMETERS (Phase 2): Real-time cascading dropdowns
  * [WizardDataSource] attribute with ScriptBlock execution
  * Auto-dependency detection from script block parameters
  * Real-time updates when dependencies change
  * Synchronous execution for reliable cascading

- MODERN FOLDER SELECTOR: Unified dialog experience
  * Vista-style folder browser (same as file picker)
  * Breadcrumb navigation, search, favorites
  * COM interop with IFileDialog (no Windows.Forms dependency)
  * Proper window ownership and error handling

CONTROL IMPROVEMENTS:
- All 14 controls now have explicit attributes (mix of optional/required)
- Numeric spinner control with increment/decrement buttons
- Date picker with calendar popup
- Option group (radio buttons) with horizontal/vertical layout
- Multi-line text with configurable rows
- ListBox with single/multi-select modes
- Informational cards for contextual help

SECURITY & ARCHITECTURE:
- Custom security validation with command blocklist
- Blocks dangerous cmdlets and unsafe operations
- Enhanced temp file security with ACLs
- Code signature verification support
- No third-party dependencies (uses native .NET 4.8)

VISUAL IMPROVEMENTS:
- Modern Windows 11 design system
- Enhanced button hover animations
- Professional Microsoft Blue accent theme
- Card elevation with drop shadows
- Consistent spacing (8px grid system)

BUG FIXES:
- Fixed folder selector dialog not showing
- Improved COM object cleanup (Marshal.ReleaseComObject)
- Fixed step icon overwriting for multi-parameter steps
- Enhanced error handling and logging
- Cleaned up obsolete code and files

DOCUMENTATION:
- Updated UI_CONTROLS_REFERENCE.md with hybrid approach
- Added Demo-OptionalAttributes.ps1 example
- Documented Phase 3 failed approaches for future reference
- Comprehensive attribute usage guide

FEATURES:
- Native Verb-Noun PowerShell API
- Full backward compatibility with parameter-based scripts
- Live execution console with real-time streaming
- Light/dark theme support
- IntelliSense and tab completion support
'@
        }
    }
}
