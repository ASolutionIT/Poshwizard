# ConvertTo-WizardScript.ps1 - Script generation engine

function ConvertTo-WizardScript {
    <#
    .SYNOPSIS
    Converts a WizardDefinition object to a traditional parameter-based PowerShell script.
    
    .DESCRIPTION
    Internal function that generates a PowerShell script with param() block and attributes
    that matches the current PoshWizard parameter-based format. This allows the existing
    WPF executable to process wizards created with the module functions.
    
    .PARAMETER Definition
    The WizardDefinition object to convert to a script.
    
    .PARAMETER ScriptBody
    Optional script body to append after the parameter block.
    
    .OUTPUTS
    String containing the generated PowerShell script.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [WizardDefinition]$Definition,
        
        [Parameter()]
        [scriptblock]$ScriptBody
    )
    
    Write-Verbose "Converting wizard definition to script: $($Definition.Title)"
    
    try {
        $scriptLines = @()
        $scriptLines += "# Generated PoshWizard script"
        $scriptLines += "# Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $scriptLines += "# Wizard: $($Definition.Title)"
        $scriptLines += ""
        
        # Start param block
        $scriptLines += "param("
        
        $parameterLines = @()
        
        # Add branding parameter - ALWAYS include if there's a wizard title or any branding
        $needsBranding = (-not [string]::IsNullOrEmpty($Definition.Title)) -or
                        ($Definition.Branding.Count -gt 0) -or 
                        (-not [string]::IsNullOrEmpty($Definition.SidebarHeaderText)) -or
                        (-not [string]::IsNullOrEmpty($Definition.SidebarHeaderIcon))
        
        if ($needsBranding) {
            $brandingLines = @()
            $brandingLines += "    [Parameter(Mandatory=`$false)]"
            
            # Build branding attribute from both old hashtable and new properties
            $brandingParts = @()
            
            # Check if WindowTitleText is explicitly set in branding
            $hasExplicitWindowTitle = $Definition.Branding.ContainsKey('WindowTitleText') -and 
                                     (-not [string]::IsNullOrEmpty($Definition.Branding['WindowTitleText']))
            
            # Add WindowTitleText from wizard Title if not explicitly set in branding
            if (-not $hasExplicitWindowTitle -and (-not [string]::IsNullOrEmpty($Definition.Title))) {
                $brandingParts += "WindowTitleText = '$($Definition.Title)'"
            }
            
            # Track which keys we've already added to avoid duplicates
            $addedKeys = @{}
            
            # Add from Branding hashtable (all keys including OriginalScriptName)
            foreach ($key in $Definition.Branding.Keys) {
                $value = $Definition.Branding[$key]
                # Skip empty values
                if ([string]::IsNullOrEmpty($value)) {
                    continue
                }
                $brandingParts += "$key = '$value'"
                $addedKeys[$key] = $true
            }
            
            # Add SidebarHeaderText if set (and not already added from hashtable)
            if (-not $addedKeys.ContainsKey('SidebarHeaderText') -and 
                -not [string]::IsNullOrEmpty($Definition.SidebarHeaderText)) {
                $brandingParts += "SidebarHeaderText = '$($Definition.SidebarHeaderText)'"
                $addedKeys['SidebarHeaderText'] = $true
            }
            
            # Add SidebarHeaderIconPath if set (and not already added from hashtable)
            if (-not $addedKeys.ContainsKey('SidebarHeaderIconPath') -and 
                -not [string]::IsNullOrEmpty($Definition.SidebarHeaderIcon)) {
                $brandingParts += "SidebarHeaderIconPath = '$($Definition.SidebarHeaderIcon)'"
                $addedKeys['SidebarHeaderIconPath'] = $true
            }

            if (-not $addedKeys.ContainsKey('SidebarHeaderIconOrientation') -and 
                -not [string]::IsNullOrEmpty($Definition.SidebarHeaderIconOrientation)) {
                $orientationValue = $Definition.SidebarHeaderIconOrientation.Trim()
                switch -Regex ($orientationValue.ToLowerInvariant()) {
                    '^(right)$'  { $orientationValue = 'Right' }
                    '^(top)$'    { $orientationValue = 'Top' }
                    '^(bottom)$' { $orientationValue = 'Bottom' }
                    default      { $orientationValue = 'Left' }
                }
                $brandingParts += "SidebarHeaderIconOrientation = '$orientationValue'"
                $addedKeys['SidebarHeaderIconOrientation'] = $true
            }
            
            # Add WindowTitleIcon if set (and not already added from hashtable)
            if (-not $addedKeys.ContainsKey('WindowTitleIcon') -and 
                -not [string]::IsNullOrEmpty($Definition.Icon)) {
                $brandingParts += "WindowTitleIcon = '$($Definition.Icon)'"
                $addedKeys['WindowTitleIcon'] = $true
            }
            
            # Add Theme if set (and not already added from hashtable)
            if (-not $addedKeys.ContainsKey('Theme') -and 
                -not [string]::IsNullOrEmpty($Definition.Theme)) {
                $brandingParts += "Theme = '$($Definition.Theme)'"
                $addedKeys['Theme'] = $true
            }
            
            $brandingAttribute = "[WizardBranding($($brandingParts -join ', '))]"
            $brandingLines += "    $brandingAttribute"
            $brandingLines += "    [string]`$BrandingPlaceholder,"
            $brandingLines += ""
            
            $parameterLines += $brandingLines
        }
        
        # Process steps in order
        $sortedSteps = $Definition.Steps | Sort-Object Order
        
        foreach ($step in $sortedSteps) {
            Write-Verbose "Processing step: $($step.Name)"
            
            # Add step header comment
            $parameterLines += "    # --- Step: $($step.Title) ---"
            
            # Handle different step types
            switch ($step.Type) {
                'Welcome' {
                    $parameterLines += Convert-WelcomeStep -Step $step
                }
                'Card' {
                    $parameterLines += Convert-CardStep -Step $step
                }
                'Summary' {
                    $parameterLines += Convert-SummaryStep -Step $step
                }
                'GenericForm' {
                    $parameterLines += Convert-GenericFormStep -Step $step
                }
                default {
                    $parameterLines += Convert-GenericFormStep -Step $step
                }
            }
            
            $parameterLines += ""
        }
        
        # Remove trailing comma from last parameter
        if ($parameterLines.Count -gt 0) {
            # Find the last non-empty line
            for ($i = $parameterLines.Count - 1; $i -ge 0; $i--) {
                $line = $parameterLines[$i]
                if (-not [string]::IsNullOrWhiteSpace($line) -and $line.Trim().EndsWith(',')) {
                    $parameterLines[$i] = $line.TrimEnd(',')
                    break
                }
            }
        }
        
        # Add parameters to script
        $scriptLines += $parameterLines
        
        # Close param block
        $scriptLines += ")"
        $scriptLines += ""
        
        # Add script body if provided
        if ($ScriptBody) {
            $scriptLines += "# --- Script Body ---"
            $scriptLines += $ScriptBody.ToString()
        } else {
            $scriptLines += "# --- Default Script Body ---"
            $scriptLines += "Write-Host 'Wizard completed successfully!' -ForegroundColor Green"
            $scriptLines += "Write-Host 'Parameters received:' -ForegroundColor Cyan"
            
            # Add parameter output for each control
            foreach ($step in $sortedSteps) {
                foreach ($control in $step.Controls) {
                    if ($control.Type -ne 'Card') {
                        $scriptLines += "Write-Host '$($control.Label): ' -NoNewline"
                        $scriptLines += "Write-Host `$$($control.Name) -ForegroundColor Yellow"
                    }
                }
            }
        }
        
        $generatedScript = $scriptLines -join "`n"
        
        Write-Verbose "Successfully generated script ($($scriptLines.Count) lines)"
        
        return $generatedScript
    }
    catch {
        Write-Error "Failed to convert wizard definition to script: $($_.Exception.Message)"
        throw
    }
}

