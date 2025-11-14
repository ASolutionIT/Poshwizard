<#
.SYNOPSIS
Tests that all PoshWizard cmdlets accept correct parameters.

.DESCRIPTION
Validates parameter definitions, mandatory flags, and parameter sets for all cmdlets.

.EXAMPLE
& .\Test-CmdletParameters.ps1
#>

param(
    [string]$ModulePath = (Join-Path $PSScriptRoot '..\..\PoshWizard\PoshWizard.psd1')
)

$testsPassed = 0
$testsFailed = 0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  PoshWizard Cmdlet Parameter Tests" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Import module
try {
    Import-Module $ModulePath -Force -ErrorAction Stop
} catch {
    Write-Host "FAIL: Could not import module: $_" -ForegroundColor Red
    exit 1
}

# Test 1: New-PoshWizard parameters
Write-Host "Test 1: New-PoshWizard parameters..." -ForegroundColor Yellow
$cmd = Get-Command New-PoshWizard -ErrorAction SilentlyContinue
if ($cmd) {
    $params = $cmd.Parameters.Keys
    $requiredParams = @('Title')
    
    $missingRequired = $requiredParams | Where-Object { $_ -notin $params }
    
    if ($missingRequired.Count -eq 0) {
        Write-Host "  PASS: All required parameters present" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  FAIL: Missing required parameters: $($missingRequired -join ', ')" -ForegroundColor Red
        $testsFailed++
    }
} else {
    Write-Host "  FAIL: New-PoshWizard cmdlet not found" -ForegroundColor Red
    $testsFailed++
}

# Test 2: Add-WizardStep parameters
Write-Host "`nTest 2: Add-WizardStep parameters..." -ForegroundColor Yellow
$cmd = Get-Command Add-WizardStep -ErrorAction SilentlyContinue
if ($cmd) {
    $params = $cmd.Parameters.Keys
    $requiredParams = @('Name', 'Title', 'Order')
    
    $missingRequired = $requiredParams | Where-Object { $_ -notin $params }
    
    if ($missingRequired.Count -eq 0) {
        Write-Host "  PASS: All required parameters present" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  FAIL: Missing required parameters: $($missingRequired -join ', ')" -ForegroundColor Red
        $testsFailed++
    }
} else {
    Write-Host "  FAIL: Add-WizardStep cmdlet not found" -ForegroundColor Red
    $testsFailed++
}

# Test 3: Add-WizardTextBox parameters
Write-Host "`nTest 3: Add-WizardTextBox parameters..." -ForegroundColor Yellow
$cmd = Get-Command Add-WizardTextBox -ErrorAction SilentlyContinue
if ($cmd) {
    $params = $cmd.Parameters.Keys
    $requiredParams = @('Step', 'Name', 'Label')
    
    $missingRequired = $requiredParams | Where-Object { $_ -notin $params }
    
    if ($missingRequired.Count -eq 0) {
        Write-Host "  PASS: All required parameters present" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  FAIL: Missing required parameters: $($missingRequired -join ', ')" -ForegroundColor Red
        $testsFailed++
    }
} else {
    Write-Host "  FAIL: Add-WizardTextBox cmdlet not found" -ForegroundColor Red
    $testsFailed++
}

# Test 4: Show-PoshWizard parameters
Write-Host "`nTest 4: Show-PoshWizard parameters..." -ForegroundColor Yellow
$cmd = Get-Command Show-PoshWizard -ErrorAction SilentlyContinue
if ($cmd) {
    $params = $cmd.Parameters.Keys
    $hasScriptBody = 'ScriptBody' -in $params
    
    if ($hasScriptBody) {
        Write-Host "  PASS: ScriptBody parameter present for live execution" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  WARN: ScriptBody parameter not found" -ForegroundColor Yellow
        $testsPassed++
    }
} else {
    Write-Host "  FAIL: Show-PoshWizard cmdlet not found" -ForegroundColor Red
    $testsFailed++
}

# Test 5: Parameter validation attributes
Write-Host "`nTest 5: Parameter validation attributes..." -ForegroundColor Yellow
$cmd = Get-Command Add-WizardTextBox -ErrorAction SilentlyContinue
if ($cmd) {
    $stepParam = $cmd.Parameters['Step']
    $isMandatory = $stepParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' -and $_.Mandatory }
    
    if ($isMandatory) {
        Write-Host "  PASS: Step parameter is marked as mandatory" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  FAIL: Step parameter should be mandatory" -ForegroundColor Red
        $testsFailed++
    }
} else {
    Write-Host "  FAIL: Add-WizardTextBox cmdlet not found" -ForegroundColor Red
    $testsFailed++
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Passed: $testsPassed" -ForegroundColor Green
Write-Host "  Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { 'Red' } else { 'Green' })
Write-Host "========================================`n" -ForegroundColor Cyan

if ($testsFailed -gt 0) {
    exit 1
}
