function Add-WizardFilePath {
    <#
    .SYNOPSIS
    Adds a file path selector control to the current wizard step.
    
    .DESCRIPTION
    Creates a text input with a browse button that allows users to select a file path.
    The control includes a "..." button that opens a file picker dialog.
    
    .PARAMETER Name
    Unique name for the control. This becomes the PowerShell parameter name.
    
    .PARAMETER Label
    Display label shown above the control.
    
    .PARAMETER Default
    Optional default file path value.
    
    .PARAMETER Mandatory
    Whether this field is required. Default is $false.
    
    .PARAMETER Filter
    File filter for the browse dialog (simple extension format).
    Examples: "*.ps1" or "*.log;*.txt"
    Note: Automatically converted to dialog format with description
    
    .PARAMETER DialogTitle
    Custom title for the file picker dialog.
    
    .PARAMETER ValidateExists
    Whether to validate that the selected file exists before allowing progression.
    
    .PARAMETER HelpText
    Optional help text displayed as a tooltip.
    
    .EXAMPLE
    Add-WizardFilePath -Name "ConfigFile" -Label "Configuration File" -DefaultValue "C:\config.json"
    
    Adds a file path selector with a default value.
    
    .EXAMPLE
    Add-WizardFilePath -Name "ScriptPath" -Label "PowerShell Script" -Mandatory
    
    Adds a required file path selector.
    
    .OUTPUTS
    WizardControl object representing the file path selector.
    
    .NOTES
    This function requires that a wizard step has been added first using Add-WizardStep.
    Generates a [WizardPathSelector('File')] attribute in the output script.
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
        [string]$Default,
        
        [Parameter()]
        [switch]$Mandatory,
        
        [Parameter()]
        [string]$Filter = "All Files|*.*",
        
        [Parameter()]
        [string]$DialogTitle,
        
        [Parameter()]
        [switch]$ValidateExists,
        
        [Parameter()]
        [string]$HelpText
    )
    
    begin {
        Write-Verbose "Adding file path selector: $Name ($Label) to step: $Step"
        
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
            
            $control = [WizardControl]::new($Name, $Label, 'FilePath')
            $control.Default = $Default
            $control.Mandatory = $Mandatory.IsPresent
            $control.HelpText = $HelpText
            
            # Set path-specific properties
            if ($PSBoundParameters.ContainsKey('Filter')) {
                $control.SetProperty('Filter', $Filter)
            }
            if ($PSBoundParameters.ContainsKey('DialogTitle')) {
                $control.SetProperty('DialogTitle', $DialogTitle)
            }
            if ($ValidateExists.IsPresent) {
                $control.SetProperty('ValidateExists', $true)
            }
            
            $wizardStep.AddControl($control)
            
            Write-Verbose "Successfully added file path selector: $Name"
            return $control
        }
        catch {
            Write-Error "Failed to add file path selector '$Name': $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        Write-Verbose "Add-WizardFilePath completed for: $Name"
    }
}

