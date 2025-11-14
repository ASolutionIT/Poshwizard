function Add-WizardCard {
    <#
    .SYNOPSIS
    Adds an informational card control to a wizard step.
    
    .DESCRIPTION
    Creates a card control that displays formatted text, instructions, or information.
    Cards are rendered as visually distinct panels and are perfect for providing
    context, guidelines, warnings, or helpful tips within a wizard step.
    
    .PARAMETER Step
    Name of the step to add this card to. The step must already exist.
    
    .PARAMETER Name
    Unique name for the card. This is used internally to reference the card.
    
    .PARAMETER Title
    Title displayed at the top of the card.
    
    .PARAMETER Content
    The main content text to display in the card. Supports multi-line text.
    Best practice: Use here-strings (@"..."@) for multi-line content instead of backtick-n.
    You can use bullet points (•), numbers, and formatting for better readability.
    
    .PARAMETER Icon
    Optional icon to display in the card header. Can be:
    - Segoe MDL2 icon glyph in format '&#xE1D3;' (e.g., '&#xE946;' for Info)
    - Emoji characters (e.g., '📋', '💡', '⚠️')
    
    .EXAMPLE
    Add-WizardCard -Step "Config" -Name "InfoCard" -Title "Important Information" -Content @"
Please read the following guidelines before proceeding:

• Requirement 1
• Requirement 2
• Requirement 3
"@
    
    Adds a simple informational card with bullet points using here-string.
    
    .EXAMPLE
    Add-WizardCard -Step "Setup" -Name "TipsCard" -Title "💡 Pro Tips" -Content @"
Here are some tips for optimal configuration:

1. Use strong passwords
2. Enable backup options
3. Test before deploying
"@
    
    Adds a tips card with emoji icon and numbered list using here-string.
    
    .EXAMPLE
    Add-WizardCard -Step "Network" -Name "NetworkInfo" -Title "Network Requirements" -Icon "&#xE968;" -Content @"
Ensure the following network requirements are met:

• Port 443 must be open
• DNS resolution configured
• Proxy settings (if applicable)
"@
    
    Adds a card with a Segoe MDL2 network icon using here-string.
    
    .OUTPUTS
    WizardControl object representing the created card.
    
    .NOTES
    This function requires that the specified step exists in the current wizard.
    Cards do not collect user input - they are for display purposes only.
    Cards are rendered at the beginning of the step, before input controls.
    #>
    [CmdletBinding()]
    # [OutputType([WizardControl])] # Commented out to avoid type loading issues
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Step,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        
        [Parameter(Mandatory = $true, Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string]$Content,
        
        [Parameter()]
        [string]$Icon
    )
    
    begin {
        Write-Verbose "Adding Card control: $Name to step: $Step"
        
        # Ensure wizard is initialized
        if (-not $script:CurrentWizard) {
            throw "No wizard initialized. Call New-PoshWizard first."
        }
        
        # Ensure step exists
        if (-not $script:CurrentWizard.HasStep($Step)) {
            throw "Step '$Step' does not exist. Add the step first using Add-WizardStep."
        }
    }
    
    process {
        try {
            # Get the step
            $wizardStep = $script:CurrentWizard.GetStep($Step)
            
            # Check for duplicate control name within the step
            if ($wizardStep.HasControl($Name)) {
                throw "Control with name '$Name' already exists in step '$Step'"
            }
            
            # Create the control
            $control = [WizardControl]::new($Name, $Title, 'Card')
            $control.SetProperty('CardTitle', $Title)
            $control.SetProperty('CardContent', $Content)
            
            if ($Icon) {
                $control.SetProperty('Icon', $Icon)
            }
            
            # Cards don't have a value, they're display-only
            $control.Mandatory = $false
            
            # Add to step
            $wizardStep.AddControl($control)
            
            Write-Verbose "Successfully added Card control: $($control.ToString())"
            Write-Verbose "Title: $Title"
            Write-Verbose "Content length: $($Content.Length) characters"
            
            # Return the control object
            return $control
        }
        catch {
            Write-Error "Failed to add Card control '$Name' to step '$Step': $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        Write-Verbose "Add-WizardCard completed for: $Name"
    }
}

