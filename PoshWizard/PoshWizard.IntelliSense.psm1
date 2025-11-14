# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              PoshWizard IntelliSense Helper Module                           ║
# ║  Provides IntelliSense for traditional parameter-based wizard scripts        ║
# ║  Import this at the top of your .ps1 wizards for auto-completion            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

<#
.SYNOPSIS
    IntelliSense helper module for PoshWizard traditional scripts.

.DESCRIPTION
    This module provides stub classes and attributes that enable IntelliSense
    for PoshWizard's custom parameter attributes in VS Code and PowerShell ISE.
    
    These are "fake" classes that only exist for IntelliSense - they're replaced
    by the real C# types when the script runs in PoshWizard.exe.

.EXAMPLE
    # At the top of your wizard script:
    using module .\PoshWizard.IntelliSense.psm1
    
    param(
        [WizardPathSelector(File)]
        [string]$ConfigFile,  # Now gets IntelliSense!
        
        [ValidateSet("Dev", "Staging", "Prod")]
        [string]$Environment
    )

.NOTES
    This module is ONLY for IntelliSense support. The actual PoshWizard.exe
    will ignore these classes and use its own C# implementations.
#>

# ═════════════════════════════════════════════════════════════════════════════
# CUSTOM ATTRIBUTE CLASSES (For IntelliSense Only)
# ═════════════════════════════════════════════════════════════════════════════

# WizardStep - Associates a parameter with a wizard step
class WizardStep : System.Attribute {
    [string]$StepName
    [int]$Order
    [string]$IconPath
    [string]$Description
    
    WizardStep([string]$stepName, [int]$order) {
        $this.StepName = $stepName
        $this.Order = $order
    }
    
    WizardStep([string]$stepName, [int]$order, [string]$iconPath) {
        $this.StepName = $stepName
        $this.Order = $order
        $this.IconPath = $iconPath
    }
    
    WizardStep([string]$stepName, [int]$order, [string]$iconPath, [string]$description) {
        $this.StepName = $stepName
        $this.Order = $order
        $this.IconPath = $iconPath
        $this.Description = $description
    }
}

# WizardParameterDetails - Labels, tooltips, and control sizing
class WizardParameterDetails : System.Attribute {
    [string]$Label
    [string]$Tooltip
    [int]$ControlWidth
    [int]$LabelWidth
    
    WizardParameterDetails() {}
    
    WizardParameterDetails([string]$label) {
        $this.Label = $label
    }
}

# WizardMultiLine - Multi-line text box
class WizardMultiLine : System.Attribute {
    [int]$Rows
    [int]$MaxLength
    
    WizardMultiLine() {
        $this.Rows = 4
    }
    
    WizardMultiLine([int]$rows) {
        $this.Rows = $rows
    }
}

# WizardNumeric - Numeric spinner control
class WizardNumeric : System.Attribute {
    [double]$Minimum
    [double]$Maximum
    [double]$Step
    [bool]$AllowDecimal
    
    WizardNumeric() {
        $this.Step = 1
        $this.AllowDecimal = $false
    }
    
    WizardNumeric([double]$minimum, [double]$maximum) {
        $this.Minimum = $minimum
        $this.Maximum = $maximum
        $this.Step = 1
        $this.AllowDecimal = $false
    }
}

# WizardDate - Date picker control
class WizardDate : System.Attribute {
    [string]$Minimum
    [string]$Maximum
    [string]$Format
    
    WizardDate() {
        $this.Format = 'yyyy-MM-dd'
    }
}

# WizardSwitch - Toggle switch control
class WizardSwitch : System.Attribute {
    WizardSwitch() {}
}

# WizardPathSelector - File or Folder picker
class WizardPathSelector : System.Attribute {
    [string]$Mode  # "File" or "Folder"
    
    WizardPathSelector([string]$mode) {
        $this.Mode = $mode
    }
    
    # Helper properties for IntelliSense
    static [string] File() { return "File" }
    static [string] Folder() { return "Folder" }
}

# WizardCard - Display information card
class WizardCard : System.Attribute {
    [string]$Title
    [string]$Content
    
