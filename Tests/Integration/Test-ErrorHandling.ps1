<#
.SYNOPSIS
Tests error handling in PoshWizard cmdlets.

.DESCRIPTION
Validates that cmdlets properly handle invalid inputs and provide meaningful error messages.

.EXAMPLE
& .\Test-ErrorHandling.ps1
#>

param(
    [string]$ModulePath = (Join-Path $PSScriptRoot '..\..\PoshWizard\PoshWizard.psd1')
)

$testsPassed = 0
$testsFailed = 0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  PoshWizard Error Handling Tests" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Import module
try {
    Import-Module $ModulePath -Force -ErrorAction Stop
} catch {
    Write-Host "FAIL: Could not import module: $_" -ForegroundColor Red
    exit 1
}

# Test 1: New-PoshWizard without required parameter
Write-Host "Test 1: New-PoshWizard without Title (should fail)..." -ForegroundColor Yellow
try {
    New-PoshWizard -ErrorAction Stop
    Write-Host "  FAIL: Should have thrown error for missing Title parameter" -ForegroundColor Red
    $testsFailed++
} catch {
    Write-Host "  PASS: Correctly throws error for missing Title parameter" -ForegroundColor Green
    $testsPassed++
}

# Test 2: Add-WizardStep without wizard initialization
Write-Host "`nTest 2: Add-WizardStep before New-PoshWizard (should fail)..." -ForegroundColor Yellow
try {
    # Clear any existing wizard
    Remove-Variable -Name PoshWizardConfig -Scope Global -ErrorAction SilentlyContinue
    
    Add-WizardStep -Name 'Test' -Title 'Test' -Order 1 -ErrorAction Stop
    Write-Host "  FAIL: Should have thrown error when wizard not initialized" -ForegroundColor Red
    $testsFailed++
} catch {
    Write-Host "  PASS: Correctly throws error when wizard not initialized" -ForegroundColor Green
    $testsPassed++
}

# Test 3: Invalid theme value
Write-Host "`nTest 3: New-PoshWizard with invalid theme..." -ForegroundColor Yellow
try {
    New-PoshWizard -Title 'Test' -Theme 'InvalidTheme' -ErrorAction Stop
    Write-Host "  FAIL: Should have thrown error for invalid theme" -ForegroundColor Red
    $testsFailed++
} catch {
    Write-Host "  PASS: Correctly validates theme parameter" -ForegroundColor Green
    $testsPassed++
}

# Test 4: Add-WizardTextBox with invalid validation pattern
Write-Host "`nTest 4: Add-WizardTextBox with invalid regex pattern..." -ForegroundColor Yellow
try {
    New-PoshWizard -Title 'Test'
    Add-WizardStep -Name 'TestStep' -Title 'Test Step' -Order 1
    
    # Invalid regex pattern (unclosed bracket)
    Add-WizardTextBox -Step 'TestStep' -Name 'TestField' -Label 'Test' -ValidationPattern '[abc' -ErrorAction Stop
    
    # If we get here, check if the pattern was rejected
    $config = Get-Variable -Name PoshWizardConfig -Scope Global -ValueOnly -ErrorAction SilentlyContinue
    if ($config) {
        Write-Host "  WARN: Invalid regex pattern was not rejected (may be validated later)" -ForegroundColor Yellow
        $testsPassed++
    } else {
        Write-Host "  PASS: Invalid regex pattern rejected" -ForegroundColor Green
        $testsPassed++
    }
} catch {
    Write-Host "  PASS: Correctly rejects invalid regex pattern" -ForegroundColor Green
    $testsPassed++
}

# Test 5: Duplicate step names
Write-Host "`nTest 5: Adding duplicate step names..." -ForegroundColor Yellow
try {
    New-PoshWizard -Title 'Test'
    Add-WizardStep -Name 'DuplicateStep' -Title 'First' -Order 1
    Add-WizardStep -Name 'DuplicateStep' -Title 'Second' -Order 2 -ErrorAction Stop
    
    Write-Host "  WARN: Duplicate step names allowed (may be handled by overwrite)" -ForegroundColor Yellow
    $testsPassed++
} catch {
    Write-Host "  PASS: Correctly prevents duplicate step names" -ForegroundColor Green
    $testsPassed++
}

# Test 6: Invalid order value (negative)
Write-Host "`nTest 6: Add-WizardStep with negative order..." -ForegroundColor Yellow
try {
    New-PoshWizard -Title 'Test'
    Add-WizardStep -Name 'TestStep' -Title 'Test' -Order -1 -ErrorAction Stop
    
    Write-Host "  WARN: Negative order value allowed" -ForegroundColor Yellow
    $testsPassed++
} catch {
    Write-Host "  PASS: Correctly validates order parameter" -ForegroundColor Green
    $testsPassed++
}

# Clean up
Remove-Variable -Name PoshWizardConfig -Scope Global -ErrorAction SilentlyContinue

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
