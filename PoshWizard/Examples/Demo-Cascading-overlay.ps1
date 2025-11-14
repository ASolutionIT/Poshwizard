#
# .SYNOPSIS
#     Demonstrates cascading dropdowns using PoshWizard Cmdlets with progress overlays.
# .DESCRIPTION
#     Builds a multi-step wizard that highlights when the built-in progress overlay appears
#     for dependent dropdowns. Cards provide guidance for each scenario so authors can see
#     what triggers the overlay and how to communicate it to users.

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

============================================
  Cascading Dropdowns with Progress Overlay
============================================
'@ -ForegroundColor Cyan

Write-Host 'Launching wizard via PoshWizard Cmdlets so you can experiment with overlay triggers...' -ForegroundColor Yellow

# -------------------------------------------------------------
# Wizard definition
# -------------------------------------------------------------

$wizardParams = @{
    Title              = 'Overlay Showcase'
    Description        = 'Understand how dependent dropdowns display the progress overlay.'
    Theme              = 'Auto'
    Icon               = $scriptIconPath
}
New-PoshWizard @wizardParams

$brandingParams = @{
    WindowTitle                  = 'Overlay Showcase'
    SidebarHeaderText            = 'Overlay Scenarios'
    SidebarHeaderIcon            = $sidebarIconPath
    SidebarHeaderIconOrientation = 'Top'
}
Set-WizardBranding @brandingParams

# -------------------------------------------------------------
# STEP 1: Overview
# -------------------------------------------------------------

$overviewStep = @{
    Name        = 'Overview'
    Title       = 'Welcome'
    Order       = 1
    Icon        = '&#xE8D6;'
    Description = 'How the progress overlay behaves in cascading flows.'
}
Add-WizardStep @overviewStep

Add-WizardCard -Step 'Overview' -Name 'OverlayIntro' -Title 'What to Watch For' -Content @'
This demo illustrates two key overlay interactions:

- Dependent dropdowns trigger the overlay while data loads.
- Nested dependencies can cause multiple overlays as chains resolve.

Each subsequent step includes a card explaining the scenario so you can reproduce it in your own scripts.
'@

# -------------------------------------------------------------
# STEP 2: Environment selection (base)
# -------------------------------------------------------------

$envStep = @{
    Name        = 'Environment'
    Title       = 'Environment'
    Order       = 2
    Icon        = '&#xE77C;'
    Description = 'Choose the base environment (loads instantly).'
}
Add-WizardStep @envStep

Add-WizardCard -Step 'Environment' -Name 'EnvironmentCard' -Title 'Base Selection' -Content @'
The first dropdown is static, so no overlay appears here.

Use it to drive dependencies in later steps.
'@

Add-WizardDropdown -Step 'Environment' -Name 'TargetEnvironment' -Label 'Target Environment' -Choices @('Development', 'Staging', 'Production') -Default 'Development' -Mandatory

# -------------------------------------------------------------
# STEP 3: Region (single dependency)
# -------------------------------------------------------------

$regionStep = @{
    Name        = 'Region'
    Title       = 'Region'
    Order       = 3
    Icon        = '&#xE909;'
    Description = 'Demonstrates overlay for a single dependency.'
}
Add-WizardStep @regionStep

Add-WizardCard -Step 'Region' -Name 'RegionCard' -Title 'Single Dependency Overlay' -Content @'
Changing the Environment parameter causes this dropdown to re-run its data source.
We intentionally pause for 2 seconds (Start-Sleep) so the launcher detects the delay
and displays the overlay. Any dependency change that takes longer than ~500 ms
automatically triggers the overlay.
'@

$regionDropdownParams = @{
    Step         = 'Region'
    Name         = 'TargetRegion'
    Label        = 'Target Region'
    ScriptBlock  = {
        param($TargetEnvironment)

        Start-Sleep -Seconds 2

        switch ($TargetEnvironment) {
            'Development' { @('Dev-US-East', 'Dev-US-West', 'Dev-EU-Central') }
            'Staging'     { @('Stage-US-East', 'Stage-EU-West') }
            'Production'  { @('Prod-US-East-1', 'Prod-US-West-1', 'Prod-EU-Central-1', 'Prod-APAC-1') }
            default       { @('Unknown') }
        }
    }
    DependsOn    = @('TargetEnvironment')
    Mandatory    = $true
}
Add-WizardDropdown @regionDropdownParams

# -------------------------------------------------------------
# STEP 4: Server (multi dependency)
# -------------------------------------------------------------

