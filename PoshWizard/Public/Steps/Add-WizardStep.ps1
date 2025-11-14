function Add-WizardStep {
    <#
    .SYNOPSIS
    Adds a new step to the current wizard.
    
    .DESCRIPTION
    Creates a new wizard step that can contain controls and defines the structure of the wizard.
    Steps are displayed in order and can be of different types (GenericForm or Card).
    
    .PARAMETER Name
    Unique name for the step. This is used internally to reference the step.
    
    .PARAMETER Title
    Display title for the step shown in the sidebar and step header.
    
    .PARAMETER Description
    Optional description displayed below the title.
    
    .PARAMETER Order
    Numeric order for the step. Steps are displayed in ascending order.
    If not specified, steps are ordered by the sequence they are added.
    
    .PARAMETER Type
    Type of step to create. Valid values:
    - GenericForm: Standard input form (default) - supports controls and cards
    - Card: Information display page - primarily for cards
    
    .PARAMETER Icon
    Optional icon for the step in the sidebar. Must be a Segoe MDL2 icon glyph.
    Format: '&#xE1D3;' (e.g., '&#xE968;' for Network, '&#xE72E;' for Shield)
    Note: Image file paths are NOT supported for sidebar step icons.
    See Docs/FLUENT_ICONS_REFERENCE.md for available glyphs.
    
    .PARAMETER Skippable
    Whether this step can be skipped by the user.
    
    .EXAMPLE
    Add-WizardStep -Name "ServerConfig" -Title "Server Configuration" -Order 1
    
    Adds a basic input form step.
    
    .EXAMPLE
    Add-WizardStep -Name "Welcome" -Title "Welcome" -Order 1 -Icon "&#xE8BC;" -Description "Get started"
    
    Adds a welcome step with a home icon.
    
    .OUTPUTS
    WizardStep object representing the created step.
    
    .NOTES
    This function requires that New-PoshWizard has been called first to initialize the wizard context.
    #>
    [CmdletBinding()]
    # [OutputType([WizardStep])] # Commented out to avoid type loading issues
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        
        [Parameter()]
        [string]$Description,
        
        [Parameter()]
        [int]$Order,
        
        [Parameter()]
        [ValidateSet('GenericForm', 'Card')]
        [string]$Type = 'GenericForm',
        
        [Parameter()]
        [string]$Icon,
        
        [Parameter()]
        [switch]$Skippable
    )
    
    begin {
        Write-Verbose "Adding wizard step: $Name ($Title)"
        
        # Ensure wizard is initialized
        if (-not $script:CurrentWizard) {
            throw "No wizard initialized. Call New-PoshWizard first."
        }
    }
    
    process {
        try {
            # Auto-assign order if not specified
            if (-not $PSBoundParameters.ContainsKey('Order')) {
                $Order = $script:CurrentWizard.Steps.Count + 1
            }
            
            # Check for duplicate step name
            if ($script:CurrentWizard.HasStep($Name)) {
                throw "Step with name '$Name' already exists"
            }
            
            # Create new step
            $step = [WizardStep]::new($Name, $Title, $Order)
            $step.Description = $Description
            $step.Type = $Type
            $step.Icon = $Icon
            $step.Skippable = $Skippable.IsPresent
            
            # Add to wizard
            $script:CurrentWizard.AddStep($step)
            
            Write-Verbose "Successfully added step: $($step.ToString())"
            
            # Return the step object to support method chaining
            return $step
        }
        catch {
            Write-Error "Failed to add wizard step '$Name': $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        Write-Verbose "Add-WizardStep completed for: $Name"
    }
}

