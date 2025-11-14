# PoshWizard Cmdlet Reference Guide

**For PowerShell Users**

This guide covers the PowerShell cmdlets for building PoshWizard wizards. Use familiar Verb-Noun functions like `New-PoshWizard`, `Add-WizardStep`, and `Add-WizardTextBox` to define your wizard structure.

**Related Documentation:**
- **CONTROLS_GUIDE.md** - Details on all control types and how they work
- **ARCHITECTURE.md** - How the PowerShell module and EXE work together

---

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Core Workflow](#core-workflow)
- [Wizard Initialization](#wizard-initialization)
- [Branding Configuration](#branding-configuration)
- [Adding Steps](#adding-steps)
- [Control Types](#control-types)
- [Showing the Wizard](#showing-the-wizard)
- [Dynamic Data Sources](#dynamic-data-sources)
- [Validation](#validation)
- [Best Practices](#best-practices)
- [Complete Examples](#complete-examples)

---

## Overview

### Building Wizards with PowerShell Cmdlets

Use standard PowerShell cmdlets (Verb-Noun functions) to build wizards programmatically. If you're comfortable with PowerShell scripting, this approach will feel natural.


---

## Getting Started

### Import the Module

```powershell
$modulePath = Join-Path $PSScriptRoot 'PoshWizard\PoshWizard.psd1'
Import-Module $modulePath -Force
```

### Minimal Example

```powershell
$modulePath = Join-Path $PSScriptRoot 'PoshWizard\PoshWizard.psd1'
Import-Module $modulePath -Force

# Initialize wizard
$wizardParams = @{
    Title = 'Quick Start'
    Description = 'A minimal wizard'
    Theme = 'Auto'
}
New-PoshWizard @wizardParams

# Add a step
$stepParams = @{
    Name = 'Welcome'
    Title = 'Welcome'
    Order = 1
}
Add-WizardStep @stepParams

# Add a control
$textBoxParams = @{
    Step = 'Welcome'
    Name = 'UserName'
    Label = 'Your Name'
    Mandatory = $true
}
Add-WizardTextBox @textBoxParams

# Show the wizard and capture results
$result = Show-PoshWizard
Write-Host "Hello, $($result.UserName)!"
```

---

## Core Workflow

Every wizard follows this pattern:

```powershell
# 1. Initialize the wizard
$wizardParams = @{
    Title = 'My Wizard'
    Description = 'Description'
    Theme = 'Auto'
}
New-PoshWizard @wizardParams

# 2. Configure branding (optional)
$brandingParams = @{
    WindowTitle = 'Custom Title'
    SidebarHeaderText = 'Branding'
}
Set-WizardBranding @brandingParams

# 3. Add steps
$stepParams = @{
    Name = 'Step1'
    Title = 'First Step'
    Order = 1
}
Add-WizardStep @stepParams

# 4. Add controls to steps
$textBoxParams = @{
    Step = 'Step1'
    Name = 'Field1'
    Label = 'Enter value'
}
Add-WizardTextBox @textBoxParams

# 5. Show wizard (with optional live execution)
# Option A: Simple mode - just collect data
$result = Show-PoshWizard

# 6. Post-wizard processing (optional)
if ($result) {
    Write-Host "Wizard completed successfully" -ForegroundColor Green
    # Process results here
}
else {
    Write-Host "Wizard was cancelled" -ForegroundColor Yellow
}

# Option B: Live execution mode - run code during wizard
$scriptBody = {
    Write-Host "Processing configuration..." -ForegroundColor Cyan
    Write-Host "Field1 value: $Field1" -ForegroundColor White
    
    # Your deployment/processing logic here
}
Show-PoshWizard -ScriptBody $scriptBody
# If we reach here, ScriptBody completed successfully
```

### How Show-PoshWizard Works

When you call `Show-PoshWizard`, the wizard:

1. Displays the wizard UI and collects user input
2. User completes all steps and clicks Finish
3. **Optional**: If you provided `ScriptBody`, your code runs inside the wizard session
4. Wizard closes and returns collected data to your script

#### Without ScriptBody

The wizard simply collects data and returns it:

```powershell
# Define wizard
New-PoshWizard -Title 'My Wizard' -Theme 'Auto'
Add-WizardStep -Name 'Config' -Title 'Configuration' -Order 1
Add-WizardTextBox -Step 'Config' -Name 'ServerName' -Label 'Server Name'

# Get results and process them yourself
$result = Show-PoshWizard

if ($result) {
    Write-Host "User entered: $($result.ServerName)"
    # Your business logic here
    Deploy-Server -Name $result.ServerName
}
```

**Use this approach when:**
- You need to perform complex post-processing
- Your logic requires external dependencies
- You want to handle errors gracefully outside the wizard

#### With ScriptBody

Your code runs inside the wizard session before it closes:

```powershell
# Define wizard
New-PoshWizard -Title 'My Wizard' -Theme 'Auto'
Add-WizardStep -Name 'Config' -Title 'Configuration' -Order 1
Add-WizardTextBox -Step 'Config' -Name 'ServerName' -Label 'Server Name'

# Define what happens during wizard execution
$scriptBody = {
    Write-Host "Deploying server: $ServerName" -ForegroundColor Cyan
    # Your business logic here - has access to all wizard parameters
    Deploy-Server -Name $ServerName
    Write-Host "Deployment complete!" -ForegroundColor Green
}

# Show wizard with ScriptBody
Show-PoshWizard -ScriptBody $scriptBody
# If we reach here, ScriptBody completed successfully
```

**Use this approach when:**
- You want to show progress/results to the user in real-time
- Your operation completes quickly
- You want a unified wizard + execution experience

**Key difference:** Your code runs inside the wizard session with access to all wizard parameters as variables. Output displays in real-time in the execution console before the wizard closes.

---

## Wizard Initialization

### New-PoshWizard

Creates a new wizard instance. Call this once at the start of your script.

**Parameters:**
- `Title` - Wizard title shown in the UI
- `Description` - Brief description of the wizard's purpose
- `Theme` - UI theme: `'Auto'`, `'Light'`, or `'Dark'`
- `Icon` - Path to window icon image (`.png`, `.ico`)

**Example with splatting:**

```powershell
$wizardParams = @{
    Title = 'Server Configuration Wizard'
    Description = 'Configure server settings and deployment options'
    Theme = 'Auto'
    Icon = $scriptIconPath
}
New-PoshWizard @wizardParams
```

---

## Branding Configuration

### Set-WizardBranding

Customizes the wizard's appearance and branding.

**Parameters:**
- `WindowTitle` - Custom window title (overrides wizard title)
- `SidebarHeaderText` - Text shown in sidebar header
- `SidebarHeaderIcon` - Path to sidebar icon image
- `SidebarHeaderIconOrientation` - Icon position: `'Left'`, `'Right'`, `'Top'`, `'Bottom'`

**Example:**

```powershell
$brandingParams = @{
    WindowTitle = 'Acme Corp - Server Setup'
    SidebarHeaderText = 'Server Deployment'
    SidebarHeaderIcon = $sidebarIconPath
    SidebarHeaderIconOrientation = 'Top'
}
Set-WizardBranding @brandingParams
```

**Asset validation pattern:**

```powershell
$scriptIconPath = Join-Path $PSScriptRoot 'browser.png'
$sidebarIconPath = Join-Path $PSScriptRoot 'logo.png'

foreach ($assetPath in @($scriptIconPath, $sidebarIconPath)) {
    if (-not (Test-Path $assetPath)) {
        throw "Branding asset not found: $assetPath"
    }
}

$brandingParams = @{
    WindowTitle = 'My App'
    SidebarHeaderIcon = $sidebarIconPath
    SidebarHeaderIconOrientation = 'Top'
}
Set-WizardBranding @brandingParams
```

---

## Adding Steps

### Add-WizardStep

Creates a new step (page) in the wizard.

**Parameters:**
- `Name` - Unique identifier for the step
- `Title` - Display title shown in sidebar
- `Order` - Numeric order (1, 2, 3...)
- `Icon` - Icon glyph from Segoe MDL2 Assets font (e.g., `'&#xE713;'`)
- `Description` - Brief description shown in sidebar

**Example:**

```powershell
$stepParams = @{
    Name = 'ServerConfig'
    Title = 'Server Configuration'
    Order = 1
    Icon = '&#xE950;'
    Description = 'Configure server name and location'
}
Add-WizardStep @stepParams
```

**Multiple steps:**

```powershell
$step1Params = @{
    Name = 'Welcome'
    Title = 'Welcome'
    Order = 1
    Icon = '&#xE8BC;'
}
Add-WizardStep @step1Params

$step2Params = @{
    Name = 'Config'
    Title = 'Configuration'
    Order = 2
    Icon = '&#xE713;'
}
Add-WizardStep @step2Params

$step3Params = @{
    Name = 'Review'
    Title = 'Review'
    Order = 3
    Icon = '&#xE73E;'
}
Add-WizardStep @step3Params
```

---

## Control Types

### Text Input Controls

#### Add-WizardTextBox

Single-line text input.

```powershell
$textBoxParams = @{
    Step = 'Config'
    Name = 'ServerName'
    Label = 'Server Name'
    Default = 'SERVER01'
    Mandatory = $true
}
Add-WizardTextBox @textBoxParams
```

**With validation:**

```powershell
$textBoxParams = @{
    Step = 'Config'
    Name = 'ServerName'
    Label = 'Server Name'
    ValidationPattern = '^[A-Z][A-Z0-9-]{0,14}$'
    ValidationMessage = 'Must start with letter, max 15 chars, alphanumeric and hyphens only'
    Mandatory = $true
}
Add-WizardTextBox @textBoxParams
```

#### Add-WizardMultiLine

Multi-line text input.

```powershell
$multiLineParams = @{
    Step = 'Config'
    Name = 'Description'
    Label = 'Server Description'
    Rows = 5
    Default = 'Production web server'
}
Add-WizardMultiLine @multiLineParams
```

#### Add-WizardPassword

Password input with optional reveal button.

```powershell
$passwordParams = @{
    Step = 'Credentials'
    Name = 'AdminPassword'
    Label = 'Administrator Password'
    MinLength = 12
    Mandatory = $true
}
Add-WizardPassword @passwordParams
```

**With validation:**

```powershell
$passwordParams = @{
    Step = 'Credentials'
    Name = 'AdminPassword'
    Label = 'Administrator Password'
    ValidationPattern = '^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&]).{12,}$'
    ValidationMessage = 'Must be 12+ chars with uppercase, lowercase, number, and special character'
    Mandatory = $true
}
Add-WizardPassword @passwordParams
```

### Selection Controls

#### Add-WizardDropdown

Dropdown (ComboBox) for single selection.

```powershell
$dropdownParams = @{
    Step = 'Config'
    Name = 'Environment'
    Label = 'Environment'
    Choices = @('Development', 'Staging', 'Production')
    Default = 'Development'
    Mandatory = $true
}
Add-WizardDropdown @dropdownParams
```

**CSV-backed dropdown:**

```powershell
$serverChoices = (Import-Csv -Path $serversCsvPath).ServerName

$dropdownParams = @{
    Step = 'Config'
    Name = 'Server'
    Label = 'Target Server'
    Choices = $serverChoices
    Default = $serverChoices[0]
    Mandatory = $true
}
Add-WizardDropdown @dropdownParams
```

#### Add-WizardListBox

List box for single or multi-selection.

```powershell
# Multi-select
$listBoxParams = @{
    Step = 'Features'
    Name = 'Components'
    Label = 'Components to Install'
    Choices = @('WebServer', 'Database', 'Cache', 'LoadBalancer')
    Default = @('WebServer', 'Database')
    MultiSelect = $true
    Height = 150
}
Add-WizardListBox @listBoxParams
```

#### Add-WizardOptionGroup

Radio button group for single selection.

```powershell
$optionGroupParams = @{
    Step = 'Config'
    Name = 'InstallType'
    Label = 'Installation Type'
    Options = @('Minimal', 'Standard', 'Full')
    Default = 'Standard'
    Orientation = 'Horizontal'
    Mandatory = $true
}
Add-WizardOptionGroup @optionGroupParams
```

### Boolean Controls

#### Add-WizardCheckbox

Single checkbox for yes/no choices.

```powershell
$checkboxParams = @{
    Step = 'Options'
    Name = 'EnableSSL'
    Label = 'Enable SSL/TLS'
    Default = $true
}
Add-WizardCheckbox @checkboxParams
```

#### Add-WizardToggle

Toggle switch (modern alternative to checkbox).

```powershell
$toggleParams = @{
    Step = 'Options'
    Name = 'AutoStart'
    Label = 'Start service automatically'
    Default = $false
}
Add-WizardToggle @toggleParams
```

### Numeric Controls

#### Add-WizardNumeric

Numeric spinner with min/max constraints.

```powershell
$numericParams = @{
    Step = 'Resources'
    Name = 'MemoryGB'
    Label = 'Memory Allocation (GB)'
    Min = 1
    Max = 128
    Default = 8
    Mandatory = $true
}
Add-WizardNumeric @numericParams
```

### Date/Time Controls

#### Add-WizardDate

Date selection control.

```powershell
$datePickerParams = @{
    Step = 'Schedule'
    Name = 'DeploymentDate'
    Label = 'Deployment Date'
    Default = (Get-Date).AddDays(7)
    Mandatory = $true
}
Add-WizardDate @datePickerParams
```

### Path Controls

#### Add-WizardFilePath

File path selector with browse button.

```powershell
$filePathParams = @{
    Step = 'Config'
    Name = 'ConfigFile'
    Label = 'Configuration File'
    Filter = 'JSON Files (*.json)|*.json|All Files (*.*)|*.*'
    Mandatory = $true
}
Add-WizardFilePath @filePathParams
```

#### Add-WizardFolderPath

Folder path selector with browse button.

```powershell
$folderPathParams = @{
    Step = 'Config'
    Name = 'InstallPath'
    Label = 'Installation Directory'
    Default = 'C:\Program Files\MyApp'
    Mandatory = $true
}
Add-WizardFolderPath @folderPathParams
```

### Informational Controls

#### Add-WizardCard

Display-only card with title and content.

```powershell
$cardParams = @{
    Step = 'Welcome'
    Name = 'WelcomeCard'
    Title = 'Welcome to Server Setup'
    Content = @'
This wizard will configure your server deployment.

Key Steps:
• Server identification and naming
• Resource allocation (CPU, memory)
• Network configuration
• Feature selection

Click Next to begin.
'@
}
Add-WizardCard @cardParams
```

---

## Showing the Wizard

### Show-PoshWizard

Displays the wizard and returns user input. This cmdlet has two modes:

**Simple mode** - Returns results immediately:

```powershell
$result = Show-PoshWizard

if ($result) {
    Write-Host "User Name: $($result.UserName)"
    Write-Host "Environment: $($result.Environment)"
}
```

**ScriptBody mode** - Executes a scriptblock after wizard completion:

```powershell
$scriptBody = {
    Write-Host "`nConfiguration Summary:" -ForegroundColor Cyan
    Write-Host "  Server Name: $ServerName" -ForegroundColor White
    Write-Host "  Environment: $Environment" -ForegroundColor White
    Write-Host "  Features: $($Features -join ', ')" -ForegroundColor White
    
    # Perform deployment logic here
    Write-Host "`nDeploying configuration..." -ForegroundColor Yellow
}

Show-PoshWizard -ScriptBody $scriptBody
# If we reach here, ScriptBody completed successfully
Write-Host "Wizard session ended." -ForegroundColor Green
```

**Key points:**
- The scriptblock has access to all wizard parameters as variables
- ScriptBody executes only if user clicks Finish (not Cancel)

- If ScriptBody needs to signal failure, use `throw` to terminate execution

**Complete example with ScriptBody:**

```powershell
# Define wizard controls
$wizardParams = @{
    Title = 'Server Setup'
    Description = 'Configure server deployment'
    Theme = 'Auto'
}
New-PoshWizard @wizardParams

$stepParams = @{
    Name = 'Config'
    Title = 'Configuration'
    Order = 1
}
Add-WizardStep @stepParams

$serverNameParams = @{
    Step = 'Config'
    Name = 'ServerName'
    Label = 'Server Name'
    Mandatory = $true
}
Add-WizardTextBox @serverNameParams

$envParams = @{
    Step = 'Config'
    Name = 'Environment'
    Label = 'Environment'
    Choices = @('Dev', 'Prod')
    Mandatory = $true
}
Add-WizardDropdown @envParams

# Define execution script
$scriptBody = {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Deployment Configuration" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Server Name : $ServerName" -ForegroundColor White
    Write-Host "Environment : $Environment" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Deploying to $ServerName..." -ForegroundColor Yellow
    
    # Your deployment logic here
    Start-Sleep -Seconds 2
    
    Write-Host "Deployment complete!" -ForegroundColor Green
}

# Launch wizard with script
Show-PoshWizard -ScriptBody $scriptBody
# If we reach here, ScriptBody completed successfully
Write-Host "`nWizard session ended." -ForegroundColor Green
```

---

## Dynamic Data Sources

Controls can have dynamic data sources that depend on other parameter values. Use scriptblocks to generate choices based on user selections.

**Dropdown with dynamic choices:**

```powershell
# Parent control
$envParams = @{
    Step = 'Config'
    Name = 'Environment'
    Label = 'Environment'
    Choices = @('Development', 'Staging', 'Production')
    Mandatory = $true
}
Add-WizardDropdown @envParams

# Child control with dynamic data source
$regionParams = @{
    Step = 'Config'
    Name = 'Region'
    Label = 'Region'
    ScriptBlock = {
        param($Environment)
        
        switch ($Environment) {
            'Development' { @('US-Dev-1', 'EU-Dev-1') }
            'Staging'     { @('US-Stage-1', 'US-Stage-2', 'EU-Stage-1') }
            'Production'  { @('US-East-1', 'US-West-2', 'EU-Central-1', 'APAC-Singapore') }
            default       { @('US-East-1') }
        }
    }
}
Add-WizardDropdown @regionParams
```

### Understanding DependsOn: Optional vs Auto-Detected

The `DependsOn` parameter is **OPTIONAL** when using `ScriptBlock` for dynamic data. The module can automatically detect dependencies from your ScriptBlock's `param()` declarations.
    Name = 'Server'
    Label = 'Target Server'
    ScriptBlock = {
        param($Environment, $Region)
        
        $envPrefix = switch ($Environment) {
            'Development' { 'DEV' }
            'Staging'     { 'STG' }
            'Production'  { 'PROD' }
        }
        
        $regionCode = $Region -replace '-', ''
        
        $servers = @()
        foreach ($type in @('WEB', 'APP', 'DB')) {
            1..2 | ForEach-Object {
                $servers += "$envPrefix-$type-$regionCode-$($_.ToString('00'))"
            }
        }
        
        $servers
    }
}
Add-WizardDropdown @serverParams
```

### Understanding DependsOn: Optional vs Auto-Detected

The `DependsOn` parameter is **OPTIONAL** when using `ScriptBlock` for dynamic data. The module can automatically detect dependencies from your ScriptBlock's `param()` declarations.

#### Method 1: Auto-Detection (Recommended)

When you omit `DependsOn`, dependencies are automatically detected:

```powershell
$regionParams = @{
    Step = 'Config'
    Name = 'Region'
    ScriptBlock = {
        param($Environment)  # Parameter name matches a wizard control
        switch ($Environment) {
            'Dev'  { @('US-Dev', 'EU-Dev') }
            'Prod' { @('US-Prod', 'EU-Prod') }
        }
    }
    # DependsOn NOT specified - auto-detected from param($Environment)
}
Add-WizardDropdown @regionParams
```

**How it works:**
- Module scans `ScriptBlock`'s `param()` declarations
- Finds parameter name `$Environment`
- Automatically links to wizard control named `'Environment'`
- Control recalculates when `Environment` changes

#### Method 2: Explicit Dependencies

Specify `DependsOn` when you need to:
- Override auto-detection
- Map different parameter names to control names
- Make dependencies more explicit for documentation

```powershell
$regionParams = @{
    ScriptBlock = {
        param($Env)  # Parameter name differs from control name
        switch ($Env) { ... }
    }
    DependsOn = @('Environment')  # Explicit mapping required
}
Add-WizardDropdown @regionParams
```

#### Multi-Level Dependencies

Both methods work with multiple dependencies:

```powershell
# Auto-detected (param names match control names)
$serverParams = @{
    ScriptBlock = {
        param($Environment, $Region)  # Both auto-detected
        # Generate servers based on both params
        "$Environment-$Region-Server01"
    }
}

# Explicit (useful for clarity or non-matching names)
$serverParams = @{
    ScriptBlock = {
        param($Environment, $Region)
        "$Environment-$Region-Server01"
    }
    DependsOn = @('Environment', 'Region')  # Order matches param() order
}
```

**Parameter Order Important:** When using multiple dependencies, ensure `param()` order matches `DependsOn` array order.

#### Decision Guide

| Scenario | Use Auto-Detection | Use Explicit DependsOn |
|----------|-------------------|------------------------|
| Param names match control names | ✅ Recommended | Optional (for clarity) |
| Simple single dependency | ✅ Cleaner code | Optional |
| Param names differ from controls | ❌ Won't work | ✅ Required |
| Complex multi-level cascades | ✅ Simplifies code | ✅ Documents flow |
| Team prefers explicit code | Optional | ✅ More readable |

---

## Validation

### Pattern Validation

Use regex patterns for text controls:

```powershell
$emailParams = @{
    Step = 'Config'
    Name = 'Email'
    Label = 'Email Address'
    ValidationPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    ValidationMessage = 'Please enter a valid email address'
    Mandatory = $true
}
Add-WizardTextBox @emailParams
```

### Range Validation

Numeric controls support min/max:

```powershell
$portParams = @{
    Step = 'Config'
    Name = 'Port'
    Label = 'Port Number'
    Min = 1024
    Max = 65535
    Default = 8080
}
Add-WizardNumeric @portParams
```

### Custom Validation

Use scriptblocks for complex validation:

```powershell
$passwordParams = @{
    Step = 'Security'
    Name = 'CustomPassword'
    Label = 'Custom Policy Password'
    ValidationScript = {
        param($InputObject)
        $value = [string]$InputObject
        
        if ($value.Length -lt 8) {
            return 'Password must be at least 8 characters'
        }
        
        if ($value -notmatch '[A-Z]') {
            return 'Password must contain uppercase letter'
        }
        
        if ($value -notmatch '[a-z]') {
            return 'Password must contain lowercase letter'
        }
        
        if ($value -notmatch '\d') {
            return 'Password must contain number'
        }
        
        return $true
    }
    Mandatory = $true
}
Add-WizardPassword @passwordParams
```

---

## Loading Dropdown Choices from CSV Files

Use `Import-Csv` with `Add-WizardDropdown` to load dropdown choices from CSV files.

### Basic CSV Loading

**Simple column extraction:**

```powershell
# Load single column from CSV
$csvPath = Join-Path $PSScriptRoot 'data\applications.csv'
$choices = (Import-Csv -Path $csvPath).AppName

$applicationParams = @{
    Step = 'Config'
    Name = 'Application'
    Label = 'Select Application'
    Choices = $choices
    Mandatory = $true
}
Add-WizardDropdown @applicationParams
```

### Advanced CSV Processing

**With filtering and transformation:**

```powershell
# Load, filter, and format CSV data
$csvPath = Join-Path $PSScriptRoot 'data\servers.csv'
$servers = Import-Csv -Path $csvPath |
    Where-Object { $_.Status -eq 'Active' } |
    ForEach-Object { "$($_.ServerName) - $($_.Location)" } |
    Sort-Object

$serverParams = @{
    Step = 'Config'
    Name = 'Server'
    Label = 'Select Server'
    Choices = $servers
    Mandatory = $true
}
Add-WizardDropdown @serverParams
```

### Dynamic CSV Loading with Dependencies

**CSV data filtered by another control:**

```powershell
$csvPath = Join-Path $PSScriptRoot 'data\databases.csv'

$dbParams = @{
    Step = 'Database'
    Name = 'TargetDatabase'
    Label = 'Database'
    ScriptBlock = {
        param($Environment)
        
        # Load and filter based on environment
        Import-Csv -Path $csvPath |
            Where-Object { $_.Environment -eq $Environment } |
            Select-Object -ExpandProperty DatabaseName
    }
    # DependsOn is auto-detected from param($Environment)
    Mandatory = $true
}
Add-WizardDropdown @dbParams
```

### Use Cases

**When to use CSV loading:**
- Active Directory queries with filtering
- CSV files with status columns (active/inactive)
- Data requiring transformation or calculation
- Multi-column formatting (e.g., "Name (Location)")
- Dynamic filtering based on other wizard selections

### Best Practice: Validate CSV Path

Always verify CSV files exist before using them:

```powershell
$csvPath = Join-Path $PSScriptRoot 'data\servers.csv'

if (-not (Test-Path $csvPath)) {
    throw "CSV file not found: $csvPath"
}

$choices = (Import-Csv -Path $csvPath).ServerName
Add-WizardDropdown -Step 'Config' -Name 'Server' -Choices $choices
```

---

> **Note**: `Add-WizardDropdownFromCsv` is deprecated. The `Import-Csv` approach shown above provides the same functionality with more flexibility.

---

## Best Practices

### 1. Use Hashtable Splatting 

Always use hashtable splatting for clean, readable code:

```powershell
# Good - Clean hashtable splatting
$wizardParams = @{
    Title = 'My Wizard'
    Description = 'A comprehensive wizard'
    Theme = 'Auto'
    Icon = $scriptIconPath
}
New-PoshWizard @wizardParams
```

### 2. Validate Assets Early

Check file paths before using them:

```powershell
$scriptIconPath = Join-Path $PSScriptRoot 'browser.png'
$sidebarIconPath = Join-Path $PSScriptRoot 'logo.png'

foreach ($assetPath in @($scriptIconPath, $sidebarIconPath)) {
    if (-not (Test-Path $assetPath)) {
        throw "Branding asset not found: $assetPath"
    }
}

$wizardParams = @{
    Title = 'My Wizard'
    Icon = $scriptIconPath
}
New-PoshWizard @wizardParams
```

### 3. Group Related Controls by Step

Keep step configuration together:

```powershell
# Step 1: Welcome
$step1Params = @{
    Name = 'Welcome'
    Title = 'Welcome'
    Order = 1
    Icon = '&#xE8BC;'
}
Add-WizardStep @step1Params

$welcomeCardParams = @{
    Step = 'Welcome'
    Name = 'WelcomeCard'
    Title = 'Welcome'
    Content = 'Welcome message...'
}
Add-WizardCard @welcomeCardParams

# Step 2: Configuration
$step2Params = @{
    Name = 'Config'
    Title = 'Configuration'
    Order = 2
    Icon = '&#xE713;'
}
Add-WizardStep @step2Params

$serverNameParams = @{
    Step = 'Config'
    Name = 'ServerName'
    Label = 'Server Name'
    Mandatory = $true
}
Add-WizardTextBox @serverNameParams
```

### 4. Use Meaningful Names

Choose descriptive names for steps and controls:

```powershell
# Good
$dnsParams = @{
    Step = 'NetworkConfig'
    Name = 'PrimaryDNSServer'
    Label = 'Primary DNS Server'
}
Add-WizardTextBox @dnsParams

# Avoid
$textParams = @{
    Step = 'Step1'
    Name = 'Field1'
    Label = 'DNS'
}
Add-WizardTextBox @textParams
```

### 5. Handle Results Safely

Check for null/empty results:

```powershell
$result = Show-PoshWizard

if (-not $result) {
    Write-Warning "Wizard was cancelled"
    exit 0
}

if ([string]::IsNullOrWhiteSpace($result.ServerName)) {
    throw "Server name is required"
}

Write-Host "Deploying to: $($result.ServerName)"
```

### 6. PowerShell 5.1 Compatibility

Avoid Unicode emojis and special glyphs in your `.ps1` wizard scripts:

```powershell
# Good - ASCII characters only
$cardParams = @{
    Step = 'Welcome'
    Name = 'InfoCard'
    Title = 'Important Information'
    Content = @'
- Requirement 1
- Requirement 2
- Requirement 3
'@
}
Add-WizardCard @cardParams

# Avoid - Unicode emojis/glyphs (breaks PowerShell 5.1)
$cardParams = @{
    Step = 'Welcome'
    Name = 'InfoCard'
    Title = '💡 Important Information'  # ❌ Don't use emojis
    Content = @'
• Requirement 1  # ❌ Don't use Unicode bullets
• Requirement 2
• Requirement 3
'@
}
Add-WizardCard @cardParams
```

**Why?** PowerShell 5.1 requires scripts with Unicode characters to be saved as UTF-8 with BOM, which can cause parsing errors. Powershell 7 is able to handle Unicode characters in scripts. Use ASCII-only characters in executable scripts and reserve emojis for Markdown documentation.

---

## Common Pitfalls and Solutions

This section covers frequent mistakes and how to avoid them.

### 1. Dynamic Dropdown Not Updating When Parent Changes

**Symptom:** Changed parent control value but dependent dropdown didn't refresh with new choices.

**Cause:** ScriptBlock parameter name doesn't match the control name (when relying on auto-detection).

**Solution:**

```powershell
# WRONG - Param name doesn't match control name
$regionParams = @{
    ScriptBlock = {
        param($Env)  # Looking for control named 'Env' (doesn't exist)
        switch ($Env) { ... }
    }
    # No DependsOn specified, auto-detection fails
}

# CORRECT Option 1 - Match param name to control name
$regionParams = @{
    ScriptBlock = {
        param($TargetEnvironment)  # Matches control name exactly
        switch ($TargetEnvironment) { ... }
    }
    # Auto-detection works
}

# CORRECT Option 2 - Use explicit DependsOn
$regionParams = @{
    ScriptBlock = {
        param($Env)  # Can use any param name
        switch ($Env) { ... }
    }
    DependsOn = @('TargetEnvironment')  # Explicit mapping
}
```

### 2. Control Doesn't Appear on Step

**Symptom:** Added control but it's not visible in the wizard UI.

**Cause:** Step name mismatch between `Add-WizardStep` and control's `-Step` parameter.

**Solution:**

```powershell
# Step definition
Add-WizardStep -Name 'Configuration' -Title 'Config' -Order 1

# WRONG - Step name doesn't match (case-sensitive)
Add-WizardTextBox -Step 'Config' -Name 'Server' -Label 'Server'

# CORRECT - Step name must match exactly
Add-WizardTextBox -Step 'Configuration' -Name 'Server' -Label 'Server'
```

**Tip:** Use constants for step names to avoid typos:

```powershell
$STEP_CONFIG = 'Configuration'
Add-WizardStep -Name $STEP_CONFIG -Title 'Config' -Order 1
Add-WizardTextBox -Step $STEP_CONFIG -Name 'Server' -Label 'Server'
```

### 3. Validation Pattern Not Working

**Symptom:** Validation message doesn't appear for invalid input.

**Cause:** Regex pattern has unescaped special characters or wrong syntax.

**Solution:**

```powershell
# WRONG - Unescaped dots match any character
Add-WizardTextBox -Step 'Config' -Name 'Domain' -Label 'Domain' `
    -ValidationPattern '^server.example.com$'

# CORRECT - Escape dots for literal match
Add-WizardTextBox -Step 'Config' -Name 'Domain' -Label 'Domain' `
    -ValidationPattern '^server\.example\.com$'

# Test your regex first in PowerShell:
'server.example.com' -match '^server\.example\.com$'  # Should return True
'serverXexampleXcom' -match '^server\.example\.com$'  # Should return False
```

### 4. CSV Path Not Found

**Symptom:** Error: "CSV data file not found: <path>"

**Cause:** Relative path doesn't resolve correctly from different execution contexts.

**Solution:**

```powershell
# WRONG - Assumes current directory
$csvPath = 'data\servers.csv'

# CORRECT - Use $PSScriptRoot for portability
$csvPath = Join-Path $PSScriptRoot 'data\servers.csv'

# Always validate before use
if (-not (Test-Path $csvPath)) {
    throw "CSV file not found: $csvPath"
}
```

### 5. ScriptBody Variables Not Accessible

**Symptom:** Error in ScriptBody: "Cannot find variable $ParameterName"

**Cause:** PowerShell variables are case-sensitive. You must use the exact case from the control's `-Name` parameter.

**Solution:**

```powershell
# Control definition - Name parameter defines the variable name
Add-WizardTextBox -Step 'Config' -Name 'ServerName' -Label 'Server'

# WRONG - Case doesn't match the -Name parameter
$scriptBody = {
    Write-Host "Server: $servername"  # Error: variable not found (lowercase 's')
}

# CORRECT - Match exact case from -Name parameter
$scriptBody = {
    Write-Host "Server: $ServerName"  # Works (capital 'S' and 'N')
}

# BEST PRACTICE - Use consistent naming conventions
# Define controls with PascalCase names
Add-WizardTextBox -Step 'Config' -Name 'ProjectName' -Label 'Project'
Add-WizardTextBox -Step 'Config' -Name 'AdminPassword' -Label 'Password'
Add-WizardDropdown -Step 'Config' -Name 'DeploymentRegion' -Choices @('US-East', 'US-West')

# Use the same case in ScriptBody
$scriptBody = {
    Write-Host "Project: $ProjectName"
    Write-Host "Region: $DeploymentRegion"
}
```

**Tip:** Use PascalCase for all control names to make them obvious as variables in your ScriptBody.

### 6. Mandatory Validation Not Triggering

**Symptom:** User can proceed with empty required field.

**Cause:** Forgot to add `-Mandatory` switch or used `$true` instead of switch syntax.

**Solution:**

```powershell
# WRONG - Not marked as mandatory
Add-WizardTextBox -Step 'Config' -Name 'Server' -Label 'Server'

# WRONG - Using $true with direct parameters (doesn't work)
Add-WizardTextBox -Step 'Config' -Name 'Server' -Label 'Server' -Mandatory $true

# CORRECT - Use switch parameter (no value)
Add-WizardTextBox -Step 'Config' -Name 'Server' -Label 'Server' -Mandatory

# CORRECT - In hashtable, $true works
$params = @{
    Step = 'Config'
    Name = 'Server'
    Label = 'Server'
    Mandatory = $true  # In hashtables, $true is correct
}
Add-WizardTextBox @params
```

### 7. Multi-Select ListBox Returns Single Value

**Symptom:** Selected multiple items but only get one in results.

**Cause:** Forgot `-MultiSelect` switch.

**Solution:**

```powershell
# WRONG - Single-select by default
Add-WizardListBox -Step 'Features' -Name 'Components' -Choices $items

# CORRECT - Enable multi-select
Add-WizardListBox -Step 'Features' -Name 'Components' -Choices $items -MultiSelect

# Access results as array:
$result = Show-PoshWizard
$result.Components | ForEach-Object {
    Write-Host "Selected: $_"
}
```

### 8. Multiple Dependencies Not Updating Correctly

**Symptom:** Control with multiple dependencies only updates when one parent changes.

**Cause:** Parameter order in `param()` doesn't match `DependsOn` array order.

**Solution:**

```powershell
# WRONG - Order mismatch
$params = @{
    ScriptBlock = {
        param($Region, $Environment)  # Region first
        # ...
    }
    DependsOn = @('Environment', 'Region')  # Environment first - MISMATCH
}

# CORRECT - Orders match
$params = @{
    ScriptBlock = {
        param($Environment, $Region)  # Same order
        # ...
    }
    DependsOn = @('Environment', 'Region')  # Same order
}
```

---

## Complete Examples

### Example 1: Simple Configuration Wizard

```powershell
$modulePath = Join-Path $PSScriptRoot 'PoshWizard\PoshWizard.psd1'
Import-Module $modulePath -Force

# Initialize
$wizardParams = @{
    Title = 'Application Setup'
    Description = 'Configure application settings'
    Theme = 'Auto'
}
New-PoshWizard @wizardParams

# Step 1: Welcome
$step1Params = @{
    Name = 'Welcome'
    Title = 'Welcome'
    Order = 1
    Icon = '&#xE8BC;'
}
Add-WizardStep @step1Params

$welcomeCardParams = @{
    Step = 'Welcome'
    Name = 'WelcomeCard'
    Title = 'Welcome to Setup'
    Content = 'This wizard will configure your application.'
}
Add-WizardCard @welcomeCardParams

# Step 2: Configuration
$step2Params = @{
    Name = 'Config'
    Title = 'Configuration'
    Order = 2
    Icon = '&#xE713;'
}
Add-WizardStep @step2Params

$appNameParams = @{
    Step = 'Config'
    Name = 'AppName'
    Label = 'Application Name'
    Default = 'MyApp'
    Mandatory = $true
}
Add-WizardTextBox @appNameParams

$envParams = @{
    Step = 'Config'
    Name = 'Environment'
    Label = 'Environment'
    Choices = @('Development', 'Production')
    Default = 'Development'
    Mandatory = $true
}
Add-WizardDropdown @envParams

$loggingParams = @{
    Step = 'Config'
    Name = 'EnableLogging'
    Label = 'Enable Logging'
    Default = $true
}
Add-WizardCheckbox @loggingParams

# Show wizard
$result = Show-PoshWizard

if ($result) {
    Write-Host "Configuration complete!" -ForegroundColor Green
    Write-Host "App Name: $($result.AppName)"
    Write-Host "Environment: $($result.Environment)"
    Write-Host "Logging: $($result.EnableLogging)"
}
```

### Example 2: Dynamic Cascading Wizard

```powershell
$modulePath = Join-Path $PSScriptRoot 'PoshWizard\PoshWizard.psd1'
Import-Module $modulePath -Force

# Initialize
$wizardParams = @{
    Title = 'Server Deployment'
    Description = 'Deploy to environment'
    Theme = 'Auto'
}
New-PoshWizard @wizardParams

# Branding
$brandingParams = @{
    WindowTitle = 'Acme Corp - Server Deployment'
    SidebarHeaderText = 'Deployment Wizard'
    SidebarHeaderIconOrientation = 'Top'
}
Set-WizardBranding @brandingParams

# Step 1: Environment Selection
$step1Params = @{
    Name = 'Environment'
    Title = 'Environment'
    Order = 1
    Icon = '&#xE81E;'
}
Add-WizardStep @step1Params

$envParams = @{
    Step = 'Environment'
    Name = 'TargetEnvironment'
    Label = 'Target Environment'
    Choices = @('Development', 'Staging', 'Production')
    Mandatory = $true
}
Add-WizardDropdown @envParams

# Step 2: Region (depends on Environment)
$step2Params = @{
    Name = 'Region'
    Title = 'Region'
    Order = 2
    Icon = '&#xE909;'
}
Add-WizardStep @step2Params

$regionParams = @{
    Step = 'Region'
    Name = 'DeploymentRegion'
    Label = 'Deployment Region'
    ScriptBlock = {
        param($TargetEnvironment)
        
        switch ($TargetEnvironment) {
            'Development' { @('US-Dev-1', 'EU-Dev-1') }
            'Staging'     { @('US-Stage-1', 'EU-Stage-1') }
            'Production'  { @('US-East-1', 'US-West-2', 'EU-Central-1', 'APAC-Singapore') }
            default       { @('US-East-1') }
        }
    }
}
Add-WizardDropdown @regionParams

# Step 3: Server (depends on Environment AND Region)
$step3Params = @{
    Name = 'Server'
    Title = 'Server'
    Order = 3
    Icon = '&#xE950;'
}
Add-WizardStep @step3Params

$serverParams = @{
    Step = 'Server'
    Name = 'TargetServer'
    Label = 'Target Server'
    ScriptBlock = {
        param($TargetEnvironment, $DeploymentRegion)
        
        $envPrefix = switch ($TargetEnvironment) {
            'Development' { 'DEV' }
            'Staging'     { 'STG' }
            'Production'  { 'PROD' }
        }
        
        $regionCode = $DeploymentRegion -replace '-', ''
        
        $servers = @()
        foreach ($type in @('WEB', 'APP', 'DB')) {
            1..2 | ForEach-Object {
                $servers += "$envPrefix-$type-$regionCode-$($_.ToString('00'))"
            }
        }
        
        $servers
    }
}
Add-WizardDropdown @serverParams

# Show wizard
$result = Show-PoshWizard

if ($result) {
    Write-Host "`nDeployment Configuration:" -ForegroundColor Cyan
    Write-Host "  Environment: $($result.TargetEnvironment)" -ForegroundColor White
    Write-Host "  Region:      $($result.DeploymentRegion)" -ForegroundColor White
    Write-Host "  Server:      $($result.TargetServer)" -ForegroundColor White
}
```

### Example 3: Validation-Heavy Wizard

```powershell
Import-Module "$PSScriptRoot\PoshWizard\PoshWizard.psd1" -Force

New-PoshWizard -Title 'User Registration' -Description 'Create new user account' -Theme 'Auto'

# Step: User Information
Add-WizardStep -Name 'UserInfo' -Title 'User Information' -Order 1 -Icon '&#xE77B;'

# Email with pattern validation
Add-WizardTextBox -Step 'UserInfo' `
    -Name 'Email' `
    -Label 'Email Address' `
    -ValidationPattern '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' `
    -ValidationMessage 'Please enter a valid email address' `
    -Mandatory

# Phone with pattern validation
Add-WizardTextBox -Step 'UserInfo' `
    -Name 'Phone' `
    -Label 'Phone Number' `
    -ValidationPattern '^\(\d{3}\) \d{3}-\d{4}$' `
    -ValidationMessage 'Format: (555) 123-4567' `
    -HelpText 'Enter phone in format: (555) 123-4567'

# Password with complexity requirements
$passwordParams = @{
    Step              = 'UserInfo'
    Name              = 'Password'
    Label             = 'Password'
    MinLength         = 12
    ShowRevealButton  = $true
    ValidationPattern = '^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&]).{12,}$'
    ValidationMessage = 'Password must be 12+ characters with uppercase, lowercase, number, and special character'
    Mandatory         = $true
}
Add-WizardPassword @passwordParams

# Age with range validation
Add-WizardNumericUpDown -Step 'UserInfo' `
    -Name 'Age' `
    -Label 'Age' `
    -MinValue 18 `
    -MaxValue 120 `
    -DefaultValue 25 `
    -Mandatory

# Show wizard
$result = Show-PoshWizard

if ($result) {
    Write-Host "User registered successfully!" -ForegroundColor Green
    Write-Host "Email: $($result.Email)"
    Write-Host "Phone: $($result.Phone)"
    Write-Host "Age: $($result.Age)"
}
```

---

## Complete Parameter Reference

### New-PoshWizard

Initializes a new wizard instance.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Title` | string | Yes | Wizard title displayed in window and sidebar |
| `-Description` | string | No | Brief description of wizard purpose |
| `-Theme` | string | No | UI theme: `'Auto'`, `'Light'`, or `'Dark'` (default: `'Auto'`) |
| `-Icon` | string | No | Path to window icon image (`.png`, `.ico`) |

### Set-WizardBranding

Customizes wizard appearance and branding.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-WindowTitle` | string | No | Custom window title (overrides wizard title) |
| `-SidebarHeaderText` | string | No | Text shown in sidebar header |
| `-SidebarHeaderIcon` | string | No | Path to sidebar icon image |
| `-SidebarHeaderIconOrientation` | string | No | Icon position: `'Left'`, `'Right'`, `'Top'`, `'Bottom'` |

### Add-WizardStep

Creates a new step (page) in the wizard.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Name` | string | Yes | Unique identifier for the step |
| `-Title` | string | Yes | Display title shown in sidebar |
| `-Order` | int | Yes | Numeric order (1, 2, 3...) |
| `-Icon` | string | No | Fluent icon glyph (e.g., `'&#xE713;'`) |
| `-Description` | string | No | Brief description shown in sidebar |

### Add-WizardTextBox

Single-line text input control.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Default` | string | No | Default value |
| `-Mandatory` | switch | No | Makes field required |
| `-MaxLength` | int | No | Maximum character length |
| `-Placeholder` | string | No | Placeholder text |
| `-ValidationPattern` | string | No | Regex pattern for validation |
| `-ValidationMessage` | string | No | Error message for validation failure |
| `-HelpText` | string | No | Tooltip/help text |
| `-Width` | int | No | Control width in pixels |

### Add-WizardMultiLine

Multi-line text input control.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Default` | string | No | Default value |
| `-Mandatory` | switch | No | Makes field required |
| `-Rows` | int | No | Number of visible rows (default: 5) |
| `-MaxLength` | int | No | Maximum character length |
| `-HelpText` | string | No | Tooltip/help text |
| `-Width` | int | No | Control width in pixels |

### Add-WizardPassword

Secure password input control.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Default` | securestring | No | Default value (as SecureString) |
| `-Mandatory` | switch | No | Makes field required |
| `-MinLength` | int | No | Minimum password length |
| `-MaxLength` | int | No | Maximum password length |
| `-ValidationPattern` | string | No | Regex pattern for validation |
| `-ValidationMessage` | string | No | Error message for validation failure |
| `-HelpText` | string | No | Tooltip/help text |
| `-Width` | int | No | Control width in pixels |

### Add-WizardDropdown

Dropdown (ComboBox) for single selection.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Choices` | array | Yes | Array of available choices |
| `-Default` | string | No | Default selected choice |
| `-Mandatory` | switch | No | Makes field required |
| `-ScriptBlock` | scriptblock | No | Generate choices at runtime (can depend on other parameters or external data) |
| `-DependsOn` | array | No | Parameters this control depends on (optional if auto-detected from ScriptBlock) |
| `-HelpText` | string | No | Tooltip/help text |
| `-Width` | int | No | Control width in pixels |

### Add-WizardListBox

List box for single or multi-selection.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Choices` | array | Yes | Array of available choices |
| `-Default` | array | No | Default selected choices |
| `-Mandatory` | switch | No | Makes field required |
| `-MultiSelect` | switch | No | Enable multi-selection (default: single) |
| `-Height` | int | No | Control height in pixels |
| `-ScriptBlock` | scriptblock | No | Generate choices at runtime (can depend on other parameters or external data) |
| `-DependsOn` | array | No | Parameters this control depends on (optional if auto-detected from ScriptBlock) |
| `-HelpText` | string | No | Tooltip/help text |
| `-Width` | int | No | Control width in pixels |

### Add-WizardOptionGroup

Radio button group for single selection.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Options` | array | Yes | Array of radio button options |
| `-Default` | string | No | Default selected option |
| `-Mandatory` | switch | No | Makes field required |
| `-Orientation` | string | No | Layout: `'Horizontal'` or `'Vertical'` (default: `'Vertical'`) |
| `-HelpText` | string | No | Tooltip/help text |
| `-Width` | int | No | Control width in pixels |

### Add-WizardCheckbox

Single checkbox for yes/no choices.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Default` | bool | No | Default checked state (default: `$false`) |
| `-HelpText` | string | No | Tooltip/help text |

### Add-WizardToggle

Toggle switch (modern alternative to checkbox).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Default` | bool | No | Default toggle state (default: `$false`) |
| `-HelpText` | string | No | Tooltip/help text |

### Add-WizardNumeric

Numeric spinner with min/max constraints.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Default` | int/double | No | Default value |
| `-Mandatory` | switch | No | Makes field required |
| `-Min` | int/double | No | Minimum allowed value |
| `-Max` | int/double | No | Maximum allowed value |
| `-Increment` | int/double | No | Step increment (default: 1) |
| `-HelpText` | string | No | Tooltip/help text |
| `-Width` | int | No | Control width in pixels |

### Add-WizardDate

Date selection control.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Default` | datetime | No | Default date value |
| `-Mandatory` | switch | No | Makes field required |
| `-Min` | datetime | No | Minimum allowed date |
| `-Max` | datetime | No | Maximum allowed date |
| `-HelpText` | string | No | Tooltip/help text |
| `-Width` | int | No | Control width in pixels |

### Add-WizardFilePath

File path selector with browse button.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Default` | string | No | Default file path |
| `-Mandatory` | switch | No | Makes field required |
| `-Filter` | string | No | File filter (e.g., `'JSON Files (*.json)\|*.json'`) |
| `-HelpText` | string | No | Tooltip/help text |
| `-Width` | int | No | Control width in pixels |

### Add-WizardFolderPath

Folder path selector with browse button.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Label` | string | Yes | Display label |
| `-Default` | string | No | Default folder path |
| `-Mandatory` | switch | No | Makes field required |
| `-HelpText` | string | No | Tooltip/help text |
| `-Width` | int | No | Control width in pixels |

### Add-WizardCard

Display-only informational card.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Step` | string | Yes | Step name to add control to |
| `-Name` | string | Yes | Unique control identifier |
| `-Title` | string | Yes | Card title |
| `-Content` | string | Yes | Card content (supports multi-line) |
| `-Icon` | string | No | Icon glyph from Segoe MDL2 Assets font (e.g., `'&#xE713;'`) |

### Show-PoshWizard

Displays the wizard and returns user input.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-ScriptBody` | scriptblock | No | Code to execute after wizard completes (before closing) |

---

## See Also

- [Parameter Attribute Syntax Guide](PARAMETER_SYNTAX_GUIDE.md) - Alternative declarative syntax
- [Control Reference](CONTROLS_REFERENCE.md) - Complete control documentation
- [Dynamic Parameters Guide](DYNAMIC_PARAMETERS.md) - Advanced dynamic scenarios
- [Examples Folder](../PoshWizard/Examples/) - Working examples

---

## Quick Reference

### Common Cmdlets

| Cmdlet | Purpose |
|--------|---------|
| `New-PoshWizard` | Initialize wizard |
| `Set-WizardBranding` | Configure branding |
| `Add-WizardStep` | Add a step/page |
| `Add-WizardTextBox` | Single-line text input |
| `Add-WizardMultiLineTextBox` | Multi-line text input |
| `Add-WizardPassword` | Password input |
| `Add-WizardDropdown` | Dropdown selection |
| `Add-WizardListBox` | List box selection |
| `Add-WizardRadioButtons` | Radio button group |
| `Add-WizardCheckbox` | Checkbox |
| `Add-WizardToggle` | Toggle switch |
| `Add-WizardNumericUpDown` | Numeric spinner |
| `Add-WizardDate` | Date picker |
| `Add-WizardFilePath` | File path selector |
| `Add-WizardFolderPath` | Folder path selector |
| `Add-WizardCard` | Informational card |
| `Show-PoshWizard` | Display wizard and get results |

### Common Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-Step` | Step name to add control to | `'Configuration'` |
| `-Name` | Unique control identifier | `'ServerName'` |
| `-Label` | Display label | `'Server Name'` |
| `-DefaultValue` | Initial value | `'SERVER01'` |
| `-Mandatory` | Required field | `$true` |
| `-HelpText` | Tooltip/help text | `'Enter server hostname'` |
| `-ValidationPattern` | Regex pattern | `'^[A-Z0-9-]+$'` |
| `-ValidationMessage` | Error message | `'Invalid format'` |

---

**Version:** 1.4.3  
**Last Updated:** November 2025
