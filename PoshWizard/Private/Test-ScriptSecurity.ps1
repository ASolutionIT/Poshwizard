function Test-ScriptSecurity {
    <#
    .SYNOPSIS
    Validates PowerShell script blocks for security issues

    .DESCRIPTION
    Performs basic security validation on PowerShell script blocks to prevent
    execution of potentially dangerous commands in wizard execution scripts.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )
    
    try {
        $scriptText = $ScriptBlock.ToString()
        Write-Verbose "Validating script security for script block (length: $($scriptText.Length))"
        
        # Parse the script to get AST
        $tokens = @()
        $errors = @()
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptText, [ref]$tokens, [ref]$errors)
        
        if ($errors.Count -gt 0) {
            $errorMessages = $errors | ForEach-Object { $_.Message }
            throw "Script parsing errors: $($errorMessages -join '; ')"
        }
        
        # Check for dangerous commands
        $dangerousCommands = @(
            'Invoke-Expression', 'iex',
            'Add-Type',
            'Remove-Item', 'rm', 'del',
            'Remove-ItemProperty',
            'Clear-RecycleBin',
            'Format-Volume',
            'Remove-Computer',
            'Stop-Computer',
            'Restart-Computer',
            'Disable-ComputerRestore',
            'Get-Credential',
            'ConvertTo-SecureString',
            'Import-Certificate',
            'Set-ExecutionPolicy',
            'Enable-PSRemoting',
            'New-PSSession',
            'Invoke-Command',
            'Start-Process',
            'Register-WmiEvent',
            'Set-WmiInstance',
            'Invoke-WmiMethod'
        )
        
        # Find all command invocations in the AST
        $commandAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
        
        $foundDangerous = @()
        foreach ($commandAst in $commandAsts) {
            $commandName = $commandAst.GetCommandName()
            if ($commandName -in $dangerousCommands) {
                $foundDangerous += $commandName
            }
        }
        
        if ($foundDangerous.Count -gt 0) {
            throw "Script contains restricted commands: $($foundDangerous -join ', '). These commands are not allowed in wizard execution scripts for security reasons."
        }
        
        # Check for suspicious patterns
        $suspiciousPatterns = @(
            '\$ExecutionContext',
            'System\.Reflection',
            'System\.Runtime\.InteropServices',
            'Add-Type.*DllImport',
            'Invoke-Expression',
            '\[System\.IO\.File\]',
            '\[System\.IO\.Directory\]',
            'Get-Process.*Stop-Process',
            'Net\.WebClient',
            'DownloadString',
            'DownloadFile'
        )
        
        foreach ($pattern in $suspiciousPatterns) {
            if ($scriptText -match $pattern) {
                Write-Warning "Script contains potentially suspicious pattern: $pattern"
            }
        }
        
        # Additional validation: Check for attempts to access parent scopes inappropriately
        if ($scriptText -match '\$global:' -or $scriptText -match '\$script:') {
            Write-Warning "Script accesses global or script scope variables. Use WizardContext for sharing data between steps."
        }
        
        Write-Verbose "Script security validation passed"
        return $true
    }
    catch {
        Write-Error "Script security validation failed: $($_.Exception.Message)"
        throw
    }
}