    WizardCard() {}
    
    WizardCard([string]$title, [string]$content) {
        $this.Title = $title
        $this.Content = $content
    }
}

# WizardDropdownFromCsv - Populate dropdown from CSV file
class WizardDropdownFromCsv : System.Attribute {
    [string]$CsvPath
    [string]$ValueColumn
    [string]$DisplayColumn
    
    WizardDropdownFromCsv([string]$csvPath) {
        $this.CsvPath = $csvPath
    }
    
    WizardDropdownFromCsv([string]$csvPath, [string]$valueColumn, [string]$displayColumn) {
        $this.CsvPath = $csvPath
        $this.ValueColumn = $valueColumn
        $this.DisplayColumn = $displayColumn
    }
}

# WizardListBox - Display items in a scrollable list box (single or multi-select)
class WizardListBox : System.Attribute {
    [bool]$MultiSelect
    [int]$Height
    
    WizardListBox() {
        $this.MultiSelect = $false
        $this.Height = 150
    }
    
    WizardListBox([bool]$multiSelect) {
        $this.MultiSelect = $multiSelect
        $this.Height = 150
    }
    
    WizardListBox([bool]$multiSelect, [int]$height) {
        $this.MultiSelect = $multiSelect
        $this.Height = $height
    }
}

# WizardDataSource - Dynamic data source for dropdowns and listboxes
class WizardDataSource : System.Attribute {
    [scriptblock]$ScriptBlock
    [string[]]$DependsOn
    [string]$CsvPath
    [string]$CsvColumn
    
    WizardDataSource([scriptblock]$scriptBlock) {
        $this.ScriptBlock = $scriptBlock
        $this.DependsOn = @()
    }
    
    WizardDataSource([scriptblock]$scriptBlock, [string[]]$dependsOn) {
        $this.ScriptBlock = $scriptBlock
        $this.DependsOn = $dependsOn
    }
    
    WizardDataSource([string]$csvPath, [string]$csvColumn) {
        $this.CsvPath = $csvPath
        $this.CsvColumn = $csvColumn
    }
}

# PageType - Designates special page types (Card, GenericForm)
class PageType : System.Attribute {
    [string]$Type
    
    PageType([string]$type) {
        $this.Type = $type
    }
    
    # Helper properties for IntelliSense
    static [string] Card() { return "Card" }
    static [string] GenericForm() { return "GenericForm" }
}

# ═════════════════════════════════════════════════════════════════════════════
# PARAMETER SNIPPETS & HELPERS
# ═════════════════════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    Shows available WizardPathSelector modes.
#>
function Get-WizardPathModes {
    [CmdletBinding()]
    param()
    
    Write-Host "WizardPathSelector Modes:" -ForegroundColor Cyan
    Write-Host "  [WizardPathSelector(File)]   - File picker" -ForegroundColor Green
    Write-Host "  [WizardPathSelector(Folder)] - Folder picker" -ForegroundColor Green
}

<#
.SYNOPSIS
    Shows available parameter attributes for wizards.
