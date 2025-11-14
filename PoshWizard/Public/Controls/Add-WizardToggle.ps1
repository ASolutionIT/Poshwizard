function Add-WizardToggle {
    <#
    .SYNOPSIS
    Adds a toggle switch control to a wizard step.
    
    .DESCRIPTION
    Creates a toggle switch (styled checkbox) for boolean on/off states.
    Visually distinct from standard checkboxes with a sliding toggle appearance.
    
    .PARAMETER Step
    Name of the step to add this control to. The step must already exist.
    
    .PARAMETER Name
    Unique name for the control. This becomes the parameter name in the generated script.
    
    .PARAMETER Label
    Display label shown next to the toggle switch.
    
    .PARAMETER DefaultValue
    Default state of the toggle (on/off, true/false).
    
    .PARAMETER Width
    Preferred width of the control in pixels.
    
    .PARAMETER HelpText
    Help text or tooltip to display for this control.
    
    .EXAMPLE
    Add-WizardToggle -Step "Config" -Name "EnableDebug" -Label "Enable Debug Mode" -DefaultValue $false
    
    Adds a toggle switch for enabling debug mode, defaulting to off.
    
    .EXAMPLE
    Add-WizardToggle -Step "Features" -Name "AdvancedMode" -Label "Advanced Features" -DefaultValue $true
    
    Adds a toggle switch that defaults to on.
    
    .OUTPUTS
    WizardControl object representing the created toggle switch.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Step,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Label,
        
        [Parameter()]
        [bool]$DefaultValue = $false,
        
        [Parameter()]
        [int]$Width,
        
        [Parameter()]
        [string]$HelpText
    )
    
    begin {
        Write-Verbose "Adding Toggle control: $Name to step: $Step"
        
        if (-not $script:CurrentWizard) {
            throw "No wizard initialized. Call New-PoshWizard first."
        }
        
        if (-not $script:CurrentWizard.HasStep($Step)) {
            throw "Step '$Step' does not exist. Add the step first using Add-WizardStep."
        }
    }
    
    process {
        try {
            $wizardStep = $script:CurrentWizard.GetStep($Step)
            
            if ($wizardStep.HasControl($Name)) {
                throw "Control with name '$Name' already exists in step '$Step'"
            }
            
            # Create the control as a toggle (switch type)
            $control = [WizardControl]::new($Name, $Label, 'Toggle')
            $control.Default = $DefaultValue.ToString().ToLower()
            $control.HelpText = $HelpText
            $control.Width = $Width
            
            # Mark as switch type for proper rendering
            $control.SetProperty('IsSwitch', $true)
            
            # Add to step
            $wizardStep.AddControl($control)
            
            Write-Verbose "Successfully added Toggle control: $($control.ToString())"
            
            return $control
        }
        catch {
            Write-Error "Failed to add Toggle control '$Name' to step '$Step': $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        Write-Verbose "Add-WizardToggle completed for: $Name"
    }
}

