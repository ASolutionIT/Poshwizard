function Find-PoshWizardExecutable {
    <#
    .SYNOPSIS
    Attempts to locate PoshWizard.exe in common locations

    .DESCRIPTION
    Searches for PoshWizard.exe in various common locations including the module directory,
    current directory, and system paths.
    #>
    [CmdletBinding()]
    param()
    
    # Try module-relative paths first
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $ProjectRoot = Split-Path -Parent $ModuleRoot
    
    $PossiblePaths = @(
        # Relative to module location (development scenario)
        (Join-Path $ProjectRoot "Launcher\bin\Release\Poshwizard.exe"),
        (Join-Path $ProjectRoot "Launcher\bin\Debug\Poshwizard.exe"),
        
        # Current directory
        ".\Launcher\bin\Release\Poshwizard.exe",
        ".\Launcher\bin\Debug\Poshwizard.exe",
        ".\Poshwizard.exe",
        
        # System paths
        (Get-Command "Poshwizard.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
        "$env:ProgramFiles\PoshWizard\Poshwizard.exe",
        "$env:ProgramFiles(x86)\PoshWizard\Poshwizard.exe",
        
        # User profile
        "$env:USERPROFILE\PoshWizard\Poshwizard.exe"
    )
    
    foreach ($Path in $PossiblePaths) {
        if ($Path -and (Test-Path $Path)) {
            $resolvedPath = Resolve-Path $Path
            Write-Verbose "Found PoshWizard.exe at: $resolvedPath"
            return $resolvedPath.Path
        }
    }
    
    Write-Verbose "PoshWizard.exe not found in any common location"
    return $null
}

