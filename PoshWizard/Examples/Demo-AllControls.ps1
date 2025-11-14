<#
.SYNOPSIS
    Complete demonstration of ALL PoshWizard controls using PoshWizard Cmdlets.

.DESCRIPTION
    Comprehensive showcase of all control types using PoshWizard Cmdlets.
    Demonstrates the Verb-Noun function approach with clean PowerShell splatting syntax.
    
    This is the PoshWizard Cmdlets equivalent of Demo-AllControls-Param.ps1.

.NOTES
    Company: A Solution IT LLC
    Style: Clean PowerShell with hashtable splatting (no backticks)
    
.EXAMPLE
    .\Demo-AllControls.ps1
    
    Launches the complete control showcase wizard using PoshWizard Cmdlets.
#>

$modulePath = Join-Path $PSScriptRoot '..\PoshWizard.psd1'
Import-Module $modulePath -Force

$serversCsvPath = Join-Path $PSScriptRoot 'sample-servers.csv'
if (-not (Test-Path $serversCsvPath)) {
    throw "CSV data file not found: $serversCsvPath"
}

$scriptIconPath = Join-Path $PSScriptRoot 'browser.png'
$sidebarIconPath = Join-Path $PSScriptRoot 'with_padding.png'

foreach ($assetPath in @($scriptIconPath, $sidebarIconPath)) {
    if (-not (Test-Path $assetPath)) {
        throw "Branding asset not found: $assetPath"
    }
}

Write-Host @'

========================================
  PoshWizard - Complete Demo
  PoshWizard Cmdlets
========================================
'@ -ForegroundColor Cyan

Write-Host "`nDemonstrating ALL control types with PoshWizard Cmdlets:" -ForegroundColor Yellow
Write-Host "  - Text inputs (single-line, multi-line, password)" -ForegroundColor White
Write-Host "  - Selection controls (dropdown, listbox, radio buttons)" -ForegroundColor White
Write-Host "  - Numeric and date pickers" -ForegroundColor White
Write-Host "  - Boolean controls (checkbox, toggle switch)" -ForegroundColor White
Write-Host "  - Path selectors (file, folder)" -ForegroundColor White
Write-Host "  - Information cards for guidance" -ForegroundColor White
Write-Host ""

# ========================================
# INITIALIZE WIZARD
# ========================================

$wizardParams = @{
    Title = 'PoshWizard - Complete Feature Demo'
    Description = 'Comprehensive demonstration using PowerShell Module API'
    Theme = 'Dark'
    Icon = $scriptIconPath
}
New-PoshWizard @wizardParams

$brandingParams = @{
    WindowTitle = 'PoshWizard - Complete Feature Demo'
    SidebarHeaderIcon = $sidebarIconPath
}
Set-WizardBranding @brandingParams

# ========================================
# STEP 1: Welcome
# ========================================

$step1Params = @{
    Name = 'Welcome'
    Title = 'Welcome'
    Order = 1
    Icon = '&#xE8BC;'
    Description = 'Get started with this comprehensive demo'
}
Add-WizardStep @step1Params

$welcomeCardParams = @{
    Step = 'Welcome'
    Name = 'WelcomeCard'
    Title = 'Welcome to PoshWizard'
    Content = @'
This wizard demonstrates every control type available in the PoshWizard framework.

Features:
- Text inputs (single & multi-line)
- Password fields with reveal
- Dropdowns, lists, and radio buttons
- Numeric spinners and date pickers
- File/folder path selectors
- Checkboxes and toggle switches
- Informational cards

Navigate through each step to see all control types in action!
'@
}
Add-WizardCard @welcomeCardParams

# ========================================
# STEP 2: Text Input Controls
# ========================================

$step2Params = @{
    Name = 'TextInputs'
    Title = 'Text Inputs'
    Order = 2
    Icon = '&#xE70F;'
    Description = 'Single-line, multi-line, and password fields'
}
Add-WizardStep @step2Params

$textInfoCardParams = @{
    Step = 'TextInputs'
    Name = 'TextInputsInfo'
    Title = 'Text Input Controls'
    Content = @'
PoshWizard supports various text input types for different use cases.

- Single-line TextBox for short text
- Multi-line TextBox for paragraphs
- Password fields with reveal toggle
- All fields support validation patterns
'@
}
Add-WizardCard @textInfoCardParams

# Single-line TextBox
$projectNameParams = @{
    Step = 'TextInputs'
    Name = 'ProjectName'
    Label = 'Project Name'
    Default = 'MyProject'
    Mandatory = $true
}
Add-WizardTextBox @projectNameParams

# Password field (SecureString)
$passwordParams = @{
    Step = 'TextInputs'
    Name = 'AdminPassword'
    Label = 'Administrator Password'
    Mandatory = $true
}
Add-WizardPassword @passwordParams

# Multi-line TextBox
$descriptionParams = @{
    Step = 'TextInputs'
    Name = 'ProjectDescription'
    Label = 'Project Description'
    Rows = 5
    Default = ''
}
Add-WizardMultiLine @descriptionParams

# ========================================
# STEP 3: Selection Controls
# ========================================