$serverStep = @{
    Name        = 'Server'
    Title       = 'Server'
    Order       = 4
    Icon        = '&#xE9CE;'
    Description = 'Demonstrates overlays for multi-parameter dependencies.'
}
Add-WizardStep @serverStep

Add-WizardCard -Step 'Server' -Name 'ServerCard' -Title 'Cascading Dependencies' -Content @'
This dropdown depends on both Environment and Region. When either parent changes,
the script block runs again, waits 1.5 seconds, and the overlay appears while
choices are recalculated. Chained dependencies often show multiple overlays.
'@

$serverDropdownParams = @{
    Step         = 'Server'
    Name         = 'TargetServer'
    Label        = 'Target Server'
    ScriptBlock  = {
        param($TargetEnvironment, $TargetRegion)

        Start-Sleep -Milliseconds 1500

        $prefix = switch ($TargetEnvironment) {
            'Production' { 'PROD' }
            'Staging'    { 'STG' }
            default      { 'DEV' }
        }

        $regionCode = ($TargetRegion -split '-')[-1]

        1..5 | ForEach-Object { "$prefix-$regionCode-Server-$_" }
    }
    DependsOn    = @('TargetEnvironment', 'TargetRegion')
    Mandatory    = $true
}
Add-WizardDropdown @serverDropdownParams

# -------------------------------------------------------------
# STEP 5: Additional example (listbox dependency)
# -------------------------------------------------------------

$appsStep = @{
    Name        = 'Applications'
    Title       = 'Applications'
    Order       = 5
    Icon        = '&#xE8FD;'
    Description = 'Shows overlays with a listbox fed by a script block.'
}
Add-WizardStep @appsStep

Add-WizardCard -Step 'Applications' -Name 'ApplicationsCard' -Title 'Bonus Scenario' -Content @'
This listbox depends on the Target Server. After you pick a server we wait 1.2 seconds
to simulate gathering app metadata, so the overlay flashes again. Any time a dependent
parameter change causes slow work, the overlay provides feedback to the user.
'@

$appListParams = @{
    Step         = 'Applications'
    Name         = 'Applications'
    Label        = 'Applications to Deploy'
    ScriptBlock  = {
        param($TargetServer)

        Start-Sleep -Milliseconds 1200

        if ([string]::IsNullOrWhiteSpace($TargetServer)) {
            return @()
        }

        @(
            'Config Service'
            'Telemetry Gateway'
            'Metrics Collector'
            "$TargetServer Backup Agent"
        )
    }
    DependsOn    = @('TargetServer')
    Mandatory    = $false
}
Add-WizardListBox @appListParams

# -------------------------------------------------------------
# STEP 6: Summary and notes
# -------------------------------------------------------------

$summaryStep = @{
    Name        = 'Summary'
    Title       = 'Summary'
    Order       = 6
    Icon        = '&#xE9F1;'
    Description = 'Capture final notes after exploring overlays.'
}
Add-WizardStep @summaryStep

Add-WizardCard -Step 'Summary' -Name 'SummaryCard' -Title 'Observations' -Content @'
Consider documenting what caused overlays and how long each dependency took.
Use this space to collect qualitative feedback from testers after they explore the scenarios.
'@

Add-WizardMultiLine -Step 'Summary' -Name 'OverlayNotes' -Label 'Overlay Observations' -Rows 5 -HelpText 'Record your findings here.'

# -------------------------------------------------------------
# Render wizard
# -------------------------------------------------------------

Show-PoshWizard -ScriptBody {
    Write-Host ''
    Write-Host '=== Cascading Overlay Results ===' -ForegroundColor Green
    Write-Host "Environment: $TargetEnvironment" -ForegroundColor Cyan
    Write-Host "Region:      $TargetRegion" -ForegroundColor Cyan
    Write-Host "Server:      $TargetServer" -ForegroundColor Cyan

    if ($Applications) {
        Write-Host 'Applications:' -ForegroundColor Cyan
        $Applications | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
    } else {
        Write-Host 'Applications: (none selected)' -ForegroundColor Yellow
    }

    if ($OverlayNotes) {
        Write-Host ''
        Write-Host 'Overlay Notes:' -ForegroundColor Cyan
        Write-Host $OverlayNotes -ForegroundColor Cyan
    }

    Write-Host ''
    Write-Host 'Remember: overlays appear whenever a dependent script block runs long enough to trigger progress feedback.' -ForegroundColor Green
}