function Convert-GenericFormStep {
    param([WizardStep]$Step)
    
    Write-Verbose "Converting GenericForm step: $($Step.Title) with $($Step.Controls.Count) controls"
    
    $lines = @()
    $isFirstNonCardControl = $true
    
    foreach ($control in $Step.Controls) {
        Write-Verbose "  Processing control: Name=$($control.Name), Type=$($control.Type), Label=$($control.Label)"
        
        # Check if this is a Card control
        $isCard = $control.Type -eq 'Card'
        
        # First NON-CARD control gets the WizardStep attribute
        if ($isFirstNonCardControl -and -not $isCard) {
            $lines += "    [Parameter(Mandatory=`$$($control.Mandatory.ToString().ToLower()))]" 
            $stepAttribute = "[WizardStep('$($Step.Title)', $($Step.Order)"
            if ($Step.Description) {
                $stepAttribute += ", Description='$($Step.Description)'"
            }
            if ($Step.Icon) {
                $stepAttribute += ", IconPath='$($Step.Icon)'"
            }
            $stepAttribute += ")]"
            $lines += "    $stepAttribute"
            $isFirstNonCardControl = $false
        } elseif (-not $isCard) {
            # Subsequent non-card controls just get Parameter attribute
            $lines += "    [Parameter(Mandatory=`$$($control.Mandatory.ToString().ToLower()))]"
            $lines += "    [WizardStep('$($Step.Title)', $($Step.Order))]"
        } else {
            # Card controls - check if this is the first control overall (to attach WizardStep)
            if ($isFirstNonCardControl -and $Step.Controls.Where({$_.Type -ne 'Card'}).Count -eq 0) {
                # Step has ONLY cards, attach WizardStep to first card
                $lines += "    [Parameter(Mandatory=`$false)]"
                $stepAttribute = "[WizardStep('$($Step.Title)', $($Step.Order)"
                if ($Step.Description) {
                    $stepAttribute += ", Description='$($Step.Description)'"
                }
                if ($Step.Icon) {
                    $stepAttribute += ", IconPath='$($Step.Icon)'"
                }
                $stepAttribute += ")]"
                $lines += "    $stepAttribute"
                $isFirstNonCardControl = $false
            } elseif (-not $isFirstNonCardControl) {
                # Subsequent cards (step already defined)
                $lines += "    [Parameter(Mandatory=`$false)]"
                $lines += "    [WizardStep('$($Step.Title)', $($Step.Order))]"
            } else {
                # First card but there are non-card controls coming
                $lines += "    [Parameter(Mandatory=`$false)]"
                $lines += "    [WizardStep('$($Step.Title)', $($Step.Order))]"
            }
        }
        
        $lines += Convert-Control -Control $control
    }
    
    return $lines
}

