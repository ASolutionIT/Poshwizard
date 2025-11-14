#
# .SYNOPSIS
#     Demonstrates password validation patterns and custom rules with rich UI context.
# .DESCRIPTION
#     This sample wizard walks through four password validation scenarios, pairing each
#     control with descriptive cards so authors know exactly what policy is enforced.


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
  PoshWizard Password Validation Showcase
============================================
'@ -ForegroundColor Cyan

Write-Host "Exploring pattern-based and script-based validation techniques..." -ForegroundColor Yellow

$wizardParams = @{
    Title              = 'Password Validation Playground'
    Description        = 'Compare regex-driven policies with custom script logic in a guided experience.'
    Theme              = 'Auto'
    Icon               = $scriptIconPath
}
New-PoshWizard @wizardParams

$brandingParams = @{
    WindowTitle                  = 'Password Validation Playground'
    SidebarHeaderText            = 'Validation Scenarios'
    SidebarHeaderIcon            = $sidebarIconPath
    SidebarHeaderIconOrientation = 'Top'
}
Set-WizardBranding @brandingParams

$overviewStep = @{
    Name        = 'Overview'
    Title       = 'Welcome'
    Order       = 1
    Icon        = '&#xE8A1;'
    Description = 'How to use this password validation harness.'
}
Add-WizardStep @overviewStep

Add-WizardCard -Step 'Overview' -Name 'OverviewCard' -Title 'Why Password Validation Matters' -Content @'
This walkthrough highlights four common policy styles:

- Minimum length enforcement for baseline strength
- Multi-factor complexity using regex patterns
- Script-based business rules (blacklists, composition)
- Optional entry with lightweight guidance

Each subsequent step contains cards describing the expectation for that field so you can
see how the UI communicates requirements to end users.
'@

$patternStep = @{
    Name        = 'PatternRules'
    Title       = 'Pattern-based Policies'
    Order       = 2
    Icon        = '&#xE8AB;'
    Description = 'Compare minimum length versus complex regex requirements.'
}
Add-WizardStep @patternStep

Add-WizardCard -Step 'PatternRules' -Name 'PatternGuide' -Title 'Pattern Guidelines' -Content @'
Use these fields to explore regex validation:

- Simple Password -> 8+ characters, no additional constraints.
- Complex Password -> 12+ characters including uppercase, lowercase, number, and symbol.

Try submitting values that violate the notes to observe the inline feedback experience.
'@

Add-WizardPassword -Step 'PatternRules' -Name 'SimplePassword' -Label 'Simple Password (minimum 8 characters)' -MinLength 8 -Mandatory

$complexPasswordParams = @{
    Step              = 'PatternRules'
    Name              = 'ComplexPassword'
    Label             = 'Complex Password (12+ with full character mix)'
    ValidationPattern = '^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[@$!%*?&]).{12,}$'
    ValidationMessage = 'Must be 12+ characters with uppercase, lowercase, number, and special character (@$!%*?&).'
    Mandatory         = $true
}
Add-WizardPassword @complexPasswordParams

$scriptStep = @{
    Name        = 'ScriptRules'
    Title       = 'Script-based Policies'
    Order       = 3
    Icon        = '&#xE9D9;'
    Description = 'Enforce business logic that goes beyond standard regex.'
}
Add-WizardStep @scriptStep

Add-WizardCard -Step 'ScriptRules' -Name 'ScriptGuide' -Title 'Custom Logic' -Content @'
These controls demonstrate tailored validation:

- Custom Policy Password -> Requires upper, lower, numeric characters and blocks common weak strings.
- Optional Password -> Light-touch policy for advisory scenarios.

Adjust the script block in the sample to plug in your own enterprise rules or banned lists.
'@

$customPasswordParams = @{
    Step              = 'ScriptRules'
    Name              = 'CustomPassword'
    Label             = 'Custom Policy Password'
    ValidationScript  = {
        param($InputObject)
        $value = [string]$InputObject
        if ([string]::IsNullOrWhiteSpace($value)) {
            return $false
        }

        $value -match '[A-Z]' -and
        $value -match '[a-z]' -and
        $value -match '\d' -and
        $value -notmatch '(password|admin|12345|qwerty)'
    }
    ValidationMessage = 'Needs upper, lower, number, and must avoid banned words (password, admin, 12345, qwerty).'
    Mandatory         = $true
}
Add-WizardPassword @customPasswordParams

Add-WizardPassword -Step 'ScriptRules' -Name 'OptionalPassword' -Label 'Optional Password (minimum 6 characters)' -MinLength 6

$resultHandler = {
    Write-Host ''
    Write-Host '=== Password Validation Results ===' -ForegroundColor Green
    Write-Host "Simple Password Length: $($SimplePassword.Length)" -ForegroundColor Cyan
    Write-Host "Complex Password Length: $($ComplexPassword.Length)" -ForegroundColor Cyan
    Write-Host "Custom Password Length: $($CustomPassword.Length)" -ForegroundColor Cyan

    if ($OptionalPassword) {
        Write-Host "Optional Password Length: $($OptionalPassword.Length)" -ForegroundColor Cyan
    } else {
        Write-Host 'Optional Password: (not provided)' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host 'All password scenarios executed. Update the policies and rerun to experiment further.' -ForegroundColor Green
}

Show-PoshWizard -ScriptBody $resultHandler