$step3Params = @{
    Name = 'Selections'
    Title = 'Selections'
    Order = 3
    Icon = '&#xE762;'
    Description = 'Dropdown menus, list boxes, and radio button groups'
}
Add-WizardStep @step3Params

$selectionsInfoCardParams = @{
    Step = 'Selections'
    Name = 'SelectionsInfo'
    Title = 'Selection Controls'
    Content = @'
Choose from various selection patterns:

- Dropdown (ComboBox) for compact lists
- ListBox for scrollable single-select
- Multi-select ListBox with Ctrl+Click, Shift+Click, or drag selection
- Radio buttons (OptionGroup) for visual clarity
'@
}
Add-WizardCard @selectionsInfoCardParams

# Dropdown/ComboBox (single-select)
$regionParams = @{
    Step = 'Selections'
    Name = 'DeploymentRegion'
    Label = 'Deployment Region'
    Choices = @('US-East', 'US-West', 'EU-Central', 'Asia-Pacific')
    Default = 'US-East'
    Mandatory = $true
}
Add-WizardDropdown @regionParams

$serverChoices = (Import-Csv -Path $serversCsvPath).ServerName

$serverDropdownParams = @{
    Step = 'Selections'
    Name = 'DeploymentServer'
    Label = 'Deployment Server (CSV)'
    Choices = $serverChoices
    Default = $serverChoices[0]
    Mandatory = $true
}
Add-WizardDropdown @serverDropdownParams

# Radio Button Group (OptionGroup)
$environmentParams = @{
    Step = 'Selections'
    Name = 'EnvironmentType'
    Label = 'Environment Type'
    Options = @('Development', 'Testing', 'Staging', 'Production')
    Default = 'Development'
    Orientation = 'Horizontal'
    Mandatory = $true
}
Add-WizardOptionGroup @environmentParams

# Multi-select ListBox
$featuresParams = @{
    Step = 'Selections'
    Name = 'Features'
    Label = 'Features to Install'
    Choices = @('Web Server', 'Database', 'Cache', 'Queue', 'Monitoring', 'Logging')
    MultiSelect = $true
    Height = 150
}
Add-WizardListBox @featuresParams

# ========================================
# STEP 4: Numeric and Date Controls
# ========================================

$step4Params = @{
    Name = 'NumericDate'
    Title = 'Numeric & Date'
    Order = 4
    Icon = '&#xE787;'
    Description = 'Numeric spinners and date pickers with range validation'
}
Add-WizardStep @step4Params

$numericInfoCardParams = @{
    Step = 'NumericDate'
    Name = 'NumericDateInfo'
    Title = 'Numeric and Date Controls'
    Content = @'
Advanced input controls for structured data:

- Numeric spinner with increment/decrement buttons
- Date picker with calendar popup
- Range validation (min/max)
- Custom formatting support
'@
}
Add-WizardCard @numericInfoCardParams

# Numeric spinner (integer)
$instanceCountParams = @{
    Step = 'NumericDate'
    Name = 'InstanceCount'
    Label = 'Number of Instances'
    Minimum = 1
    Maximum = 100
    Default = 3
    StepSize = 1
    Mandatory = $true
}
Add-WizardNumeric @instanceCountParams

# Numeric spinner (decimal)
$memoryParams = @{
    Step = 'NumericDate'
    Name = 'MemoryAllocation'
    Label = 'Memory Allocation (GB)'
    Minimum = 0.5
    Maximum = 256
    Default = 4.0
    StepSize = 0.5
    Mandatory = $true
}
Add-WizardNumeric @memoryParams

# Date picker
$launchDateParams = @{
    Step = 'NumericDate'
    Name = 'LaunchDate'
    Label = 'Planned Launch Date'
    Minimum = '2025-01-01'
    Maximum = '2025-12-31'
    Default = '2025-06-01'
    Format = 'yyyy-MM-dd'
    Mandatory = $true
}
Add-WizardDate @launchDateParams

# ========================================
# STEP 5: Boolean Controls
# ========================================

$step5Params = @{
    Name = 'Options'
    Title = 'Options'
    Order = 5
    Icon = '&#xE73E;'
    Description = 'Checkboxes and toggle switches for yes/no options'
}
Add-WizardStep @step5Params

$optionsInfoCardParams = @{
    Step = 'Options'
    Name = 'OptionsInfo'
    Title = 'Boolean Controls'
    Content = @'
Two styles of boolean controls with different APIs:

- CheckBox (traditional) - Use Add-WizardCheckbox
- Toggle Switch (modern) - Use Add-WizardToggle

Module API Syntax:
  Add-WizardCheckbox -Name "EnableSSL" -Default $true
  Add-WizardToggle -Name "Maintenance" -Default $false
'@
}
Add-WizardCard @optionsInfoCardParams

# Traditional CheckBox
$sslParams = @{
    Step = 'Options'
    Name = 'EnableSSL'
    Label = 'Enable SSL/TLS Encryption'
    Default = $true
}
Add-WizardCheckbox @sslParams

# Traditional CheckBox
$backupsParams = @{
    Step = 'Options'
    Name = 'EnableBackups'
    Label = 'Enable Automatic Backups'
    Default = $true
}
Add-WizardCheckbox @backupsParams

