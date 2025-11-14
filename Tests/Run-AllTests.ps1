<#
.SYNOPSIS
Runs all PoshWizard integration tests.

.DESCRIPTION
Master test runner that executes all integration tests and provides a summary.
Used in CI/CD pipelines and local development.

.PARAMETER SkipInteractive
Skip interactive tests (useful for CI/CD environments).

.EXAMPLE
& .\Run-AllTests.ps1

.EXAMPLE
& .\Run-AllTests.ps1 -SkipInteractive
#>

param(
    [switch]$SkipInteractive
)

$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$integrationDir = Join-Path $testDir 'Integration'

Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  PoshWizard Integration Test Suite     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan

if ($SkipInteractive) {
    Write-Host "Mode: CI/CD (Non-Interactive)`n" -ForegroundColor Yellow
} else {
    Write-Host "Mode: Interactive`n" -ForegroundColor Yellow
}

$totalPassed = 0
$totalFailed = 0
$testFiles = @()

# Find all test files
if (Test-Path $integrationDir) {
    $testFiles = Get-ChildItem -Path $integrationDir -Filter 'Test-*.ps1' -File
} else {
    Write-Host "ERROR: Integration tests directory not found: $integrationDir" -ForegroundColor Red
    exit 1
}

if ($testFiles.Count -eq 0) {
    Write-Host "WARNING: No test files found in $integrationDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($testFiles.Count) test file(s):`n" -ForegroundColor Cyan

# Run each test
foreach ($testFile in $testFiles) {
    Write-Host "Running: $($testFile.Name)" -ForegroundColor Cyan
    Write-Host "─" * 40 -ForegroundColor Gray
    
    try {
        if ($SkipInteractive) {
            & $testFile.FullName -SkipInteractive -ErrorAction Stop
        } else {
            & $testFile.FullName -ErrorAction Stop
        }
        $totalPassed++
    } catch {
        Write-Host "ERROR: Test failed with exception: $_" -ForegroundColor Red
        $totalFailed++
    }
    
    Write-Host ""
}

# Final summary
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Final Test Summary                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "  Total Tests Run: $($testFiles.Count)" -ForegroundColor White
Write-Host "  Passed: $totalPassed" -ForegroundColor Green
Write-Host "  Failed: $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { 'Red' } else { 'Green' })
Write-Host "════════════════════════════════════════`n" -ForegroundColor Cyan

if ($totalFailed -gt 0) {
    Write-Host "RESULT: FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "RESULT: PASSED" -ForegroundColor Green
    exit 0
}
