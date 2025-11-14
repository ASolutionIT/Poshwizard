<#
.SYNOPSIS
    Advanced demonstration of dynamic controls with cascading dependencies.

.DESCRIPTION
    Comprehensive showcase of PoshWizard's dynamic control capabilities using PoshWizard Cmdlets.
    Demonstrates real-world scenarios with cascading dropdowns, conditional logic,
    CSV data sources, and dependency chains.
    
.NOTES
    Company: A Solution IT LLC
    Style: Clean PowerShell with hashtable splatting (no backticks)
    
.EXAMPLE
    .\Demo-DynamicControls.ps1
    
    Launches the advanced dynamic controls wizard demonstrating:
    - Cascading dropdowns (Environment -> Region -> Server)
    - CSV-based dynamic data
    - Multi-level dependencies
    - Real-time updates
#>

$modulePath = Join-Path $PSScriptRoot '..\PoshWizard.psd1'
Import-Module $modulePath -Force

$scriptIconPath = Join-Path $PSScriptRoot 'browser.png'
$sidebarIconPath = Join-Path $PSScriptRoot 'with_padding.png'

foreach ($assetPath in @($scriptIconPath, $sidebarIconPath)) {
    if (-not (Test-Path $assetPath)) {
        throw "Branding asset not found: $assetPath"
    }
}

Write-Host @'

========================================
  PoshWizard
  Advanced Dynamic Controls Demo
========================================
'@ -ForegroundColor Cyan

Write-Host "`nDemonstrating advanced dynamic control patterns:" -ForegroundColor Yellow
Write-Host "  - Cascading dropdowns with dependencies" -ForegroundColor White
Write-Host "  - Script block-driven choices" -ForegroundColor White
Write-Host "  - CSV data sources" -ForegroundColor White
Write-Host "  - Multi-level dependency chains" -ForegroundColor White
Write-Host "  - Conditional control behavior" -ForegroundColor White
Write-Host "  - Real-time updates" -ForegroundColor White
Write-Host ""

# ========================================
# CREATE SAMPLE DATA FILES
# ========================================

# Create sample CSV for database selection
$databasesCsvPath = Join-Path $env:TEMP 'poshwizard_databases.csv'
$databasesCsvContent = @'
DatabaseName,Server,Environment,Size
ProductionDB01,SQL-PROD-01,Production,500GB
ProductionDB02,SQL-PROD-02,Production,750GB
StagingDB01,SQL-STAGE-01,Staging,100GB
StagingDB02,SQL-STAGE-02,Staging,150GB
DevDB01,SQL-DEV-01,Development,50GB
DevDB02,SQL-DEV-02,Development,75GB
'@
Set-Content -Path $databasesCsvPath -Value $databasesCsvContent -Force

# Create sample CSV for application selection
$applicationsCsvPath = Join-Path $env:TEMP 'poshwizard_applications.csv'
$applicationsCsvContent = @'
AppName,AppType,RequiresDatabase
WebPortal,Web Application,Yes
APIGateway,API Service,Yes
FileProcessor,Background Service,No
MonitoringAgent,Monitoring,No
ReportGenerator,Reporting,Yes
'@
Set-Content -Path $applicationsCsvPath -Value $applicationsCsvContent -Force

Write-Host "Sample data files created in: $env:TEMP" -ForegroundColor Gray
Write-Host ""

# ========================================
# INITIALIZE WIZARD
# ========================================

$wizardParams = @{
    Title = 'Advanced Dynamic Controls Showcase'
    Description = 'Demonstrating cascading dependencies and dynamic data sources'
    Theme = 'Auto'
    Icon = $scriptIconPath
}
New-PoshWizard @wizardParams

$brandingParams = @{
    WindowTitle                  = 'Advanced Dynamic Controls Showcase'
    SidebarHeaderText            = 'Dynamic Controls'
    SidebarHeaderIcon            = $sidebarIconPath
    SidebarHeaderIconOrientation = 'Top'
}
Set-WizardBranding @brandingParams

# ========================================
# STEP 1: Welcome and Overview
# ========================================

$step1Params = @{
    Name = 'Welcome'
    Title = 'Welcome'
    Order = 1
    Icon = '&#xE8BC;'
    Description = 'Introduction to dynamic controls'
}
Add-WizardStep @step1Params