function Convert-WelcomeStep {
    param([WizardStep]$Step)
    
    $lines = @()
    $lines += "    [Parameter(Mandatory=`$false)]"
    
    $stepAttribute = "[WizardStep('$($Step.Title)', $($Step.Order), PageType='Welcome'"
    if ($Step.Description) {
        $stepAttribute += ", Description='$($Step.Description)'"
    }
    
    # Add welcome-specific properties
    $introText = $Step.GetProperty('IntroductionText')
    if ($introText) {
        $stepAttribute += ", IntroductionText='$introText'"
    }
    
    $prerequisites = $Step.GetProperty('Prerequisites')
    if ($prerequisites) {
        $stepAttribute += ", Prerequisites='$prerequisites'"
    }
    
    $supportLink = $Step.GetProperty('SupportLink')
    if ($supportLink) {
        $stepAttribute += ", SupportLink='$supportLink'"
    }
    
    if ($Step.Icon) {
        $stepAttribute += ", IconPath='$($Step.Icon)'"
    }
    
    $stepAttribute += ")]"
    $lines += "    $stepAttribute"
    $lines += "    [string]`$WelcomePlaceholder_$($Step.Name),"
    
    return $lines
}

function Convert-CardStep {
    param([WizardStep]$Step)
    
    $lines = @()
    $isFirstCard = $true
    
    # Add step definition on first card
    if ($Step.Controls.Count -gt 0) {
        $lines += "    [Parameter(Mandatory=`$false)]"
        $stepAttribute = "[WizardStep('$($Step.Title)', $($Step.Order), PageType='Card'"
        if ($Step.Description) {
            $stepAttribute += ", Description='$($Step.Description)'"
        }
        $stepAttribute += ")]"
        $lines += "    $stepAttribute"
    }
    
    foreach ($control in $Step.Controls) {
        if ($control.Type -eq 'Card') {
            if (-not $isFirstCard) {
                $lines += "    [Parameter(Mandatory=`$false)]"
            }
            
            $title = $control.GetProperty('Title')
            $content = $control.GetProperty('Content')
            $lines += "    [WizardCard('$title', '$content')]"
            $lines += "    [string]`$CardPlaceholder_$($control.Name),"
            
            $isFirstCard = $false
        } else {
            # Regular controls in card step
            $lines += "    [Parameter(Mandatory=`$$($control.Mandatory.ToString().ToLower()))]"
            $lines += Convert-Control -Control $control
        }
    }
    
    return $lines
}

