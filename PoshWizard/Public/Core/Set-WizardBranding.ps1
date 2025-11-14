function Set-WizardBranding {
    <#
    .SYNOPSIS
    Configures branding and appearance settings for the wizard.
    
    .DESCRIPTION
    Sets visual customization options including window title, sidebar header, icons, and theme.
    Must be called after New-PoshWizard.
    
    .PARAMETER WindowTitle
    The title displayed in the window title bar.
    
    .PARAMETER SidebarHeaderText
    Text displayed in the sidebar header area.
    
    .PARAMETER SidebarHeaderIcon
    Segoe MDL2 icon glyph for the sidebar header (e.g., '&#xE8BC;').
    
    .PARAMETER SidebarHeaderIconOrientation
    Position of the sidebar icon relative to text: 'Left', 'Right', 'Top', or 'Bottom'.
    
    .PARAMETER ShowSidebarHeaderIcon
    Whether to display the sidebar header icon.
    
    .PARAMETER Theme
    Visual theme: 'Light', 'Dark', or 'Auto' (system default).
    
    .PARAMETER AllowCancel
    Whether users can cancel the wizard (default: $true).
    
    .EXAMPLE
    Set-WizardBranding -WindowTitle "Server Setup" -SidebarHeaderText "Company Name" -SidebarHeaderIcon "&#xE8BC;"
    
    Sets basic branding with custom title and sidebar.
    
    .EXAMPLE
    Set-WizardBranding -WindowTitle "Deployment Wizard" -Theme "Dark" -AllowCancel $false
    
    Sets dark theme and prevents cancellation.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$WindowTitle,
        
        [Parameter()]
        [string]$SidebarHeaderText,
        
        [Parameter()]
        [string]$SidebarHeaderIcon,
        
        [Parameter()]
        [ValidateSet('Left', 'Right', 'Top', 'Bottom')]
        [string]$SidebarHeaderIconOrientation = 'Left',
        
        [Parameter()]
        [bool]$ShowSidebarHeaderIcon = $true,
        
        [Parameter()]
        [ValidateSet('Light', 'Dark', 'Auto')]
        [string]$Theme = 'Auto',
        
        [Parameter()]
        [bool]$AllowCancel = $true
    )
    
    begin {
        Write-Verbose "Configuring wizard branding"
        
        # Ensure wizard is initialized
        if (-not $script:CurrentWizard) {
            throw "No wizard initialized. Call New-PoshWizard first."
        }
    }
    
    process {
        try {
            # Update branding properties
            if ($PSBoundParameters.ContainsKey('WindowTitle')) {
                $script:CurrentWizard.Branding['WindowTitleText'] = $WindowTitle
            }
            
            if ($PSBoundParameters.ContainsKey('SidebarHeaderText')) {
                $script:CurrentWizard.Branding['SidebarHeaderText'] = $SidebarHeaderText
            }
            
            if ($PSBoundParameters.ContainsKey('SidebarHeaderIcon')) {
                $script:CurrentWizard.Branding['SidebarHeaderIconPath'] = $SidebarHeaderIcon
                $script:CurrentWizard.SidebarHeaderIcon = $SidebarHeaderIcon
            }
            
            if ($PSBoundParameters.ContainsKey('SidebarHeaderIconOrientation')) {
                $normalizedOrientation = switch (($SidebarHeaderIconOrientation -as [string]).ToLowerInvariant()) {
                    'right' { 'Right' }
                    'top'   { 'Top' }
                    'bottom' { 'Bottom' }
                    default { 'Left' }
                }
                $script:CurrentWizard.Branding['SidebarHeaderIconOrientation'] = $normalizedOrientation
                $script:CurrentWizard.SidebarHeaderIconOrientation = $normalizedOrientation
            }
            
            if ($PSBoundParameters.ContainsKey('ShowSidebarHeaderIcon')) {
                $script:CurrentWizard.Branding['ShowSidebarHeaderIcon'] = $ShowSidebarHeaderIcon
            }
            
            if ($PSBoundParameters.ContainsKey('Theme')) {
                $script:CurrentWizard.Theme = $Theme
            }
            
            if ($PSBoundParameters.ContainsKey('AllowCancel')) {
                $script:CurrentWizard.AllowCancel = $AllowCancel
            }
            
            Write-Verbose "Branding configured successfully"
        }
        catch {
            Write-Error "Failed to configure branding: $($_.Exception.Message)"
            throw
        }
    }
}