$welcomeCardParams = @{
    Step = 'Welcome'
    Name = 'WelcomeCard'
    Title = 'Advanced Dynamic Controls'
    Content = @'
This wizard demonstrates PoshWizard's powerful dynamic control capabilities.

Key Concepts Demonstrated:
- Cascading Dropdowns - Choices that update based on other selections
- Script Block Logic - Custom PowerShell code to generate options
- CSV Data Sources - Loading choices from external files
- Dependency Chains - Multi-level cascading (A -> B -> C -> D)
- Conditional Controls - Controls that appear/behave differently based on context

Real-World Scenario:
We'll walk through a deployment wizard where your selections dynamically
influence subsequent options, simulating real infrastructure choices.
'@
}
Add-WizardCard @welcomeCardParams

# ========================================
# STEP 2: Environment Selection (Base)
# ========================================

$step2Params = @{
    Name = 'Environment'
    Title = 'Environment'
    Order = 2
    Icon = '&#xE7F4;'
    Description = 'Select target environment'
}
Add-WizardStep @step2Params

$envInfoCardParams = @{
    Step = 'Environment'
    Name = 'EnvInfoCard'
    Title = 'Environment Selection'
    Content = @'
The environment you select will determine available regions and servers.

This demonstrates:
- Base selection that drives all subsequent choices
- Foundation of the dependency chain

Watch how your selection affects the next steps!
'@
}
Add-WizardCard @envInfoCardParams

# Static environment dropdown (foundation of dependency chain)
$environmentParams = @{
    Step = 'Environment'
    Name = 'TargetEnvironment'
    Label = 'Target Environment'
    Choices = @('Development', 'Staging', 'Production')
    Default = 'Development'
    Mandatory = $true
}
Add-WizardDropdown @environmentParams

# ========================================
# STEP 3: Region Selection (Dynamic - Level 1)
# ========================================

$step3Params = @{
    Name = 'Region'
    Title = 'Region'
    Order = 3
    Icon = '&#xE909;'
    Description = 'Select deployment region (depends on environment)'
}
Add-WizardStep @step3Params

$regionInfoCardParams = @{
    Step = 'Region'
    Name = 'RegionInfoCard'
    Title = 'Dynamic Region Selection'
    Content = @'
Regions are filtered based on your environment selection.

Dependency: TargetEnvironment -> Region

Logic:
- Production: Access to all global regions
- Staging: Limited to staging-approved regions
- Development: Local development regions only

This is a ScriptBlock-driven dropdown with parameter dependency.
'@
}
Add-WizardCard @regionInfoCardParams

# Dynamic region dropdown (depends on TargetEnvironment)
$regionParams = @{
    Step = 'Region'
    Name = 'DeploymentRegion'
    Label = 'Deployment Region'
    ScriptBlock = {
        param($TargetEnvironment)
        
        Start-Sleep -Milliseconds 300  # Simulate data retrieval
        
        switch ($TargetEnvironment) {
            'Production' {
                @('US-East-1', 'US-West-2', 'EU-Central-1', 'EU-West-1', 'AP-Southeast-1', 'AP-Northeast-1')
            }
            'Staging' {
                @('US-East-1-Staging', 'EU-Central-1-Staging', 'AP-Southeast-1-Staging')
            }
            'Development' {
                @('Dev-Local', 'Dev-Cloud-US', 'Dev-Cloud-EU')
            }
            default {
                @('Unknown')
            }
        }
    }
    DependsOn = @('TargetEnvironment')
    Mandatory = $true
}
Add-WizardDropdown @regionParams

# ========================================
# STEP 4: Server Selection (Dynamic - Level 2)
# ========================================

$step4Params = @{
    Name = 'Server'
    Title = 'Server'
    Order = 4
    Icon = '&#xE968;'
    Description = 'Select target server (depends on environment and region)'
}
Add-WizardStep @step4Params

$serverInfoCardParams = @{
    Step = 'Server'
    Name = 'ServerInfoCard'
    Title = 'Cascading Server Selection'
    Content = @'
Server list is dynamically generated based on BOTH environment and region.

Dependency Chain: TargetEnvironment -> Region -> Server

Logic:
- Server names include environment prefix
- Server availability filtered by region
- Simulates real infrastructure discovery

This demonstrates multi-parameter dependencies in ScriptBlocks.
'@
}
Add-WizardCard @serverInfoCardParams