function Convert-SummaryStep {
    param([WizardStep]$Step)
    
    $lines = @()
    $lines += "    [Parameter(Mandatory=`$false)]"
    
    $stepAttribute = "[WizardStep('$($Step.Title)', $($Step.Order), PageType='Summary'"
    if ($Step.Description) {
        $stepAttribute += ", Description='$($Step.Description)'"
    }
    if ($Step.Icon) {
        $stepAttribute += ", IconPath='$($Step.Icon)'"
    }
    $stepAttribute += ")]"
    $lines += "    $stepAttribute"
    $lines += "    [string]`$SummaryPlaceholder_$($Step.Name),"
    
    return $lines
}

function Convert-Control {
    param([WizardControl]$Control)
    
    $lines = @()
    
    # Add parameter details attribute
    $detailsAttribute = "[WizardParameterDetails(Label='$($Control.Label)'"
    if ($Control.Width -gt 0) {
        $detailsAttribute += ", ControlWidth=$($Control.Width)"
    }
    $detailsAttribute += ")]"
    $lines += "    $detailsAttribute"
    
    # Add validation attributes (but NOT for Password controls - SecureString doesn't support ValidatePattern)
    # Password validation is handled by C# using the ValidationPattern property on ParameterInfo
    if ($Control.ValidationPattern -and $Control.Type -ne 'Password') {
        $lines += "    [ValidatePattern('$($Control.ValidationPattern)')]"
    }
    
    # Note: ValidationScript is not yet supported in generated scripts
    # Script block validation requires C# runtime execution which is not yet implemented
    # ValidationMessage is also pending C# implementation
    
    # Add type-specific attributes and parameter declaration
    switch ($Control.Type) {
        'TextBox' {
            $paramType = '[string]'

            if ($Control.GetPropertyOrDefault('Multiline', $false)) {
                $rows = $Control.GetPropertyOrDefault('Rows', $null)
                $multiLineArgs = @()
                if ($rows) {
                    $multiLineArgs += "Rows=$rows"
                }
                $multiLineAttribute = if ($multiLineArgs.Count -gt 0) {
                    "[WizardMultiLine($($multiLineArgs -join ', '))]"
                } else {
                    "[WizardMultiLine]"
                }
                $lines += "    $multiLineAttribute"
            } else {
                # Check for optional WizardTextBox attribute (v1.2.0)
                $maxLength = $Control.GetPropertyOrDefault('MaxLength', $null)
                $placeholder = $Control.GetPropertyOrDefault('Placeholder', $null)
                
                if ($maxLength -or $placeholder) {
                    $textBoxArgs = @()
                    if ($maxLength) {
                        $textBoxArgs += "MaxLength=$maxLength"
                    }
                    if ($placeholder) {
                        $escapedPlaceholder = $placeholder -replace "'", "''"
                        $textBoxArgs += "Placeholder='$escapedPlaceholder'"
                    }
                    $lines += "    [WizardTextBox($($textBoxArgs -join ', '))]"
                }
            }
        }
        'Password' {
            $paramType = '[SecureString]'
            
            # Check for optional WizardPassword attribute (v1.2.0+)
            $minLength = $Control.GetPropertyOrDefault('MinLength', $null)
            $showReveal = $Control.GetPropertyOrDefault('ShowRevealButton', $null)
            $validationPattern = $Control.ValidationPattern
            
            if ($minLength -or ($null -ne $showReveal) -or $validationPattern) {
                $passwordArgs = @()
                if ($minLength) {
                    $passwordArgs += "MinLength=$minLength"
                }
                if ($null -ne $showReveal) {
                    $passwordArgs += "ShowRevealButton=`$$($showReveal.ToString().ToLower())"
                }
                if ($validationPattern) {
                    # Escape single quotes in the pattern
                    $escapedPattern = $validationPattern -replace "'", "''"
                    $passwordArgs += "ValidationPattern='$escapedPattern'"
                }
                $lines += "    [WizardPassword($($passwordArgs -join ', '))]"
            }
        }
        'Checkbox' {
            $paramType = '[bool]'
            
            # Check for optional WizardCheckBox attribute (v1.2.0)
            $checkedLabel = $Control.GetPropertyOrDefault('CheckedLabel', $null)
            $uncheckedLabel = $Control.GetPropertyOrDefault('UncheckedLabel', $null)
            
            if ($checkedLabel -or $uncheckedLabel) {
                $checkBoxArgs = @()
                if ($checkedLabel) {
                    $escapedChecked = $checkedLabel -replace "'", "''"
                    $checkBoxArgs += "CheckedLabel='$escapedChecked'"
                }
                if ($uncheckedLabel) {
                    $escapedUnchecked = $uncheckedLabel -replace "'", "''"
                    $checkBoxArgs += "UncheckedLabel='$escapedUnchecked'"
                }
                $lines += "    [WizardCheckBox($($checkBoxArgs -join ', '))]"
            }
        }
        'Toggle' {
            # Toggle requires WizardSwitch attribute for modern UI
            $lines += "    [WizardSwitch]"
            $paramType = '[switch]'
        }
        'Dropdown' {
            # Check for dynamic scriptblock first
            $isDynamic = $Control.GetPropertyOrDefault('IsDynamic', $false)
            if ($isDynamic) {
                $scriptBlockContent = $Control.GetProperty('DataSourceScriptBlock')
                if ($scriptBlockContent) {
                    # Generate WizardDataSource attribute with script block
                    $dataSourceAttribute = "[WizardDataSource({$scriptBlockContent})]"
                    $lines += "    $dataSourceAttribute"
                }
            }
            # Fall back to static choices if no scriptblock
            elseif ($Control.Choices -and $Control.Choices.Count -gt 0) {
                $choicesString = ($Control.Choices | ForEach-Object { "'$_'" }) -join ', '
                $lines += "    [ValidateSet($choicesString)]"
            }
            $paramType = '[string]'
        }
        'ListBox' {
            # Check for dynamic scriptblock first
            $isDynamic = $Control.GetPropertyOrDefault('IsDynamic', $false)
            if ($isDynamic) {
                $scriptBlockContent = $Control.GetProperty('DataSourceScriptBlock')
                if ($scriptBlockContent) {
                    # Generate WizardDataSource attribute with script block
                    $dataSourceAttribute = "[WizardDataSource({$scriptBlockContent})]"
                    $lines += "    $dataSourceAttribute"
                }
            }
            # Fall back to static choices if no scriptblock
            elseif ($Control.Choices -and $Control.Choices.Count -gt 0) {
                $choicesString = ($Control.Choices | ForEach-Object { "'$_'" }) -join ', '
                $lines += "    [ValidateSet($choicesString)]"
            }
            $isMultiSelect = $Control.GetPropertyOrDefault('IsMultiSelect', $false)
            if ($isMultiSelect) {
                # Multi-select uses string array - use named parameter
                $paramType = '[string[]]'
                $lines += "    [WizardListBox(MultiSelect=`$true)]"
            } else {
                # Single-select uses string
                $paramType = '[string]'
                $lines += "    [WizardListBox()]"
            }
        }
        'Numeric' {
            $paramType = '[double]'

            $numericArgs = @()
            $min = $Control.GetPropertyOrDefault('Minimum', $null)
            $max = $Control.GetPropertyOrDefault('Maximum', $null)
            $step = $Control.GetPropertyOrDefault('Step', $null)
            $allowDecimal = [bool]$Control.GetPropertyOrDefault('AllowDecimal', $false)

            if ($null -ne $min) {
                $numericArgs += "Minimum=$($min.ToString([System.Globalization.CultureInfo]::InvariantCulture))"
            }
            if ($null -ne $max) {
                $numericArgs += "Maximum=$($max.ToString([System.Globalization.CultureInfo]::InvariantCulture))"
            }
            if ($null -ne $step) {
                $numericArgs += "Step=$($step.ToString([System.Globalization.CultureInfo]::InvariantCulture))"
            }
            if ($allowDecimal) {
                $numericArgs += "AllowDecimal=`$true"
            }

            $numericAttribute = if ($numericArgs.Count -gt 0) {
                "[WizardNumeric($($numericArgs -join ', '))]"
            } else {
                "[WizardNumeric]"
            }
            $lines += "    $numericAttribute"
        }
        'Date' {
            $paramType = '[string]'

            $dateArgs = @()
            $minDate = $Control.GetPropertyOrDefault('Minimum', $null)
            $maxDate = $Control.GetPropertyOrDefault('Maximum', $null)
            $format = $Control.GetPropertyOrDefault('Format', $null)

            if ($minDate) {
                $dateArgs += "Minimum='$(($minDate).ToString('o'))'"
            }
            if ($maxDate) {
                $dateArgs += "Maximum='$(($maxDate).ToString('o'))'"
            }
            if ($format) {
                $escapedFormat = $format -replace "'", "''"
                $dateArgs += "Format='$escapedFormat'"
            }

            $dateAttribute = if ($dateArgs.Count -gt 0) {
                "[WizardDate($($dateArgs -join ', '))]"
            } else {
                "[WizardDate]"
            }
            $lines += "    $dateAttribute"
        }
        'OptionGroup' {
            if ($Control.Choices -and $Control.Choices.Count -gt 0) {
                $choicesString = ($Control.Choices | ForEach-Object { "'$_'" }) -join ', '
                $lines += "    [ValidateSet($choicesString)]"
            }

            $paramType = '[string]'

            $orientation = $Control.GetPropertyOrDefault('Orientation', 'Vertical')
            $arguments = @()
            if ($Control.Choices) {
                $arguments += ($Control.Choices | ForEach-Object { "'$_'" })
            }

            $orientationArg = if ($orientation -and $orientation -ne 'Vertical') {
                "Orientation='$orientation'"
            } else {
                $null
            }

            $optionAttribute = if ($orientationArg) {
                if ($arguments.Count -gt 0) {
                    "[WizardOptionGroup($($arguments -join ', '), $orientationArg)]"
                } else {
                    "[WizardOptionGroup($orientationArg)]"
                }
            } else {
                if ($arguments.Count -gt 0) {
                    "[WizardOptionGroup($($arguments -join ', '))]"
                } else {
                    "[WizardOptionGroup]"
                }
            }

            $lines += "    $optionAttribute"
        }
        'Card' {
            # Cards render as display elements, not input parameters
            $title = $Control.GetProperty('CardTitle')
            $content = $Control.GetProperty('CardContent')
            
            if ($title -and $content) {
                # Escape content properly for PowerShell attribute syntax
                # 1. Escape single quotes by doubling them
                # 2. Replace newlines with PowerShell escape sequence (backtick-n)
                #    Use double-backtick to output literal backtick in generated script
                $escapedTitle = $title -replace "'", "''"
                $escapedContent = $content -replace "'", "''" -replace "`r`n", '``n' -replace "`n", '``n'
                $lines += "    [WizardCard('$escapedTitle', '$escapedContent')]"
            }
            $paramType = '[string]'
        }
        'DropdownFromCsv' {
            # CSV dropdowns use WizardDataSource attribute with CsvPath/CsvColumn
            $csvPath = $Control.GetProperty('CsvPath')
            $valueColumn = $Control.GetProperty('CsvColumn')
            if (-not $valueColumn) {
                $valueColumn = $Control.GetProperty('ValueColumn')  # Try alternate property name
            }
            
            if ($csvPath -and $valueColumn) {
                $lines += "    [WizardDataSource(CsvPath='$csvPath', CsvColumn='$valueColumn')]"
            }
            $paramType = '[string]'
        }
        'DynamicDropdown' {
            # Generate WizardDataSource attribute with script block
            $scriptBlockContent = $Control.GetProperty('DataSourceScriptBlock')
            if ($scriptBlockContent) {
                # The script block is stored as a string, wrap it properly
                $dataSourceAttribute = "[WizardDataSource({$scriptBlockContent})]"
                $lines += "    $dataSourceAttribute"
            }
            $paramType = '[string]'
        }
        'FilePath' {
            # Use WizardFilePath with Filter and DialogTitle (Test-DirectAttributes.ps1 line 15)
            $pathProps = @()
            $filter = $Control.GetPropertyOrDefault('Filter', $null)
            $dialogTitle = $Control.GetPropertyOrDefault('DialogTitle', $null)
            
            if ($filter) {
                $pathProps += "Filter='$filter'"
            }
            if ($dialogTitle) {
                $escapedTitle = $dialogTitle -replace "'", "''"
                $pathProps += "DialogTitle='$escapedTitle'"
            }
            
            if ($pathProps.Count -gt 0) {
                $lines += "    [WizardFilePath($($pathProps -join ', '))]"
            } else {
                # Fallback to PathSelector if no filter/title specified
                $lines += "    [WizardPathSelector('File')]"
            }
            $paramType = '[string]'
        }
        'FolderPath' {
            # Use WizardPathSelector('Folder') - this is what works in Demo-AllControls-Param.ps1
            $lines += "    [WizardPathSelector('Folder')]"
            $paramType = '[string]'
        }
        default {
            $paramType = '[string]'
        }
    }
    
    # Add parameter declaration with proper default value formatting
    $paramDeclaration = "    $paramType`$$($Control.Name)"
    if ($null -ne $Control.Default -and $Control.Default -ne '') {
        # Format default value based on type
        if ($Control.Type -in @('Checkbox', 'Toggle')) {
            # Boolean/switch types don't use quotes
            $paramDeclaration += " = `$$($Control.Default)"
        }
        elseif ($Control.Type -eq 'Password') {
            # SecureString types don't have defaults
        }
        elseif ($Control.Type -eq 'Numeric') {
            $paramDeclaration += " = $($Control.Default.ToString([System.Globalization.CultureInfo]::InvariantCulture))"
        }
        elseif ($Control.Type -eq 'Date') {
            if ($Control.Default -is [DateTime]) {
                $dateLiteral = $Control.Default.ToString('yyyy-MM-dd')
                $paramDeclaration += " = '$dateLiteral'"
            } else {
                $paramDeclaration += " = '$($Control.Default)'"
            }
        }
        elseif ($Control.Type -eq 'ListBox' -and $paramType -eq '[string[]]') {
            # Multi-select ListBox with array default
            if ($Control.Default -is [array]) {
                $defaultArray = ($Control.Default | ForEach-Object { "'$_'" }) -join ', '
                $paramDeclaration += " = @($defaultArray)"
            } else {
                $paramDeclaration += " = @('$($Control.Default)')"
            }
        }
        elseif ($Control.Type -eq 'Card') {
            # Cards don't have default values
        }
        else {
            # String and numeric types use quotes (PowerShell will convert)
            $paramDeclaration += " = '$($Control.Default)'"
        }
    }
    $paramDeclaration += ","
    
    $lines += $paramDeclaration
    
    return $lines
}

