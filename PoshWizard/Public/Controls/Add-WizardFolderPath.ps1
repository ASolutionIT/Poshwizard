function Add-WizardFolderPath {
    <#
    .SYNOPSIS
    Adds a folder path selector control to the current wizard step.
    
    .DESCRIPTION
    Creates a text input with a browse button that allows users to select a folder path.
    The control includes a "..." button that opens a folder picker dialog.
    
    .PARAMETER Name
    Unique name for the control. This becomes the PowerShell parameter name.
    
    .PARAMETER Label
    Display label shown above the control.
    
    .PARAMETER Default
    Optional default folder path value.
    
    .PARAMETER Mandatory
    Whether this field is required. Default is $false.
    
    .PARAMETER HelpText
    Optional help text displayed as a tooltip.
    
    .EXAMPLE
    Add-WizardFolderPath -Name "DataPath" -Label "Data Folder" -DefaultValue "C:\SQLData"
    
    Adds a folder path selector with a default value.
    
    .EXAMPLE
    Add-WizardFolderPath -Name "BackupPath" -Label "Backup Location" -Mandatory
    
    Adds a required folder path selector.
    
    .OUTPUTS
    WizardControl object representing the folder path selector.
    
    .NOTES
    This function requires that a wizard step has been added first using Add-WizardStep.
    Generates a [WizardPathSelector('Folder')] attribute in the output script.
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
        [string]$HelpText
    )
    
    begin {
        Write-Verbose "Adding folder path selector: $Name ($Label) to step: $Step"
        
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
            
            $control = [WizardControl]::new($Name, $Label, 'FolderPath')
            $control.Default = $Default
            $control.Mandatory = $Mandatory.IsPresent
            $control.HelpText = $HelpText
            
            $wizardStep.AddControl($control)
            
            Write-Verbose "Successfully added folder path selector: $Name"
            return $control
        }
        catch {
            Write-Error "Failed to add folder path selector '$Name': $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        Write-Verbose "Add-WizardFolderPath completed for: $Name"
    }
}