# Dynamic server dropdown (depends on TargetEnvironment AND DeploymentRegion)
$serverParams = @{
    Step = 'Server'
    Name = 'TargetServer'
    Label = 'Target Server'
    ScriptBlock = {
        param($TargetEnvironment, $DeploymentRegion)
        
        Start-Sleep -Milliseconds 500  # Simulate server discovery
        
        # Generate server names based on environment and region
        $envPrefix = switch ($TargetEnvironment) {
            'Production' { 'PROD' }
            'Staging' { 'STG' }
            'Development' { 'DEV' }
        }
        
        # Extract region code (e.g., "US-East-1" -> "USE1")
        $regionCode = if ($DeploymentRegion -match '^([A-Z]{2,3})-([A-Za-z]+)-?(\d*)') {
            "$($matches[1])$($matches[2].Substring(0,1).ToUpper())$($matches[3])"
        }
        else {
            'LOCAL'
        }
        
        # Generate realistic server list
        $servers = @(
            "$envPrefix-WEB-$regionCode-01"
            "$envPrefix-WEB-$regionCode-02"
            "$envPrefix-APP-$regionCode-01"
            "$envPrefix-DB-$regionCode-01"
        )
        
        $servers
    }
    DependsOn = @('TargetEnvironment', 'DeploymentRegion')
    Mandatory = $true
}
Add-WizardDropdown @serverParams

# ========================================
# STEP 5: Application Selection (CSV-Driven)
# ========================================

$step5Params = @{
    Name = 'Application'
    Title = 'Application'
    Order = 5
    Icon = '&#xE74C;'
    Description = 'Select application to deploy from CSV data'
}
Add-WizardStep @step5Params

$appInfoCardParams = @{
    Step = 'Application'
    Name = 'AppInfoCard'
    Title = 'CSV-Based Application Selection'
    Content = @'
Application choices are loaded from a CSV file.

Data Source: poshwizard_applications.csv

This demonstrates:
- External data source integration
- CSV column mapping
- Real-world data-driven wizards

The CSV contains application metadata that will be used in the next step.
'@
}
Add-WizardCard @appInfoCardParams

# CSV-based application dropdown (using Import-Csv + Add-WizardDropdown)
$applicationChoices = (Import-Csv -Path $applicationsCsvPath).AppName

$applicationParams = @{
    Step = 'Application'
    Name = 'ApplicationName'
    Label = 'Application to Deploy'
    Choices = $applicationChoices
    Mandatory = $true
}
Add-WizardDropdown @applicationParams

# ========================================
# STEP 6: Database Selection (Environment-Filtered)
# ========================================

$step6Params = @{
    Name = 'Database'
    Title = 'Database'
    Order = 6
    Icon = '&#xE1D3;'
    Description = 'Select target database'
}
Add-WizardStep @step6Params

$dbInfoCardParams = @{
    Step = 'Database'
    Name = 'DbInfoCard'
    Title = 'Database Selection'
    Content = @'
Databases are dynamically filtered based on your environment selection.

Environment-Specific Databases:
- Development: 50-75GB databases (2 options)
- Staging: 100-150GB databases (2 options)
- Production: 500-750GB databases (2 options)

Tip: The database list updates automatically when you change the environment.
Try it: Go back and change the environment, then return here.

See also:
- PoshWizard\Examples\Demo-DynamicParameters-Cascading.ps1
- PoshWizard\Examples\Demo-DynamicParameters-Dependencies.ps1

Dynamic examples in this demo: Steps 3, 4, 6, and 7 (Region, Server, Database, Features)
'@
}
Add-WizardCard @dbInfoCardParams

# Database dropdown with dynamic filtering based on environment
$databaseParams = @{
    Step = 'Database'
    Name = 'DatabaseName'
    Label = 'Target Database'
    ScriptBlock = {
        param($TargetEnvironment)
        
        if ($TargetEnvironment -eq 'Production') {
            @('ProductionDB01 (500GB)', 'ProductionDB02 (750GB)')
        }
        elseif ($TargetEnvironment -eq 'Staging') {
            @('StagingDB01 (100GB)', 'StagingDB02 (150GB)')
        }
        else {
            @('DevDB01 (50GB)', 'DevDB02 (75GB)')
        }
    }
    Mandatory = $true
}
Add-WizardDropdown @databaseParams

# ========================================
# STEP 7: Deployment Options (Dynamic ListBox)
# ========================================

$step7Params = @{
    Name = 'Options'
    Title = 'Options'
    Order = 7
    Icon = '&#xE713;'
    Description = 'Select deployment features (multi-select, environment-dependent)'
}
Add-WizardStep @step7Params

$optionsInfoCardParams = @{
    Step = 'Options'
    Name = 'OptionsInfoCard'
    Title = 'Dynamic Multi-Select Options'
    Content = @'
Available deployment features change based on environment.

Dependency: TargetEnvironment -> FeatureList

Logic:
- Production: Security-focused features enabled
- Staging: Testing and validation features
- Development: Debug and development tools

This demonstrates ScriptBlock-driven multi-select ListBox controls.
'@
}
Add-WizardCard @optionsInfoCardParams

