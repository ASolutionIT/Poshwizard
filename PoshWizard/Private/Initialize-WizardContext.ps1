# Initialize-WizardContext.ps1 - Internal context management functions

function Initialize-WizardContext {
    <#
    .SYNOPSIS
    Initializes the wizard context and validates the environment.
    
    .DESCRIPTION
    Internal function that sets up the wizard execution environment,
    validates dependencies, and prepares for wizard execution.
    
    .PARAMETER Wizard
    The WizardDefinition object to initialize context for.
    
    .OUTPUTS
    Hashtable containing the initialized context.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [WizardDefinition]$Wizard
    )
    
    Write-Verbose "Initializing wizard context for: $($Wizard.Title)"
    
    try {
        # Validate wizard definition
        $validation = $Wizard.Validate()
        if (-not $validation.IsValid) {
            $errorMessage = "Wizard validation failed:`n" + ($validation.Errors -join "`n")
            throw $errorMessage
        }
        
        # Log warnings if any
        if ($validation.Warnings.Count -gt 0) {
            foreach ($warning in $validation.Warnings) {
                Write-Warning $warning
            }
        }
        
        # Check for PoshWizard executable
        $exePath = Join-Path $script:ModuleRoot "bin\PoshWizard.exe"
        if (-not (Test-Path $exePath)) {
            throw "PoshWizard executable not found at: $exePath"
        }
        
        # Create context object
        $context = @{
            Wizard = $Wizard
            ExecutablePath = $exePath
            TempDirectory = [System.IO.Path]::GetTempPath()
            StartTime = Get-Date
            SessionId = [System.Guid]::NewGuid().ToString()
        }
        
        Write-Verbose "Wizard context initialized successfully"
        Write-Verbose "Executable: $($context.ExecutablePath)"
        Write-Verbose "Session ID: $($context.SessionId)"
        
        return $context
    }
    catch {
        Write-Error "Failed to initialize wizard context: $($_.Exception.Message)"
        throw
    }
}

function Clear-WizardContext {
    <#
    .SYNOPSIS
    Cleans up wizard context and temporary resources.
    
    .DESCRIPTION
    Internal function that performs cleanup after wizard execution,
    removing temporary files and resetting context variables.
    
    .PARAMETER Context
    The context object to clean up.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Context
    )
    
    Write-Verbose "Cleaning up wizard context"
    
    try {
        if ($Context -and $Context.ContainsKey('TempFiles')) {
            foreach ($tempFile in $Context.TempFiles) {
                # Use SECURE removal function
                Remove-SecureTempScript -Path $tempFile
                Write-Verbose "Securely removed temp file: $tempFile"
            }
        }
        
        # Clear module-level variables if needed
        if ($Context -and $Context.ContainsKey('SessionId')) {
            Write-Verbose "Cleaned up session: $($Context.SessionId)"
        }
    }
    catch {
        Write-Warning "Error during context cleanup: $($_.Exception.Message)"
    }
}

