# PoshWizard Controls Guide

**Version**: 1.4.3  
**Last Updated**: 2025-10-31

A comprehensive guide to all available controls in PoshWizard and how they work.

---

## Table of Contents

1. [How Controls Work](#how-controls-work)
2. [Control Types Overview](#control-types-overview)
3. [Text Controls](#text-controls)
4. [Password Controls](#password-controls)
5. [Selection Controls](#selection-controls)
6. [Boolean Controls](#boolean-controls)
7. [Numeric & Date Controls](#numeric--date-controls)
8. [Path Selection Controls](#path-selection-controls)
9. [Information Controls](#information-controls)
10. [Dynamic Controls](#dynamic-controls)
11. [Validation](#validation)

---

## How Controls Work

### The Big Picture

PoshWizard controls are the bridge between your PowerShell scripts and the professional WPF UI. Here's how they work:

```
Your PowerShell Script
    ↓
You define controls using Module API or Direct Attributes
    ↓
PowerShell Module generates a temporary script with control definitions
    ↓
Module launches PoshWizard.exe with the generated script
    ↓
WPF Executable PARSES the control definitions
    ↓
EXE renders the UI based on control types
    ↓
User interacts with controls (fills in values, makes selections)
    ↓
EXE collects the data and returns results
    ↓
Your script processes the results
```

### Two Ways to Define Controls

**Option 1: PowerShell Cmdlets** (Recommended)
```powershell
New-PoshWizard -Title 'My Wizard'
Add-WizardStep -Name 'Config' -Title 'Configuration' -Order 1
Add-WizardTextBox -Step 'Config' -Name 'ServerName' -Label 'Server' -Mandatory
Show-PoshWizard
```

**Option 2: Direct Attributes** (Parameter-based, legacy)
```powershell
[WizardStep("Config", 1)]
[WizardParameterDetails(Label='Server')]
[WizardTextBox(MaxLength=50)]
[string]$ServerName
```

Both approaches create the same UI. The PowerShell cmdlet approach is more flexible and recommended for new projects.

### How the EXE Parses Controls

When you call `Show-PoshWizard` or run a parameter-based script:

1. **PowerShell Module** generates a temporary script with all control metadata
2. **Module launches PoshWizard.exe** with the script path
3. **EXE reads the script** and extracts control definitions from:
   - PowerShell cmdlet calls: `Add-WizardTextBox`, `Add-WizardDropdown`, etc.
   - Parameter attributes: `[WizardTextBox]`, `[WizardDropdown]`, etc.
4. **EXE renders the UI** based on control types and properties
5. **EXE handles user interaction** (validation, dynamic updates, etc.)
6. **EXE returns results** as JSON to the PowerShell module
7. **Module converts JSON** to PowerShell objects and returns to your script

### Deployment: How It All Works Together

When you distribute PoshWizard:

```
PoshWizard/
├── PoshWizard.psd1              # PowerShell Module (defines controls)
├── PoshWizard.psm1              # Module implementation
├── bin/
│   └── PoshWizard.exe           # WPF UI Engine (parses & renders controls)
├── Public/
│   ├── Add-WizardTextBox.ps1    # Control definition functions
│   ├── Add-WizardDropdown.ps1
│   ├── Add-WizardPassword.ps1
│   └── ... (other controls)
└── Examples/
    └── Demo-AllControls.ps1 # Shows all available controls
```

**The Flow:**
1. User imports the module: `Import-Module PoshWizard`
2. User defines controls using cmdlets or attributes
3. User calls `Show-PoshWizard`
4. Module generates a temporary script with control definitions
5. Module launches `PoshWizard.exe` with the script
6. EXE parses the control definitions and renders the UI
7. User interacts with the UI
8. EXE returns results to the module
9. Module returns results to the user's script

**No installation needed.** Everything is bundled in one folder. The EXE automatically finds the module, and the module automatically finds the EXE.

### Control Properties

Each control type has specific properties that the EXE uses to render and validate:

- **Label** - Display text shown to the user
- **Mandatory** - Whether the field must be filled
- **Default** - Initial value
- **Validation** - Rules for acceptable input (regex, range, choices)
- **Width** - UI sizing hints
- **HelpText** - Tooltip or help description

The EXE reads these properties and applies them during rendering and validation.

---

## Control Types Overview

PowerShell cmdlets are the recommended way to define controls. Direct attributes remain fully supported for parameter-based scripts.

| Control Type | PowerShell Cmdlet | Direct Attribute | Purpose |
|--------------|-------------------|-----------------|---------|
| TextBox | `Add-WizardTextBox` | `[WizardTextBox]` | Single-line text input |
| MultiLine | `Add-WizardMultiLine` | `[WizardMultiLine]` | Multi-line text area |
| Password | `Add-WizardPassword` | `[WizardPassword]` | Secure password input |
| Dropdown | `Add-WizardDropdown` | `[WizardDropdown]` | Selection from list |
| ListBox | `Add-WizardListBox` | `[WizardListBox]` | Single/multi-select list |
| Checkbox | `Add-WizardCheckbox` | `[WizardCheckBox]` | True/False toggle |
| Toggle | `Add-WizardToggle` | `[WizardSwitch]` | Modern toggle switch |
| OptionGroup | `Add-WizardOptionGroup` | `[WizardOptionGroup]` | Radio button group |
| Numeric | `Add-WizardNumeric` | `[WizardNumeric]` | Number spinner |
| Date | `Add-WizardDate` | `[WizardDate]` | Date picker |
| FilePath | `Add-WizardFilePath` | `[WizardFilePath]` | File browse dialog |
| FolderPath | `Add-WizardFolderPath` | `[WizardFolderPath]` | Folder browse dialog |
| Card | `Add-WizardCard` | `[WizardCard]` | Information display |

---

## Text Controls

### TextBox (Single-Line)

**Purpose**: Collect short text input (names, servers, descriptions)

**Direct Attribute Syntax**:
```powershell
[WizardStep("Config", 1)]
[WizardParameterDetails(Label='Server Name')]
[WizardTextBox(MaxLength=50, Placeholder='Enter server name...')]
[ValidatePattern('^[A-Z0-9\-]+$')]
[string]$ServerName = "SERVER01"
```

**Features**:
- Optional `MaxLength` limit
- Optional `Placeholder` text
- Validation via regex pattern
- Default values supported

---

### MultiLine (Text Area)

**Purpose**: Collect longer text (descriptions, JSON, scripts)

**Direct Attribute Syntax**:
```powershell
[WizardStep("Config", 1)]
[WizardParameterDetails(Label='Description')]
[WizardMultiLine(Rows=5)]
[string]$Description = "Enter description..."
```

**Features**:
- Adjustable rows (height)
- Scrollable for long content
- Word wrap enabled

---

## Password Controls

### Secure Password Input

**Purpose**: Collect passwords securely (returns `SecureString`)

**Direct Attribute Syntax**:
```powershell
[WizardStep("Security", 1)]
[WizardParameterDetails(Label='Administrator Password')]
[WizardPassword(MinLength=12, ShowRevealButton=$true, ValidationPattern='^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{12,}$')]
[SecureString]$AdminPassword
```

**Features**:
- Returns `SecureString` (encrypted in memory)
- Optional eye icon to reveal password
- Minimum length validation
- Regex pattern validation
- Custom validation messages
- Supports enterprise password policies (NIST, PCI-DSS, etc.)

**Common Password Patterns**:

```powershell
# Minimum 8 characters, at least one letter and one number
'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$'

# Minimum 8 characters, uppercase, lowercase, number
'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$'

# Minimum 8 characters, uppercase, lowercase, number, special char
'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$'

# Minimum 12 characters, very strong (recommended for admin accounts)
'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{12,}$'
```

**How Password Validation Works**:
1. PowerShell: Validation pattern stored in control
2. Script Generation: Pattern passed via `[WizardPassword(ValidationPattern='...')]`
3. C# Launcher: Reads pattern from attribute
4. Validation: C# temporarily converts SecureString to plaintext, validates with regex, disposes plaintext
5. Result: Password validated before script execution

---

## Selection Controls

### Dropdown (ComboBox)

**Purpose**: Select one option from a list

**Direct Attribute Syntax**:
```powershell
[WizardStep("Config", 1)]
[WizardParameterDetails(Label='Environment')]
[WizardDropdown(Choices=@('Development','Staging','Production'))]
[ValidateSet("Development", "Staging", "Production")]
[string]$Environment = "Development"
```

**Features**:
- Static choices via array
- Dynamic choices via script block
- CSV data source support
- Dependency tracking (refresh when parent changes)
- Filtering support
- Default values

---

### ListBox (List Selection)

**Purpose**: Select one or multiple items from a scrollable list

**Direct Attribute Syntax**:
```powershell
[WizardStep("Features", 3)]
[WizardParameterDetails(Label='Select Feature')]
[ValidateSet("Web Server", "Database", "Cache", "Monitoring")]
[WizardListBox()]
[string]$Feature = "Web Server"

[WizardStep("Features", 3)]
[WizardParameterDetails(Label='Select Features')]
[ValidateSet("Web Server", "Database", "Cache", "Monitoring")]
[WizardListBox(MultiSelect=$true)]
[string[]]$Features = @("Web Server", "Database")
```

**Features**:
- Single or multi-select mode
- Scrollable list
- Returns string or string array
- Dynamic data sources supported
- Default selections

---

### OptionGroup (Radio Buttons)

**Purpose**: Mutually exclusive selection (radio buttons)

**Direct Attribute Syntax**:
```powershell
[WizardOptionGroup("Standard", "High Availability", "Disaster Recovery", Orientation='Horizontal')]
[string]$DeploymentType = "Standard"
```

**Features**:
- Radio button visual
- Horizontal or vertical layout
- Mandatory by design (must select one)
- Default value required

---

## Boolean Controls

### Checkbox

**Purpose**: True/False toggle with custom labels

**Direct Attribute Syntax**:
```powershell
[WizardCheckBox(CheckedLabel='Enabled', UncheckedLabel='Disabled')]
[bool]$EnableSSL = $true
```

**Features**:
- Returns boolean
- Custom labels for checked/unchecked states
- Default value supported

---

### Toggle Switch

**Purpose**: Modern On/Off switch (Windows 11 style)

**Direct Attribute Syntax**:
```powershell
[WizardSwitch]
[switch]$EnableBackups
```

**Features**:
- Returns PowerShell `[switch]`
- Modern animated toggle
- Windows 11 styling
- Default is always `$false` for switches

---

## Numeric & Date Controls

### Numeric (Number Spinner)

**Purpose**: Collect numeric input with validation

**Direct Attribute Syntax**:
```powershell
[WizardNumeric(Minimum=1, Maximum=10, Step=1, Format='N0')]
[double]$InstanceCount = 3
```

**Features**:
- Spinner arrows
- Keyboard input
- Min/Max validation
- Step increment
- Format display (N0, C2, P0, etc.)
- Decimal support

---

### Date Picker

**Purpose**: Select dates with calendar popup

**Direct Attribute Syntax**:
```powershell
[WizardDate(Minimum='2025-01-01', Maximum='2025-12-31', Format='yyyy-MM-dd')]
[DateTime]$LaunchDate = '2025-10-13'
```

**Features**:
- Calendar popup
- Min/Max date validation
- Custom format display
- Returns `DateTime`

---

## Path Selection Controls

### FilePath

**Purpose**: Browse and select a file

**Direct Attribute Syntax**:
```powershell
[WizardFilePath(Filter='JSON files (*.json)|*.json|All files (*.*)|*.*', DialogTitle='Select Configuration File')]
[string]$ConfigFile = "C:\Config\app.json"
```

**Features**:
- Browse dialog button
- File type filtering
- Custom dialog title
- Returns full file path

---

### FolderPath

**Purpose**: Browse and select a folder

**Direct Attribute Syntax**:
```powershell
[WizardFolderPath()]
[string]$InstallPath = "C:\Program Files\MyApp"
```

**Features**:
- Folder browse dialog
- Manual path entry
- Returns full folder path

---

## Information Controls

### Card (Info Display)

**Purpose**: Display information, instructions, or warnings

**Direct Attribute Syntax**:
```powershell
[WizardCard("Welcome to Setup", @"
This wizard will guide you through the installation process.

Prerequisites:
- Windows Server 2019 or later
- PowerShell 5.1 or later
- Administrator privileges

Click Next to begin.
"@)]
[string]$InfoCard
```

**Features**:
- Display-only (no input)
- Title and content
- Optional Segoe MDL2 icon
- Supports multi-line content
- Markdown-style formatting

---

## Dynamic Controls

### How Dynamic Controls Work

Dynamic controls refresh their choices based on other parameter values.

**Supported Dynamic Controls**:
- Dropdown
- ListBox
- DropdownFromCsv

**PowerShell Cmdlets - ScriptBlock**:
```powershell
# Parent control
Add-WizardDropdown -Step "Config" -Name "Environment" `
    -Label "Environment" `
    -Choices @("Development", "Staging", "Production")

# Dependent control
Add-WizardDropdown -Step "Config" -Name "Server" `
    -Label "Server" `
    -ScriptBlock {
        # $Environment is available here
        if ($Environment -eq "Production") {
            @("PROD-WEB01", "PROD-WEB02")
        } else {
            @("DEV-WEB01", "STG-WEB01")
        }
    } `
    -DependsOn @("Environment")
```

**PowerShell Cmdlets - CSV** (using Import-Csv):
```powershell
$choices = (Import-Csv -Path ".\databases.csv").DatabaseName
Add-WizardDropdown -Step "Config" -Name "Database" `
    -Label "Database" `
    -Choices $choices `
    -FilterScript { $_.Environment -eq $Environment } `
    -DependsOn @("Environment")
```

**Direct Attribute Syntax (ScriptBlock)**:
```powershell
[WizardStep("Servers", 2)]
[WizardParameterDetails(Label='Server (Dynamic)')]
[WizardDataSource({
    param($Environment)
    if ($Environment -eq "Production") {
        @("PROD-WEB01", "PROD-WEB02")
    } else {
        @("DEV-WEB01", "STG-WEB01")
    }
})]
[string]$Server
```

**Important Notes**:
1. **Sequential Refresh**: Dependent parameters refresh one at a time (v1.4.2+)
2. **Backward Navigation**: Changing parent values refreshes dependent controls
3. **ScriptBlock Context**: Parent parameter values are available as variables
4. **CSV Filtering**: Use `FilterScript` to filter CSV rows based on parent values
5. **PowerShell Cmdlets Only**: ScriptBlock-based dynamic dropdowns only work with PowerShell cmdlets

---

## Validation

### Built-in Validation

All controls support validation through parameters and attributes:

**Required Fields**:
```powershell
# PowerShell Cmdlets
-Mandatory  # Makes field required

# Direct Attribute
[Parameter(Mandatory=$true)]   # Required field
[Parameter(Mandatory=$false)]  # Optional field
```

**Pattern Validation** (TextBox, Password):
```powershell
# PowerShell Cmdlets
-ValidationPattern '^[A-Z0-9]+$'
-ValidationMessage "Must be alphanumeric"

# Direct Attribute (TextBox only)
[ValidatePattern('^[A-Z0-9]+$')]

# Direct Attribute (Password) - v1.4.3+
[WizardPassword(ValidationPattern='^[A-Z0-9]+$')]
```

**Range Validation** (Numeric):
```powershell
# PowerShell Cmdlets
-Minimum 1 -Maximum 100

# Direct Attribute
[WizardNumeric(Minimum=1, Maximum=100)]
```

**Date Range** (Date):
```powershell
# PowerShell Cmdlets
-Minimum (Get-Date) -Maximum (Get-Date).AddMonths(6)

# Direct Attribute
[WizardDate(Minimum='2025-01-01', Maximum='2025-12-31')]
```

**Choice Validation** (Dropdown, ListBox):
```powershell
# PowerShell Cmdlets
-Choices @("Option1", "Option2", "Option3")

# Direct Attribute
[ValidateSet("Option1", "Option2", "Option3")]
```

---

## Control Properties Reference

### Common Properties

All controls support these properties:

| Property | Description | PowerShell Cmdlet Parameter | Direct Attribute |
|----------|-------------|---------------------|------------------|
| Name | Parameter name | `-Name` | Parameter name |
| Label | Display label | `-Label` | `[WizardParameterDetails(Label='...')]` |
| Default | Default value | `-Default` | `= "value"` |
| Mandatory | Required field | `-Mandatory` | `[Parameter(Mandatory=$true)]` |
| Width | Control width | `-Width` | `[WizardParameterDetails(ControlWidth=500)]` |
| HelpText | Tooltip/help | `-HelpText` | Not yet supported |

---

## Best Practices

### 1. Use Mandatory=$true for Required Fields

```powershell
# REQUIRED FIELD - User must provide value
[Parameter(Mandatory=$true)]
[WizardStep("Config", 1)]
[string]$ServerName

# OPTIONAL FIELD - Can be left empty, uses default
[Parameter(Mandatory=$false)]
[WizardStep("Config", 1)]
[string]$Description = "Default description"
```

**Why?** PoshWizard respects PowerShell's `Mandatory` attribute. Required fields (`Mandatory=$true`) are validated before the wizard can complete. The "Next" button will be disabled until all mandatory fields on the current step are filled.

---

### 2. Use ValidationPattern for Passwords, Not ValidatePattern

```powershell
# CORRECT (v1.4.3+)
[WizardPassword(MinLength=12, ValidationPattern='^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).+$')]
[SecureString]$AdminPassword

# WRONG - ValidatePattern doesn't work with SecureString
[ValidatePattern('^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).+$')]
[SecureString]$AdminPassword
```

---

### 3. Order Steps by Number

```powershell
[WizardStep("Welcome", 1)]
[WizardStep("Configuration", 2)]
[WizardStep("Options", 3)]
[WizardStep("Summary", 4)]
```

---

### 4. Use DependsOn for Dynamic Dropdowns

```powershell
Add-WizardDropdown -Name "Region" -Choices @("US", "EU", "APAC")

Add-WizardDropdown -Name "Server" `
    -ScriptBlock { Get-ServersInRegion $Region } `
    -DependsOn @("Region")  # Always specify dependencies
```

---

### 5. Provide Meaningful Labels

```powershell
# GOOD
-Label "Administrator Password"

# BAD
-Label "AdminPwd"
```

---

### 6. PowerShell 5.1 Compatibility - Avoid Unicode Emojis

```powershell
# GOOD - ASCII characters only
[WizardCard(Title="Important Notes", Content="- Item 1\n- Item 2\n- Item 3")]

# BAD - Unicode emojis/glyphs (breaks PowerShell 5.1)
[WizardCard(Title="Important Notes", Content="- Item 1\n- Item 2\n- Item 3")]
```

**Why?** PowerShell 5.1 requires scripts with Unicode characters to be saved as UTF-8 with BOM, which can cause parsing errors. Use ASCII-only characters in executable `.ps1` scripts and reserve emoji usage for Markdown documentation.

---

## Troubleshooting

### Control Not Showing

- **Check**: Is the step defined before adding the control?
- **Check**: Is `-Step` parameter spelled correctly?
- **Fix**: Define step with `Add-WizardStep` first

### Validation Not Working

- **Check**: Is `ValidationPattern` correctly escaped?
- **Check**: For passwords, using `[WizardPassword]` attribute not `[ValidatePattern]`?
- **Fix**: Use single quotes and escape special characters

### Dynamic Dropdown Empty

- **Check**: Is `DependsOn` specified?
- **Check**: Is the script block returning an array?
- **Check**: Are parent parameter values available in script block?
- **Fix**: Add `-DependsOn` and ensure script block returns values

### Mandatory Field Not Enforced

- **Check**: Using `-Mandatory` switch in PowerShell cmdlets?
- **Check**: Using `[Parameter(Mandatory=$true)]` in direct attribute scripts?
- **Fix**: Add the mandatory flag to required fields:
  - PowerShell Cmdlets: `Add-WizardTextBox -Name "ServerName" -Mandatory`
  - Direct Attribute: `[Parameter(Mandatory=$true)]`

---

## Examples

See the `Examples/` folder for comprehensive demonstrations:

- `Demo-AllControls.ps1` - All controls using PowerShell cmdlets
- `Demo-DynamicControls.ps1` - Dynamic dropdowns with dependencies
- `Demo-PasswordValidation.ps1` - Password validation examples
- `Demo-HyperV-CreateVM.ps1` - Real-world VM creation example
- `Demo-Cascading-overlay.ps1` - Progress overlay behavior

---