# Dynamic multi-select ListBox (depends on TargetEnvironment)
$featuresParams = @{
    Step = 'Options'
    Name = 'DeploymentFeatures'
    Label = 'Deployment Features (Multi-Select)'
    ScriptBlock = {
        param($TargetEnvironment)
        
        Start-Sleep -Milliseconds 200
        
        $baseFeatures = @('Logging', 'Monitoring', 'Health Checks')
        
        $environmentFeatures = switch ($TargetEnvironment) {
            'Production' {
                @('High Availability', 'Auto-Scaling', 'Disaster Recovery', 'Security Hardening')
            }
            'Staging' {
                @('Integration Tests', 'Performance Testing', 'Load Testing')
            }
            'Development' {
                @('Debug Mode', 'Hot Reload', 'Detailed Logging', 'Developer Tools')
            }
        }
        
        $baseFeatures + $environmentFeatures | Sort-Object
    }
    DependsOn = @('TargetEnvironment')
    MultiSelect = $true
    Height = 180
}
Add-WizardListBox @featuresParams

# ========================================
# STEP 8: Review and Summary
# ========================================

$step8Params = @{
    Name = 'Summary'
    Title = 'Summary'
    Order = 8
    Icon = '&#xE73A;'
    Description = 'Review your dynamic selections'
}
Add-WizardStep @step8Params

$summaryCardParams = @{
    Step = 'Summary'
    Name = 'SummaryCard'
    Title = 'Deployment Configuration Ready'
    Content = @'
Review your selections and click Finish to see the complete configuration.

This summary demonstrates how data gathered across cascading dependencies
can be compiled into a deployment-ready configuration.
'@
}
Add-WizardCard @summaryCardParams

# ========================================
# EXECUTION SCRIPT
# ========================================

$scriptBody = {
    Write-Host "`n" -NoNewline
    Write-Host ('=' * 80) -ForegroundColor Cyan
    Write-Host "  Advanced Dynamic Controls - Configuration Summary" -ForegroundColor Cyan
    Write-Host ('=' * 80) -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "DEPENDENCY CHAIN RESULTS:" -ForegroundColor Yellow
    Write-Host "  Environment         : $TargetEnvironment" -ForegroundColor White
    Write-Host "  ->" -ForegroundColor DarkGray
    Write-Host "  Region              : $DeploymentRegion" -ForegroundColor White
    Write-Host "  ->" -ForegroundColor DarkGray
    Write-Host "  Server              : $TargetServer" -ForegroundColor White
    Write-Host ""
    
    Write-Host "CSV-DRIVEN SELECTIONS:" -ForegroundColor Yellow
    Write-Host "  Application         : $ApplicationName" -ForegroundColor White
    Write-Host "  Database            : $DatabaseName" -ForegroundColor White
    Write-Host ""
    
    Write-Host "DYNAMIC FEATURES (Multi-Select):" -ForegroundColor Yellow
    if ($DeploymentFeatures -and $DeploymentFeatures.Count -gt 0) {
        foreach ($feature in $DeploymentFeatures) {
            Write-Host "  [SEL] $feature" -ForegroundColor Green
        }
    }
    else {
        Write-Host "  (none selected)" -ForegroundColor Gray
    }
    Write-Host ""
    
    Write-Host ('=' * 80) -ForegroundColor Cyan
    Write-Host "  All dynamic dependencies resolved successfully!" -ForegroundColor Green
    Write-Host ('=' * 80) -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "KEY LEARNINGS:" -ForegroundColor Yellow
    Write-Host "  - Used -ScriptBlock with param() for dynamic choices" -ForegroundColor White
    Write-Host "  - Specified -DependsOn to create cascading updates" -ForegroundColor White
    Write-Host "  - Loaded data from CSV files with Import-Csv + Add-WizardDropdown" -ForegroundColor White
    Write-Host "  - Combined CSV + ScriptBlock for filtered data" -ForegroundColor White
    Write-Host "  - Applied dependencies to multi-select ListBox controls" -ForegroundColor White
    Write-Host ""
}

# ========================================
# LAUNCH WIZARD
# ========================================

Write-Host "Launching advanced dynamic controls wizard..." -ForegroundColor Cyan
Write-Host ""

Show-PoshWizard -ScriptBody $scriptBody

# ========================================
# CLEANUP
# ========================================

Write-Host "`nCleaning up temporary files..." -ForegroundColor Gray
if (Test-Path $databasesCsvPath) {
    Remove-Item $databasesCsvPath -Force
}
if (Test-Path $applicationsCsvPath) {
    Remove-Item $applicationsCsvPath -Force
}
Write-Host "Cleanup complete." -ForegroundColor Gray


