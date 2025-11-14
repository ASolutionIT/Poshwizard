<#
.SYNOPSIS
Tests PoshWizard module loading and cmdlet export.

.DESCRIPTION
Verifies that the PoshWizard module loads correctly and exports all expected cmdlets.
This is the primary integration test for module functionality.

.EXAMPLE
& .\Test-ModuleLoading.ps1
#>

param(
    [string]$ModulePath = (Join-Path $PSScriptRoot '..\..\PoshWizard\PoshWizard.psd1')
)

$testsPassed = 0
$testsFailed = 0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  PoshWizard Module Loading Tests" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Module file exists
Write-Host "Test 1: Module file exists..." -ForegroundColor Yellow
if (Test-Path $ModulePath) {
    Write-Host "  PASS: Module file found at $ModulePath" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  FAIL: Module file not found at $ModulePath" -ForegroundColor Red
    $testsFailed++
    exit 1
}

# Test 2: Module imports successfully
Write-Host "`nTest 2: Module imports successfully..." -ForegroundColor Yellow
try {
    Import-Module $ModulePath -Force -ErrorAction Stop
    Write-Host "  PASS: Module imported successfully" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "  FAIL: Module import failed: $_" -ForegroundColor Red
    $testsFailed++
    exit 1
}

# Test 3: Verify cmdlets are exported
Write-Host "`nTest 3: Verify cmdlets are exported..." -ForegroundColor Yellow
$commands = Get-Command -Module PoshWizard -ErrorAction SilentlyContinue
if ($commands.Count -gt 0) {
    Write-Host "  PASS: $($commands.Count) cmdlets exported" -ForegroundColor Green
    Write-Host "    Cmdlets: $($commands.Name -join ', ')" -ForegroundColor Gray
    $testsPassed++
} else {
    Write-Host "  FAIL: No cmdlets exported" -ForegroundColor Red
    $testsFailed++
    exit 1
}

# Test 4: Verify core cmdlets exist
Write-Host "`nTest 4: Verify core cmdlets exist..." -ForegroundColor Yellow
$coreCmdlets = @('New-PoshWizard', 'Add-WizardStep', 'Add-WizardTextBox', 'Show-PoshWizard')
$missingCmdlets = @()

foreach ($cmdlet in $coreCmdlets) {
    if (-not (Get-Command $cmdlet -ErrorAction SilentlyContinue)) {
        $missingCmdlets += $cmdlet
    }
}

if ($missingCmdlets.Count -eq 0) {
    Write-Host "  PASS: All core cmdlets present" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  FAIL: Missing cmdlets: $($missingCmdlets -join ', ')" -ForegroundColor Red
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
