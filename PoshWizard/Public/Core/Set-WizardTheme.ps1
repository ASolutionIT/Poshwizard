function Set-WizardTheme {
    <#
    .SYNOPSIS
    Sets the visual theme for the wizard.
    
    .DESCRIPTION
    Configures the color scheme for the wizard interface.
    Convenience function that calls Set-WizardBranding internally.
    
    .PARAMETER Theme
    Visual theme: 'Light', 'Dark', or 'Auto' (follows system preference).
    
    .EXAMPLE
    Set-WizardTheme -Theme "Dark"
    
    Sets dark theme for the wizard.
    
    .EXAMPLE
    Set-WizardTheme -Theme "Auto"
    
    Uses system default theme (light or dark based on Windows settings).
    
    .NOTES
    This is a convenience wrapper around Set-WizardBranding.
    For more branding options, use Set-WizardBranding directly.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('Light', 'Dark', 'Auto')]
        [string]$Theme
    )
    
    begin {
        Write-Verbose "Setting wizard theme to: $Theme"
        
        if (-not $script:CurrentWizard) {
            throw "No wizard initialized. Call New-PoshWizard first."
        }
    }
    
    process {
        try {
            # Set theme via branding
            Set-WizardBranding -Theme $Theme
            
            Write-Verbose "Theme set to: $Theme"
        }
        catch {
            Write-Error "Failed to set theme: $($_.Exception.Message)"
            throw
        }
    }
}

