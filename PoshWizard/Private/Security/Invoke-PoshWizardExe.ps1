function Invoke-PoshWizardExe {
    <#
    .SYNOPSIS
        Safely invokes the PoshWizard.exe with a script file.
    
    .DESCRIPTION
        Executes PoshWizard.exe with proper security checks:
        - Validates exe path exists
        - Verifies code signature (if signature mode enabled)
        - Uses proper argument escaping
        - Returns exit code
        
        This function ensures the exe invocation is secure and doesn't
        introduce command injection vulnerabilities.
    
    .PARAMETER ScriptPath
        Full path to the PowerShell script to execute
    
    .PARAMETER AppDebug
        If specified, enables debug mode in PoshWizard.exe
    
    .PARAMETER Wait
        If specified, waits for the wizard to complete
    
    .OUTPUTS
        [PSCustomObject] Object with ExitCode and Output properties
    
    .EXAMPLE
        $result = Invoke-PoshWizardExe -ScriptPath "C:\Temp\wizard.ps1" -Wait
        if ($result.ExitCode -eq 0) {
            Write-Host "Output: $($result.Output)"
        }
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Script file not found: $_"
            }
            if ($_ -notmatch '\.ps1$') {
                throw "File must have .ps1 extension: $_"
            }
            $true
        })]
        [string]$ScriptPath,
        
        [Parameter()]
        [switch]$AppDebug,
        
        [Parameter()]
        [switch]$Wait
    )
    
    try {
        # Get exe path relative to module root
        $modulePath = $script:ModuleRoot
        if (-not $modulePath) {
            $modulePath = Split-Path $PSScriptRoot -Parent
        }
        
        # Try multiple possible exe locations
        $exePaths = @(
            (Join-Path $modulePath 'bin\PoshWizard.exe'),
            (Join-Path $modulePath '..\Launcher\bin\Release\PoshWizard.exe'),
            (Join-Path $modulePath '..\Launcher\bin\Debug\PoshWizard.exe')
        )
        
        $exePath = $null
        foreach ($path in $exePaths) {
            if (Test-Path $path) {
                $exePath = $path
                Write-Verbose "Found PoshWizard.exe at: $exePath"
                break
            }
        }
        
        if (-not $exePath) {
            throw "PoshWizard.exe not found. Searched locations:`n" + ($exePaths -join "`n")
        }
        
        # Verify exe signature if signature mode is enabled
        $signatureMode = $env:POSHWIZARD_SIGNATURE_MODE
        if ($signatureMode -eq 'Enforce') {
            Write-Verbose "Signature mode is Enforce, verifying exe signature..."
            
            $signature = Get-AuthenticodeSignature -FilePath $exePath -ErrorAction Stop
            if ($signature.Status -ne 'Valid') {
                throw "PoshWizard.exe signature is invalid. Status: $($signature.Status). Cannot execute in Enforce mode."
            }
            
            Write-Verbose "Exe signature verified: $($signature.SignerCertificate.Subject)"
        } elseif ($signatureMode -eq 'Warn') {
            Write-Verbose "Signature mode is Warn, checking exe signature..."
            
            $signature = Get-AuthenticodeSignature -FilePath $exePath -ErrorAction SilentlyContinue
            if ($signature -and $signature.Status -ne 'Valid') {
                Write-Warning "PoshWizard.exe signature is invalid. Status: $($signature.Status). Proceeding anyway (Warn mode)."
            }
        }
        
        # Build argument list safely (no string concatenation)
        $arguments = [System.Collections.Generic.List[string]]::new()
        $arguments.Add($ScriptPath)
        
        if ($AppDebug) {
            $arguments.Add('--debug')
        }
        
        Write-Verbose "Invoking PoshWizard.exe with arguments: $($arguments -join ' ')"
        
        # Execute the process
        if ($Wait) {
            # Create a temp file to capture stdout
            $outputFile = [System.IO.Path]::GetTempFileName()
            Write-Verbose "Output will be captured to: $outputFile"
            
            $process = Start-Process -FilePath $exePath `
                                    -ArgumentList $arguments `
                                    -Wait `
                                    -PassThru `
                                    -RedirectStandardOutput $outputFile `
                                    -NoNewWindow `
                                    -ErrorAction Stop
            
            $exitCode = $process.ExitCode
            Write-Verbose "PoshWizard.exe exited with code: $exitCode"
            
            # Read captured output
            $output = $null
            if (Test-Path $outputFile) {
                $output = Get-Content $outputFile -Raw
                Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
                Write-Verbose "Captured output length: $($output.Length) characters"
            }
            
            # Return structured result
            return [PSCustomObject]@{
                ExitCode = $exitCode
                Output = $output
            }
        } else {
            # Non-blocking execution
            Start-Process -FilePath $exePath `
                         -ArgumentList $arguments `
                         -ErrorAction Stop
            
            Write-Verbose "PoshWizard.exe launched (non-blocking)"
            return [PSCustomObject]@{
                ExitCode = 0
                Output = $null
            }
        }
        
    } catch {
        Write-Error "Failed to invoke PoshWizard.exe: $_"
        throw
    }
}

