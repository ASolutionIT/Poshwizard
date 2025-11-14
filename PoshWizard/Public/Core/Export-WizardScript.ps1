function Export-WizardScript {
    <#
    .SYNOPSIS
    Exports the current wizard definition as a traditional parameter-based PowerShell script.
    
    .DESCRIPTION
    Generates a PowerShell script with param() blocks and custom attributes that matches
    the traditional PoshWizard parameter-based format. This is useful for:
    - Debugging wizard definitions
    - Creating standalone wizard scripts
    - Understanding the generated script structure
    - Sharing wizards in traditional format
    
    .PARAMETER OutputPath
    Path where the generated script should be saved. If not specified, returns the script as a string.
    
    .PARAMETER ScriptBody
    Optional script block to include in the generated script.
    If not provided, uses the script body set via Set-WizardScript or a default display script.
    
    .PARAMETER PassThru
    Returns the generated script as a string even when saving to a file.
    
    .EXAMPLE
    $script = Export-WizardScript
    Write-Host $script
    
    Exports the wizard as a string and displays it.
    
    .EXAMPLE
    Export-WizardScript -OutputPath ".\MyWizard.ps1"
    
    Saves the generated script to a file.
    
    .EXAMPLE
    Export-WizardScript -OutputPath ".\MyWizard.ps1" -ScriptBody {
        Write-Host "Custom logic here"
    } -PassThru
    
    Saves to file and returns the script text.
    
    .OUTPUTS
    String containing the generated PowerShell script (if no OutputPath or PassThru is specified).
    
    .NOTES
    This function requires that New-PoshWizard has been called and at least one step has been added.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [scriptblock]$ScriptBody,
        
        [Parameter()]
        [switch]$PassThru
    )
    
    begin {
        Write-Verbose "Starting Export-WizardScript"
        
        # Ensure wizard is initialized
        if (-not $script:CurrentWizard) {
            throw "No wizard initialized. Call New-PoshWizard first."
        }
        
        # Ensure wizard has steps
        if ($script:CurrentWizard.Steps.Count -eq 0) {
            throw "Wizard has no steps. Add at least one step using Add-WizardStep."
        }
    }
    
    process {
        try {
            # Generate the script
            Write-Verbose "Generating PowerShell script from wizard definition"
            $generatedScript = ConvertTo-WizardScript -Definition $script:CurrentWizard -ScriptBody $ScriptBody
            
            if ($OutputPath) {
                # Save to file
                Write-Verbose "Saving script to: $OutputPath"
                $generatedScript | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
                Write-Host "Wizard script exported to: $OutputPath" -ForegroundColor Green
                
                if ($PassThru) {
                    return $generatedScript
                }
            } else {
                # Return as string
                return $generatedScript
            }
        }
        catch {
            Write-Error "Failed to export wizard script: $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        Write-Verbose "Export-WizardScript completed"
    }
}