#>
function Get-WizardAttributes {
    [CmdletBinding()]
    param()
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       PoshWizard Parameter Attributes Reference           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "STEP ORGANIZATION:" -ForegroundColor Yellow
    Write-Host "  [WizardStep('StepName', 1)]           - Associate parameter with step" -ForegroundColor White
    Write-Host "  [WizardParameterDetails(Label='...')]  - Set label and control sizing" -ForegroundColor White
    
    Write-Host "`nINPUT CONTROLS:" -ForegroundColor Yellow
    Write-Host "  [string]                              - Single-line text input (implicit)" -ForegroundColor White
    Write-Host "  [WizardMultiLine()]                   - Multi-line text box (explicit)" -ForegroundColor White
    Write-Host "  [SecureString]                        - Password input (implicit)" -ForegroundColor White
    Write-Host "  [bool]                                - Checkbox (implicit)" -ForegroundColor White
    Write-Host "  [switch]                              - Checkbox (implicit)" -ForegroundColor White
    Write-Host "  [WizardSwitch]                        - Toggle switch (explicit)" -ForegroundColor White
    Write-Host "  [ValidateSet('A','B','C')]            - Dropdown (implicit)" -ForegroundColor White
    Write-Host "  [WizardListBox()]                     - ListBox single-select (explicit)" -ForegroundColor White
    Write-Host "  [WizardListBox(`$true)]               - ListBox multi-select (explicit)" -ForegroundColor White
    Write-Host "  [WizardDropdownFromCsv('file.csv')]   - CSV dropdown (explicit)" -ForegroundColor White
    Write-Host "  [WizardNumeric()]                     - Numeric spinner (explicit)" -ForegroundColor White
    Write-Host "  [WizardDate()]                        - Date picker (explicit)" -ForegroundColor White
    Write-Host "  [WizardPathSelector(File)]            - File picker (explicit)" -ForegroundColor White
    Write-Host "  [WizardPathSelector(Folder)]          - Folder picker (explicit)" -ForegroundColor White
    
    Write-Host "`nDYNAMIC CONTROLS:" -ForegroundColor Yellow
    Write-Host "  [WizardDataSource({param(`$Env) ... })] - Dynamic dropdown/listbox" -ForegroundColor White
    Write-Host "  [WizardDataSource('file.csv','Col')]  - CSV data source" -ForegroundColor White
    
    Write-Host "`nDISPLAY CONTROLS:" -ForegroundColor Yellow
    Write-Host "  [WizardCard('Title','Content')]       - Info card" -ForegroundColor White
    
    Write-Host "`nVALIDATION ATTRIBUTES:" -ForegroundColor Yellow
    Write-Host "  [Parameter(Mandatory)]                - Required field" -ForegroundColor White
    Write-Host "  [ValidateNotNullOrEmpty`(`)]          - Cannot be empty" -ForegroundColor White
    Write-Host "  [ValidatePattern('regex')]            - Regex validation" -ForegroundColor White
    Write-Host "  [ValidateRange(1,100)]                - Numeric range" -ForegroundColor White
    Write-Host "  [ValidateLength(3,50)]                - String length" -ForegroundColor White
    
    Write-Host "`nPAGE TYPES:" -ForegroundColor Yellow
    Write-Host "  [PageType='Card']                     - Card/information page" -ForegroundColor White
    Write-Host "  [PageType='GenericForm']              - Standard form page (default)" -ForegroundColor White
    Write-Host "`n  Note: Welcome and Summary page types have been removed." -ForegroundColor DarkGray
    
    Write-Host ""
}

<#
.SYNOPSIS
    Generates a complete wizard parameter template.
#>
function New-WizardParameterTemplate {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IncludeAllTypes
    )
    
    # Note: Returns a string template - not executed PowerShell code
    $template = @'
# Import IntelliSense support (for VS Code auto-completion)
using module .\PoshWizard\PoshWizard.IntelliSense.psm1

param(
    # Text input example
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,
    
    # Password example
    [Parameter(Mandatory)]
    [SecureString]$AdminPassword,
    
    # Dropdown example
    [ValidateSet("Dev", "Test", "Prod")]
    [string]$Environment = "Dev",
    
    # Checkbox example
    [bool]$EnableSSL = $true,
    
    # File path example
    [WizardPathSelector(File)]
    [string]$ConfigFile,
    
    # Folder path example
    [WizardPathSelector(Folder)]
    [string]$InstallDir
)

# Your wizard logic here
Write-Host "Configuration started..." -ForegroundColor Cyan
Write-Host "Server: $ServerName"
Write-Host "Environment: $Environment"
'@
    
    return $template
}

# ═════════════════════════════════════════════════════════════════════════════
# EXPORT FUNCTIONS
# ═════════════════════════════════════════════════════════════════════════════

Export-ModuleMember -Function @(
    'Get-WizardPathModes',
    'Get-WizardAttributes',
    'New-WizardParameterTemplate'
)

# Export classes for using module syntax
Export-ModuleMember -Variable @()

Write-Verbose "PoshWizard.IntelliSense module loaded - Custom attributes available for IntelliSense"
