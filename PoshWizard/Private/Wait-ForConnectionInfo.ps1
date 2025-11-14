function Wait-ForConnectionInfo {
    <#
    .SYNOPSIS
    Waits for connection information from PoshWizard.exe process

    .DESCRIPTION
    Monitors the stdout of PoshWizard.exe process to extract pipe name and session secret
    that are output when sequential mode starts.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process,
        
        [Parameter()]
        [int]$TimeoutSeconds = 10
    )
    
    $startTime = Get-Date
    $connectionInfo = @{}
    
    try {
        Write-Verbose "Waiting for connection information from PoshWizard process..."
        
        # Preferred path: temp file written by WPF app
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ("poshwizard_connection_{0}.txt" -f $Process.Id)
        Write-Verbose "Looking for connection file: $tempFile"
        
        while ((Get-Date).Subtract($startTime).TotalSeconds -lt $TimeoutSeconds) {
            # Check if process has exited
            if ($Process.HasExited) {
                $stderr = $Process.StandardError.ReadToEnd()
                throw "PoshWizard process exited unexpectedly. Exit code: $($Process.ExitCode). Error: $stderr"
            }
            
            # Try file-based discovery first
            if (Test-Path $tempFile) {
                try {
                    $json = Get-Content $tempFile -Raw -ErrorAction Stop
                    $obj = $json | ConvertFrom-Json
                    if ($obj -and $obj.PipeName -and $obj.SessionSecret -and $obj.ProcessId) {
                        $connectionInfo.PipeName = [string]$obj.PipeName
                        $connectionInfo.SessionSecret = [string]$obj.SessionSecret
                        $connectionInfo.ProcessId = [int]$obj.ProcessId
                        Write-Verbose "Extracted from file - Pipe: $($connectionInfo.PipeName); PID: $($connectionInfo.ProcessId)"
                        Write-Verbose "All connection information received"
                        return $connectionInfo
                    }
                }
                catch {
                    Write-Verbose "Failed to parse connection file: $($_.Exception.Message)"
                }
            }
            
            # Skip stdout parsing to avoid blocking; WPF app writes connection info to a temp file
            
            Start-Sleep -Milliseconds 100
        }
        
        # Timeout reached
        $stderr = ""
        try {
            $stderr = $Process.StandardError.ReadToEnd()
        } catch { }
        
        throw "Timeout waiting for connection information from PoshWizard.exe. Stderr: $stderr"
    }
    catch {
        Write-Error "Error waiting for connection info: $($_.Exception.Message)"
        throw
    }
}

