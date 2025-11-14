function New-PoshWizard {
    <#
    .SYNOPSIS
    Initializes a new PoshWizard definition.
    
    .DESCRIPTION
    Creates a new wizard context that can be populated with steps and controls using other PoshWizard functions.
    This function must be called before adding any steps or controls to the wizard.
    
    .PARAMETER Title
    The title of the wizard that will be displayed in the window title bar.
    
    .PARAMETER Description
    Optional description of the wizard's purpose.
    
    .PARAMETER Icon
    Optional path to an icon file (PNG, ICO) to display in the wizard.
    Can also be a Segoe MDL2 icon glyph in the format '&#xE1D3;' (e.g., Database icon).
    
    .PARAMETER SidebarHeaderText
    Optional text to display in the sidebar header for branding.
    
    .PARAMETER SidebarHeaderIcon
    Optional icon for the sidebar header. Can be a file path or Segoe MDL2 glyph (e.g., '&#xE1D3;').

    .PARAMETER SidebarHeaderIconOrientation
    Optional orientation for the sidebar icon relative to the text. Supported values: Left (default), Right, Top, Bottom.
    
    .PARAMETER Theme
    The theme to use for the wizard UI. Valid values are 'Light', 'Dark', or 'Auto'.
    Default is 'Auto' which follows the system theme.
    
    .PARAMETER AllowCancel
    Whether to allow users to cancel the wizard. Default is $true.
    
    .EXAMPLE
    New-PoshWizard -Title "Server Configuration Wizard"
    
    Creates a new wizard with the specified title.
    
    .EXAMPLE
    New-PoshWizard -Title "Database Setup" -Description "Configure database connection settings" -Theme Dark
    
    Creates a new wizard with title, description, and dark theme.
    
    .OUTPUTS
    WizardDefinition object representing the initialized wizard.
    
    .NOTES
    This function initializes the module-level $script:CurrentWizard variable that is used by other PoshWizard functions.
    #>
    [CmdletBinding()]
    # [OutputType([WizardDefinition])] # Commented out to avoid type loading issues
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        
        [Parameter()]
        [string]$Description,
        
        [Parameter()]
        [string]$Icon,
        
        [Parameter()]
        [string]$SidebarHeaderText,
        
        [Parameter()]
        [string]$SidebarHeaderIcon,
        
        [Parameter()]
        [ValidateSet('Left', 'Right', 'Top', 'Bottom')]
        [string]$SidebarHeaderIconOrientation = 'Left',
        
        [Parameter()]
        [ValidateSet('Light', 'Dark', 'Auto')]
        [string]$Theme = 'Auto',
        
        [Parameter()]
        [bool]$AllowCancel = $true
    )
    
    begin {
        Write-Verbose "Creating new PoshWizard: $Title"
    }
    
    process {
        try {
            # Create new wizard definition
            $wizard = [WizardDefinition]::new($Title)
            $wizard.Description = $Description
            $wizard.Icon = $Icon
            $wizard.SidebarHeaderText = $SidebarHeaderText
            $wizard.SidebarHeaderIcon = $SidebarHeaderIcon
            $wizard.SidebarHeaderIconOrientation = $SidebarHeaderIconOrientation
            $wizard.Theme = $Theme
            $wizard.AllowCancel = $AllowCancel
            
            # Store as current wizard for other functions to use
            $script:CurrentWizard = $wizard
            
            Write-Verbose "Successfully created wizard: $($wizard.ToString())"
            
            # Return the wizard object to support method chaining
            return $wizard
        }
        catch {
            Write-Error "Failed to create wizard: $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        Write-Verbose "New-PoshWizard completed"
    }
}

