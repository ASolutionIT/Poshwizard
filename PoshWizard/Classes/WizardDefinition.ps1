# WizardDefinitionSimple.ps1 - Simplified wizard definition class for PowerShell 5.1

class WizardDefinition {
    [string]$Title
    [string]$Description
    [string]$Icon
    [string]$SidebarHeaderText
    [string]$SidebarHeaderIcon
    [string]$SidebarHeaderIconOrientation = 'Left'
    [string]$Theme = 'Auto'
    [bool]$AllowCancel = $true
    [array]$Steps  # Changed from generic List to simple array
    [hashtable]$Branding
    [hashtable]$GlobalActions
    [hashtable]$Variables
    [scriptblock]$ScriptBody
    
    # Constructor
    WizardDefinition() {
        $this.Steps = @()  # Initialize as empty array
        $this.Branding = @{}
        $this.GlobalActions = @{}
        $this.Variables = @{}
    }
    
    WizardDefinition([string]$Title) {
        $this.Title = $Title
        $this.Steps = @()
        $this.Branding = @{}
        $this.GlobalActions = @{}
        $this.Variables = @{}
    }
    
    # Methods
    [void]AddStep([WizardStep]$Step) {
        if ($this.Steps | Where-Object Name -eq $Step.Name) {
            throw "Step with name '$($Step.Name)' already exists"
        }
        $this.Steps += $Step
    }
    
    [WizardStep]GetStep([string]$Name) {
        $step = $this.Steps | Where-Object Name -eq $Name
        if (-not $step) {
            throw "Step with name '$Name' not found"
        }
        return $step
    }
    
    [bool]HasStep([string]$Name) {
        return $null -ne ($this.Steps | Where-Object Name -eq $Name)
    }
    
    [WizardStep]GetCurrentStep() {
        if ($this.Steps.Count -eq 0) {
            return $null
        }
        return $this.Steps[-1]  # Return the most recently added step
    }
    
    [void]SetBranding([hashtable]$BrandingOptions) {
        foreach ($key in $BrandingOptions.Keys) {
            $this.Branding[$key] = $BrandingOptions[$key]
        }
    }
    
    [void]SetScriptBody([scriptblock]$ScriptBody) {
        $this.ScriptBody = $ScriptBody
    }
    
    [hashtable]Validate() {
        $errors = @()
        $warnings = @()
        
        # Validate basic properties
        if ([string]::IsNullOrWhiteSpace($this.Title)) {
            $errors += "Wizard title is required"
        }
        
        # Validate steps
        if ($this.Steps.Count -eq 0) {
            $errors += "At least one step is required"
        }
        
        # Check for duplicate step names
        $stepNames = $this.Steps | Group-Object Name | Where-Object Count -gt 1
        foreach ($duplicate in $stepNames) {
            $errors += "Duplicate step name: '$($duplicate.Name)'"
        }
        
        return @{
            IsValid = ($errors.Count -eq 0)
            Errors = $errors
            Warnings = $warnings
        }
    }
    
    [string]ToString() {
        return "WizardDefinition: '$($this.Title)' ($($this.Steps.Count) steps)"
    }
}

