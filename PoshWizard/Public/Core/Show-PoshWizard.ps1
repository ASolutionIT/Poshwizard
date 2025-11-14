function Show-PoshWizard {
    <#
    .SYNOPSIS
    Displays the wizard and executes the associated script.
    
    .DESCRIPTION
    Generates a traditional parameter-based script from the current wizard definition,
    launches the PoshWizard executable, and returns the results. This function provides
    the bridge between the module's function-based API and the existing WPF application.
    
    .PARAMETER ScriptBody
    Optional script block containing the logic to execute after collecting user input.
    If not provided, a default script that displays the collected parameters is used.
    
    .PARAMETER DefaultValues
    Hashtable of default values to pre-populate in the wizard form.
    Keys should match the control names.
    
    .PARAMETER NonInteractive
    Run the wizard in non-interactive mode using only the default values.
    The UI will not be displayed.
    
    .PARAMETER ShowConsole
    Whether to show the live execution console during script execution.
    Default is $true.
    
    .PARAMETER Theme
    Override the theme for this wizard execution.
    Valid values are 'Light', 'Dark', or 'Auto'.
    
    .PARAMETER OutputFormat
    Format for the returned results. Valid values are 'Object', 'JSON', 'Hashtable'.
    Default is 'Object'.
    
    .EXAMPLE
    $result = Show-PoshWizard
    
    Shows the wizard with default script body and returns results.
    
    .EXAMPLE
    $result = Show-PoshWizard -ScriptBody {
        Write-Host "Configuring server: $ServerName"
        # Perform configuration tasks
        return @{ Status = 'Success'; Message = 'Configuration completed' }
    }
    
    Shows the wizard with custom script logic.
    
    .EXAMPLE
    $defaults = @{ ServerName = 'SQL01'; Environment = 'Production' }
    $result = Show-PoshWizard -DefaultValues $defaults -ScriptBody $configScript
    
    Shows the wizard with pre-populated default values.
    
    .OUTPUTS
    PSCustomObject containing the wizard results and any return values from the script body.
    
    .NOTES
    This function requires that New-PoshWizard has been called and at least one step has been added.
    The function generates a temporary script file that is automatically cleaned up after execution.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [scriptblock]$ScriptBody,
        
        [Parameter()]
        [hashtable]$DefaultValues = @{},
        
        [Parameter()]
        [switch]$NonInteractive,
        
        [Parameter()]
        [bool]$ShowConsole = $true,
        
        [Parameter()]
        [ValidateSet('Light', 'Dark', 'Auto')]
        [string]$Theme,
        
        [Parameter()]
        [ValidateSet('Object', 'JSON', 'Hashtable')]
        [string]$OutputFormat = 'Object'
    )
    
    begin {
        Write-Verbose "Starting Show-PoshWizard"
        
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
        $context = $null
        $tempScriptPath = $null
        
        try {
            # Initialize context
            $context = Initialize-WizardContext -Wizard $script:CurrentWizard
            
            # Override theme if specified
            if ($PSBoundParameters.ContainsKey('Theme')) {
                $script:CurrentWizard.Theme = $Theme
            }
            
            # Set script body if provided
            if ($ScriptBody) {
                $script:CurrentWizard.SetScriptBody($ScriptBody)
            }
            
            # Capture original calling script name for log file naming
            # This ensures Module API scripts use the calling script name, not the temp script name
            # Look up the call stack to find the first .ps1 file that's NOT in the module directory
            $callingScript = $null
            $callStack = Get-PSCallStack
            Write-Verbose "Examining call stack for original script..."
            foreach ($frame in $callStack) {
                Write-Verbose "  Frame: $($frame.ScriptName) (Function: $($frame.FunctionName))"
                if ($frame.ScriptName -and $frame.ScriptName -match '\.ps1$') {
                    # Skip if it's from the module directory (handle both \ and / path separators)
                    $normalizedPath = $frame.ScriptName -replace '\\','/'
                    if (-not $normalizedPath.Contains('PoshWizard/Public/') -and 
                        -not $normalizedPath.Contains('PoshWizard/Private/') -and
                        -not $normalizedPath.Contains('PoshWizard/Classes/')) {
                        $callingScript = $frame.ScriptName
                        Write-Verbose "  --> Found calling script: $callingScript"
                        break
                    }
                }
            }
            
            if ($callingScript) {
                $originalScriptFullPath = [System.IO.Path]::GetFullPath($callingScript)
                $originalScriptName = [System.IO.Path]::GetFileNameWithoutExtension($originalScriptFullPath)
                $originalScriptDirectory = [System.IO.Path]::GetDirectoryName($originalScriptFullPath)

                # Store it in branding so the exe can use it for log naming and placement
                # Use SetBranding method to ensure it's properly added
                $brandingUpdate = @{ OriginalScriptName = $originalScriptName }
                if ($originalScriptDirectory) {
                    $brandingUpdate.OriginalScriptPath = $originalScriptDirectory
                }
                $script:CurrentWizard.SetBranding($brandingUpdate)
                Write-Verbose "Original script name for logging: $originalScriptName (from $originalScriptFullPath)"
                if ($originalScriptDirectory) {
                    Write-Verbose "Original script directory for logging: $originalScriptDirectory"
                }
            } else {
                Write-Verbose "Could not determine original calling script name from call stack"
            }
            
            # Generate the script
            Write-Verbose "Generating PowerShell script from wizard definition"
            $generatedScript = ConvertTo-WizardScript -Definition $script:CurrentWizard -ScriptBody $ScriptBody
            
            # Create SECURE temporary script file (using security framework)
            Write-Verbose "Creating secure temporary script file"
            $tempScriptPath = New-SecureTempScript -ScriptContent $generatedScript
            
            # Track temp file for cleanup
            if (-not $context.ContainsKey('TempFiles')) {
                $context['TempFiles'] = @()
            }
            $context.TempFiles += $tempScriptPath
            
            # Execute the wizard using SECURE invocation
            Write-Verbose "Invoking PoshWizard.exe with secure execution"
            $result = Invoke-PoshWizardExe -ScriptPath $tempScriptPath -Wait
            
            if ($result.ExitCode -ne 0) {
                throw "Wizard execution failed with exit code: $($result.ExitCode)"
            }
            
            # Check for result file (Module API mode)
            $resultFilePath = [System.IO.Path]::ChangeExtension($tempScriptPath, '.result.json')
            Write-Verbose "Checking for result file: $resultFilePath"
            
            $jsonResult = $null
            if (Test-Path $resultFilePath) {
                Write-Verbose "Result file found, reading contents"
                $jsonResult = Get-Content $resultFilePath -Raw
                # Clean up result file
                Remove-Item $resultFilePath -Force -ErrorAction SilentlyContinue
            }
            elseif ($result.Output) {
                # Fallback to stdout if available
                Write-Verbose "No result file, using stdout"
                $jsonResult = $result.Output.Trim()
            }
            
            # Parse and return results
            if ($jsonResult) {
                Write-Verbose "Raw result: $jsonResult"
                
                # Try to parse as JSON
                try {
                    switch ($OutputFormat) {
                        'JSON' {
                            return $jsonResult
                        }
                        'Hashtable' {
                            $parsedResult = ConvertFrom-Json $jsonResult -ErrorAction Stop
                            $hashtable = @{}
                            $parsedResult.PSObject.Properties | ForEach-Object {
                                $hashtable[$_.Name] = $_.Value
                            }
                            return $hashtable
                        }
                        'Object' {
                            return ConvertFrom-Json $jsonResult -ErrorAction Stop
                        }
                    }
                }
                catch {
                    Write-Warning "Could not parse wizard output as JSON. Returning raw output."
                    Write-Verbose "Parse error: $_"
                    return $jsonResult
                }
            } else {
                Write-Warning "No result returned from wizard execution"
                return $null
            }
        }
        catch {
            Write-Error "Failed to execute wizard: $($_.Exception.Message)"
            throw
        }
        finally {
            # Cleanup
            if ($context) {
                Clear-WizardContext -Context $context
            }
        }
    }
    
    end {
        Write-Verbose "Show-PoshWizard completed"
    }
}

