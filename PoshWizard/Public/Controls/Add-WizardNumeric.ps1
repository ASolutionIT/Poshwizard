function Add-WizardNumeric {
    <#
    .SYNOPSIS
    Adds a numeric input control to a wizard step.

    .DESCRIPTION
    Creates a numeric spinner that enforces optional minimum/maximum bounds and step size.

    .PARAMETER Step
    Name of the step to add this control to. The step must already exist.

    .PARAMETER Name
    Unique name for the control. This becomes the parameter name in the generated script.

    .PARAMETER Label
    Display label shown next to the numeric input.

    .PARAMETER Default
    Default numeric value. Must respect the specified minimum/maximum if provided.

    .PARAMETER Minimum
    Lowest permissible value. Leave unset for no lower bound.

    .PARAMETER Maximum
    Highest permissible value. Leave unset for no upper bound.

    .PARAMETER Step
    Increment used by the spinner buttons. Defaults to 1 for integers or 0.1 when -AllowDecimal is specified.

    .PARAMETER AllowDecimal
    Allow non-integer values. When omitted the wizard coerces to whole numbers.
    
    .PARAMETER Format
    Display format string for the number.
    Examples: "C2" (currency with 2 decimals), "P0" (percentage), "N2" (number with 2 decimals)

    .PARAMETER Mandatory
    Whether a value is required. Users cannot proceed without entering a value.

    .PARAMETER Width
    Preferred width of the control in pixels.

    .PARAMETER HelpText
    Help text or tooltip to display for this control.

    .EXAMPLE
    Add-WizardNumeric -Step "Config" -Name "CpuCount" -Label "CPU Cores" -Minimum 1 -Maximum 32 -Default 4

    Adds an integer numeric input allowing 1-32 cores with a default of 4.

    .OUTPUTS
    WizardControl object representing the created numeric control.

    .NOTES
    This function requires that the specified step exists in the current wizard.
    Numeric controls generate [double] parameters decorated with [WizardNumeric].
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
        [Nullable[double]]$Default,

        [Parameter()]
        [Nullable[double]]$Minimum,

        [Parameter()]
        [Nullable[double]]$Maximum,

        [Parameter()]
        [Nullable[double]]$StepSize,

        [Parameter()]
        [switch]$AllowDecimal,
        
        [Parameter()]
        [string]$Format,

        [Parameter()]
        [switch]$Mandatory,

        [Parameter()]
        [int]$Width,

        [Parameter()]
        [string]$HelpText
    )

    begin {
        Write-Verbose "Adding Numeric control: $Name to step: $Step"

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

            if ($Minimum.HasValue -and $Maximum.HasValue -and $Minimum.Value -gt $Maximum.Value) {
                throw "Minimum value $Minimum cannot exceed maximum value $Maximum."
            }

            # Determine the step size for the numeric spinner
            if ($PSBoundParameters.ContainsKey('StepSize')) {
                if ($StepSize.HasValue) {
                    $calculatedStep = [double]$StepSize.Value
                } else {
                    # StepSize parameter was passed but is null - use default
                    $calculatedStep = if ($AllowDecimal.IsPresent) { 0.1 } else { 1.0 }
                }
            } else {
                # StepSize parameter not provided - use default based on AllowDecimal
                $calculatedStep = if ($AllowDecimal.IsPresent) { 0.1 } else { 1.0 }
            }

            if ($calculatedStep -le 0) {
                throw "Step size must be greater than 0."
            }

            if ($Default.HasValue) {
                if ($Minimum.HasValue -and $Default.Value -lt $Minimum.Value) {
                    throw "Default value $($Default.Value) is below the minimum $($Minimum.Value)."
                }
                if ($Maximum.HasValue -and $Default.Value -gt $Maximum.Value) {
                    throw "Default value $($Default.Value) exceeds the maximum $($Maximum.Value)."
                }
                if (-not $AllowDecimal.IsPresent -and ($Default.Value % 1) -ne 0) {
                    throw "Default value must be an integer when -AllowDecimal is not specified."
                }
            }

            $control = [WizardControl]::new($Name, $Label, 'Numeric')
            if ($Default.HasValue) {
                $control.Default = $Default.Value
            }
            $control.Mandatory = $Mandatory.IsPresent
            $control.HelpText = $HelpText
            $control.Width = $Width

            if ($PSBoundParameters.ContainsKey('Minimum')) { 
                $control.SetProperty('Minimum', [double]$Minimum) 
                Write-Verbose "Minimum set to $Minimum for '$Name'"
            }
            if ($PSBoundParameters.ContainsKey('Maximum')) { 
                $control.SetProperty('Maximum', [double]$Maximum) 
                Write-Verbose "Maximum set to $Maximum for '$Name'"
            }
            if ($calculatedStep) { $control.SetProperty('Step', $calculatedStep) }
            $control.SetProperty('AllowDecimal', [bool]$AllowDecimal.IsPresent)
            
            if ($PSBoundParameters.ContainsKey('Format') -and -not [string]::IsNullOrWhiteSpace($Format)) {
                $control.SetProperty('Format', $Format)
                Write-Verbose "Number format set to '$Format' for '$Name'"
            }

            $wizardStep.AddControl($control)

            Write-Verbose "Successfully added Numeric control: $($control.ToString())"
            return $control
        }
        catch {
            Write-Error "Failed to add Numeric control '$Name' to step '$Step': $($_.Exception.Message)"
            throw
        }
    }

    end {
        Write-Verbose "Add-WizardNumeric completed for: $Name"
    }
}