# Modern Toggle Switch
$maintenanceParams = @{
    Step = 'Options'
    Name = 'MaintenanceMode'
    Label = 'Enable Maintenance Mode'
    Default = $false
}
Add-WizardToggle @maintenanceParams

# Modern Toggle Switch
$notificationsParams = @{
    Step = 'Options'
    Name = 'SendNotifications'
    Label = 'Send Email Notifications'
    Default = $true
}
Add-WizardToggle @notificationsParams

# ========================================
# STEP 6: Path Selectors
# ========================================

$step6Params = @{
    Name = 'Paths'
    Title = 'Paths'
    Order = 6
    Icon = '&#xE8B7;'
    Description = 'File and folder path selectors with browse dialogs'
}
Add-WizardStep @step6Params

$pathsInfoCardParams = @{
    Step = 'Paths'
    Name = 'PathsInfo'
    Title = 'Path Selectors'
    Content = @'
Browse for files and folders with native dialogs:

- File picker with type filters
- Folder browser for directories
- Browse button (three dots) for easy selection
- Manual entry also supported
'@
}
Add-WizardCard @pathsInfoCardParams

# File path selector
$configFileParams = @{
    Step = 'Paths'
    Name = 'TextFile'
    Label = 'Config File'
    DialogTitle = 'Select Configuration File'
    Mandatory = $false
}
Add-WizardFilePath @configFileParams

# Folder path selector (mandatory)
$dataDirectoryParams = @{
    Step = 'Paths'
    Name = 'DataDirectory'
    Label = 'Data Directory'
    Default = 'C:\Windows'
    Mandatory = $false
}
Add-WizardFolderPath @dataDirectoryParams

# Folder path selector (optional)
$logDirectoryParams = @{
    Step = 'Paths'
    Name = 'LogDirectory'
    Label = 'Log Directory'
    Default = 'C:\Users'
}
Add-WizardFolderPath @logDirectoryParams

# ========================================
# STEP 7: Summary
# ========================================

$step7Params = @{
    Name = 'Summary'
    Title = 'Summary'
    Order = 7
    Icon = '&#xE73A;'
    Description = 'Review your configuration before proceeding'
}
Add-WizardStep @step7Params

$summaryCardParams = @{
    Step = 'Summary'
    Name = 'SummaryCard'
    Title = 'Ready to Deploy'
    Content = @'
Review your configuration and click Finish to apply the settings.

The wizard will generate a summary of all selected options and execute the deployment script.
'@
}
Add-WizardCard @summaryCardParams

# ========================================
# EXECUTION SCRIPT
# ========================================

$scriptBody = {
    Write-Host "`n" -NoNewline
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host "  PoshWizard Demo - Configuration Summary" -ForegroundColor Cyan
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "TEXT INPUTS:" -ForegroundColor Yellow
    Write-Host "  Project Name        : $ProjectName" -ForegroundColor White
    Write-Host "  Password Set        : $(if ($AdminPassword) { '****** (hidden)' } else { '(not provided)' })" -ForegroundColor White
    Write-Host "  Description         : $ProjectDescription" -ForegroundColor White
    Write-Host ""
    
    Write-Host "SELECTIONS:" -ForegroundColor Yellow
    Write-Host "  Region              : $DeploymentRegion" -ForegroundColor White
    Write-Host "  Server              : $DeploymentServer" -ForegroundColor White
    Write-Host "  Environment         : $EnvironmentType" -ForegroundColor White
    Write-Host "  Features            : $($Features -join ', ')" -ForegroundColor White
    Write-Host ""
    
    Write-Host "NUMERIC & DATES:" -ForegroundColor Yellow
    Write-Host "  Instance Count      : $InstanceCount" -ForegroundColor White
    Write-Host "  Memory (GB)         : $MemoryAllocation" -ForegroundColor White
    Write-Host "  Launch Date         : $LaunchDate" -ForegroundColor White
    Write-Host ""
    
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  SSL Enabled         : $EnableSSL" -ForegroundColor White
    Write-Host "  Backups Enabled     : $EnableBackups" -ForegroundColor White
    Write-Host "  Maintenance Mode    : $MaintenanceMode" -ForegroundColor White
    Write-Host "  Notifications       : $SendNotifications" -ForegroundColor White
    Write-Host ""
    
    Write-Host "PATHS:" -ForegroundColor Yellow
    Write-Host "  Config File         : $ConfigFile" -ForegroundColor White
    Write-Host "  Data Directory      : $DataDirectory" -ForegroundColor White
    Write-Host "  Log Directory       : $(if ($LogDirectory) { $LogDirectory } else { '(not specified)' })" -ForegroundColor White
    Write-Host ""
    
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host "  Configuration complete!" -ForegroundColor Green
    Write-Host "  Ready to deploy with these settings." -ForegroundColor Green
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host ""

    Return $DataDirectory
}

# ========================================
# LAUNCH WIZARD
# ========================================

Write-Host "Launching wizard..." -ForegroundColor Cyan
Write-Host ""

Show-PoshWizard -ScriptBody $scriptBody



