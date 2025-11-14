#Requires -Version 5.1

# PoshWizard PowerShell Module
# Provides native Verb-Noun API for creating interactive wizards

# Cache module root for downstream scripts
$script:ModuleRoot = $PSScriptRoot

# Resolve file collections explicitly to avoid path parsing issues
$publicFolder  = Join-Path $PSScriptRoot 'Public'
$privateFolder = Join-Path $PSScriptRoot 'Private'
$classesFolder = Join-Path $PSScriptRoot 'Classes'

# Get public function definition files and class scripts
$PublicFunctions = @(Get-ChildItem -Path $publicFolder -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)
$Classes         = @(Get-ChildItem -Path $classesFolder -Filter '*.ps1' -ErrorAction SilentlyContinue)

# Load classes in dependency order (WizardControl first, then WizardStep, then WizardDefinition)
$ClassOrder = @('WizardControl.ps1', 'WizardStep.ps1', 'WizardDefinition.ps1')
foreach ($className in $ClassOrder) {
    $classFile = $Classes | Where-Object { $_.Name -eq $className }
    if ($classFile) {
        try {
            Write-Verbose "Loading class: $($classFile.FullName)"
            . $classFile.FullName
        }
        catch {
            Write-Error -Message "Failed to import class $($classFile.FullName): $_"
        }
    }
}

## Load security functions first (critical for module operation)
$securityFolder = Join-Path $privateFolder 'Security'
if (Test-Path $securityFolder) {
    $securityScripts = @(Get-ChildItem -Path $securityFolder -Filter '*.ps1' -ErrorAction SilentlyContinue)
    foreach ($secScript in $securityScripts) {
        try {
            Write-Verbose "Loading security function: $($secScript.FullName)"
            . $secScript.FullName
        }
        catch {
            Write-Error -Message "Failed to load security function $($secScript.FullName): $_"
            throw  # Security functions are critical
        }
    }
    Write-Verbose "Loaded $($securityScripts.Count) security functions"
}

## Load private helper scripts directly to ensure availability in module scope
$privateScripts = @(
    'Initialize-WizardContext.ps1',
    'ConvertTo-WizardScript.ps1',
    'ArgumentCompleters.ps1',
    'Test-WizardDataSource.ps1',
    'Test-WizardScriptBlockParameters.ps1',
    'Measure-WizardDataSource.ps1'
)

foreach ($scriptName in $privateScripts) {
    $scriptPath = Join-Path $privateFolder $scriptName
    if (Test-Path $scriptPath) {
        try {
            Write-Verbose "Dot-sourcing private helper script: $scriptPath"
            . $scriptPath
        }
        catch {
            Write-Error -Message "Failed to dot-source private helper script '$scriptPath': $($_.Exception.Message)"
            throw
        }
    } else {
        Write-Warning "Private helper script not found at '$scriptPath'."
    }
}

# Load public functions
foreach ($import in $PublicFunctions) {
    try {
        Write-Verbose "Loading public function: $($import.FullName)"
        . $import.FullName
    }
    catch {
        Write-Error -Message "Failed to import public function $($import.FullName): $_"
    }
}

# Module-level variables
$script:CurrentWizard = $null
$script:ModuleRoot = $PSScriptRoot

# Initialize module
Write-Verbose "PoshWizard module loaded. Functions available: $($PublicFunctions.Count)"

# Module cleanup when removed
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Verbose "Cleaning up PoshWizard module"
    $script:CurrentWizard = $null
    $script:ModuleRoot = $null
}

# Export public functions and validation helpers
$FunctionNames = $PublicFunctions | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) }

# Add validation helper functions (loaded from Private but exported for user consumption)
$ValidationHelpers = @('Test-WizardDataSource', 'Test-WizardScriptBlockParameters', 'Measure-WizardDataSource')

# Add security functions for testing
$SecurityHelpers = @('Invoke-PoshWizardExe')

$AllExportedFunctions = $FunctionNames + $ValidationHelpers + $SecurityHelpers

Export-ModuleMember -Function $AllExportedFunctions

# Export aliases if any are defined
# Export-ModuleMember -Alias @()

# ═════════════════════════════════════════════════════════════════════════════
# ARGUMENT COMPLETERS FOR INTELLISENSE
# ═════════════════════════════════════════════════════════════════════════════

# Filter parameter - Common file extensions
$FilterCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $commonFilters = @(
        @{ Value = '*.ps1'; Description = 'PowerShell Scripts' }
        @{ Value = '*.txt'; Description = 'Text Files' }
        @{ Value = '*.log'; Description = 'Log Files' }
        @{ Value = '*.csv'; Description = 'CSV Files' }
        @{ Value = '*.xml'; Description = 'XML Files' }
        @{ Value = '*.json'; Description = 'JSON Files' }
        @{ Value = '*.config'; Description = 'Config Files' }
        @{ Value = '*.exe'; Description = 'Executables' }
        @{ Value = '*.dll'; Description = 'DLL Files' }
        @{ Value = '*.zip'; Description = 'ZIP Archives' }
        @{ Value = '*.log;*.txt'; Description = 'Log and Text Files' }
    )
    
    $commonFilters | Where-Object { $_.Value -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.Value,
            $_.Value,
            'ParameterValue',
            $_.Description
        )
    }
}

Register-ArgumentCompleter -CommandName 'Add-WizardFilePath' -ParameterName 'Filter' -ScriptBlock $FilterCompleter

# Step parameter - Returns existing step names from current wizard
$StepCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    if ($script:CurrentWizard) {
        $script:CurrentWizard.Steps.Keys | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_,
                $_,
                'ParameterValue',
                "Step: $_"
            )
        }
    }
}

# Register Step parameter completers for all control functions
$controlFunctions = @(
    'Add-WizardTextBox', 'Add-WizardPassword', 'Add-WizardCheckbox', 'Add-WizardToggle',
    'Add-WizardDropdown',
    'Add-WizardListBox', 'Add-WizardFilePath', 'Add-WizardFolderPath', 'Add-WizardNumeric',
    'Add-WizardDate', 'Add-WizardOptionGroup', 'Add-WizardMultiLine', 'Add-WizardCard'
)

foreach ($func in $controlFunctions) {
    Register-ArgumentCompleter -CommandName $func -ParameterName 'Step' -ScriptBlock $StepCompleter
}

Write-Verbose "PoshWizard module initialization complete"
