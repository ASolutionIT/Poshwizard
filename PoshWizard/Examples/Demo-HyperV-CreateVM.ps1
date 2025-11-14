<#
.SYNOPSIS
    Hyper-V Virtual Machine Creation Wizard using PoshWizard Cmdlets.

.DESCRIPTION
    Interactive wizard for creating a new Hyper-V virtual machine using PoshWizard Cmdlets.
    Collects VM configuration parameters and provisions the VM with specified settings.

.NOTES
    Syntax: PoshWizard Cmdlets (Verb-Noun functions)
    Requires: Hyper-V PowerShell module and administrator privileges
    
.EXAMPLE
    .\Demo-HyperV-CreateVM.ps1
    
    Launches the Hyper-V VM creation wizard using PoshWizard Cmdlets.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

$modulePath = Join-Path $PSScriptRoot '..\PoshWizard.psd1'
Import-Module $modulePath -Force
$sidebarIconPath = Join-Path $PSScriptRoot 'with_padding.png'
$scriptIconPath = Join-Path $PSScriptRoot 'browser.png'

foreach ($assetPath in @($sidebarIconPath, $scriptIconPath)) {
    if (-not (Test-Path $assetPath)) {
        throw "Branding asset not found: $assetPath"
    }
}
Write-Host @'

========================================
  Hyper-V VM Creation Wizard
  PoshWizard Cmdlets
========================================
'@ -ForegroundColor Cyan

Write-Host "`nCreating a new virtual machine with guided configuration..." -ForegroundColor Yellow
Write-Host ""

# ========================================
# INITIALIZE WIZARD
# ========================================

$wizardParams = @{
    Title       = 'Hyper-V VM Creation Wizard'
    Description = 'Create and configure a new virtual machine'
    Theme       = 'Auto'
    Icon        = $scriptIconPath
}
New-PoshWizard @wizardParams

$brandingParams = @{
    WindowTitle                 = 'Hyper-V VM Creation Wizard'
    SidebarHeaderText           = 'Hyper-V Manager'
    SidebarHeaderIcon           = $sidebarIconPath
    SidebarHeaderIconOrientation = 'Top'
}
Set-WizardBranding @brandingParams

# ========================================
# STEP 1: Welcome
# ========================================

Add-WizardStep -Name 'Welcome' -Title 'Welcome' -Order 1 `
    -Icon '&#xE950;' `
    -Description 'Create a new Hyper-V Virtual Machine'

Add-WizardCard -Step 'Welcome' -Name 'WelcomeCard' `
    -Title 'Hyper-V Virtual Machine Creation Wizard' `
    -Content @'
This wizard will guide you through creating a new virtual machine on your local Hyper-V host.

You will configure:
- VM name and generation
- Memory and processor allocation
- Virtual hard disk settings
- Network configuration

Prerequisites:
- Hyper-V role installed and enabled
- Administrator privileges
- Sufficient disk space for VM files
- Valid virtual switch configured

Documentation: https://docs.microsoft.com/virtualization/hyper-v-on-windows
'@

# ========================================
# STEP 2: VM Identity
# ========================================

Add-WizardStep -Name 'Identity' -Title 'Identity' -Order 2 `
    -Icon '&#xE7EE;' `
    -Description 'Configure VM name and generation'

Add-WizardCard -Step 'Identity' -Name 'IdentityInfoCard' `
    -Title 'VM Naming Guidelines' `
    -Content @'
Choose a unique, descriptive name for your virtual machine:

- Use letters, numbers, hyphens, and underscores only
- Maximum 64 characters
- Avoid spaces and special characters
- Use a naming convention (e.g., Env-Purpose-##)

Examples: Dev-WebServer-01, SQL-Prod-DB, Test-App-Server
'@

Add-WizardTextBox -Step 'Identity' -Name 'VMName' `
    -Label 'Virtual Machine Name' `
    -Default 'NewVM' `
    -ValidationPattern '^[a-zA-Z0-9\-_]{1,64}$'

Add-WizardDropdown -Step 'Identity' -Name 'VMGeneration' `
    -Label 'VM Generation' `
    -Choices @('Generation 1', 'Generation 2') `
    -Default 'Generation 2'

Add-WizardFolderPath -Step 'Identity' -Name 'VMPath' `
    -Label 'VM Storage Path' `
    -Default 'C:\Hyper-V\Virtual Machines'

Add-WizardCard -Step 'Identity' -Name 'IdentityCard' `
    -Title 'VM Generation Info' `
    -Content @'
Generation 1:
- Legacy BIOS boot
- Supports 32-bit guest OS
- IDE and legacy network adapters

Generation 2:
- UEFI firmware
- 64-bit only
- Enhanced performance
- Secure Boot capable
'@

# ========================================
# STEP 3: Resources
# ========================================

Add-WizardStep -Name 'Resources' -Title 'Resources' -Order 3 `
    -Icon '&#xE950;' `
    -Description 'Allocate CPU and memory resources'

Add-WizardCard -Step 'Resources' -Name 'ResourcesInfoCard' `
    -Title 'Resource Planning Tips' `
    -Content @'
Allocate resources based on your workload requirements:

Memory Recommendations:
- Minimum: 512 MB (light workloads)
- Recommended: 2-4 GB (typical workloads)
- High-performance: 8+ GB (databases, applications)

Processor Guidelines:
- 1-2 vCPUs: Development/testing
- 2-4 vCPUs: Production servers
- 4+ vCPUs: High-performance applications

WARNING: Do not over-allocate resources - leave capacity for the host OS
'@

Add-WizardTextBox -Step 'Resources' -Name 'MemoryStartupMB' `
    -Label 'Startup Memory (MB)' `
    -Default '2048' `
    -ValidationPattern '^\d+$'

Add-WizardCheckbox -Step 'Resources' -Name 'EnableDynamicMemory' `
    -Label 'Enable Dynamic Memory' `
    -Default $true

Add-WizardTextBox -Step 'Resources' -Name 'MemoryMinimumMB' `
    -Label 'Minimum Memory (MB) - if dynamic' `
    -Default '512'

Add-WizardTextBox -Step 'Resources' -Name 'MemoryMaximumMB' `
    -Label 'Maximum Memory (MB) - if dynamic' `
    -Default '4096'

Add-WizardTextBox -Step 'Resources' -Name 'ProcessorCount' `
    -Label 'Number of Virtual Processors' `
    -Default '2' `
    -ValidationPattern '^[1-9]\d*$'

# ========================================
# STEP 4: Storage
# ========================================

Add-WizardStep -Name 'Storage' -Title 'Storage' -Order 4 `
    -Icon '&#xEDA2;' `
    -Description 'Configure virtual hard disk settings'

Add-WizardCard -Step 'Storage' -Name 'StorageInfoCard' `
    -Title 'Storage Configuration Guide' `
    -Content @'
Configure the virtual hard disk for your VM:

Disk Size Guidelines:
- Minimal OS install: 20-30 GB
- Standard server: 60-80 GB
- Application server: 100+ GB
- Database server: 200+ GB

Disk Type Comparison:
- Dynamic Expanding: Grows as needed, saves space
- Fixed Size: Better performance, requires full space upfront

TIP: Start with dynamic expanding for flexibility
'@

Add-WizardCheckbox -Step 'Storage' -Name 'CreateNewVHD' `
    -Label 'Create New Virtual Hard Disk' `
    -Default $true

Add-WizardTextBox -Step 'Storage' -Name 'VHDName' `
    -Label 'Virtual Hard Disk Name' `
    -Default 'NewVM.vhdx'

Add-WizardTextBox -Step 'Storage' -Name 'VHDSizeGB' `
    -Label 'Virtual Hard Disk Size (GB)' `
    -Default '60' `
    -ValidationPattern '^\d+$'

Add-WizardDropdown -Step 'Storage' -Name 'VHDType' `
    -Label 'Virtual Hard Disk Type' `
    -Choices @('Dynamic Expanding', 'Fixed Size') `
    -Default 'Dynamic Expanding'

# ========================================
# STEP 5: Networking
# ========================================

Add-WizardStep -Name 'Networking' -Title 'Networking' -Order 5 `
    -Icon '&#xE8B2;' `
    -Description 'Configure network adapter settings'

Add-WizardCard -Step 'Networking' -Name 'NetworkInfoCard' `
    -Title 'Network Configuration' `
    -Content @'
Connect your VM to the network:

Virtual Switch Types:
- External: Connect to physical network
- Internal: Connect to host and other VMs
- Private: Isolated VM-to-VM communication

MAC Address:
- Dynamic (Recommended): Automatically assigned
- Static: Manual configuration for specific scenarios

TIP: Use PowerShell command Get-VMSwitch to view available switches
'@

Add-WizardCheckbox -Step 'Networking' -Name 'AddNetworkAdapter' `
    -Label 'Add Network Adapter' `
    -Default $true

Add-WizardTextBox -Step 'Networking' -Name 'SwitchName' `
    -Label 'Virtual Switch Name' `
    -Default 'Default Switch'

Add-WizardDropdown -Step 'Networking' -Name 'MACAddressType' `
    -Label 'MAC Address Type' `
    -Choices @('Dynamic', 'Static') `
    -Default 'Dynamic'

Add-WizardTextBox -Step 'Networking' -Name 'StaticMACAddress' `
    -Label 'MAC Address (if static)' `
    -Default ''

# ========================================
# STEP 6: Additional Options
# ========================================

Add-WizardStep -Name 'Options' -Title 'Options' -Order 6 `
    -Icon '&#xE713;' `
    -Description 'Additional VM configuration options'

Add-WizardCard -Step 'Options' -Name 'OptionsInfoCard' `
    -Title 'Additional Configuration' `
    -Content @'
Finalize your VM settings:

Automatic Checkpoints:
- Enabled: Creates restore points before changes
- Recommended for production VMs

Integration Services:
- Provides enhanced VM-host communication
- Required for clipboard, time sync, and file copy

Start After Creation:
- Start immediately for testing
- Leave stopped to attach ISO or configure further
'@

Add-WizardCheckbox -Step 'Options' -Name 'StartAfterCreation' `
    -Label 'Start VM after creation' `
    -Default $false

Add-WizardCheckbox -Step 'Options' -Name 'EnableAutomaticCheckpoints' `
    -Label 'Enable Automatic Checkpoints' `
    -Default $true

Add-WizardCheckbox -Step 'Options' -Name 'EnableIntegrationServices' `
    -Label 'Enable Integration Services' `
    -Default $true

Add-WizardMultiLine -Step 'Options' -Name 'VMNotes' `
    -Label 'VM Notes / Description' `
    -Default 'Created via PoshWizard Hyper-V VM Creation Wizard' `
    

# ========================================
# STEP 7: Review
# ========================================

Add-WizardStep -Name 'Review' -Title 'Review' -Order 99 `
    -Icon '&#xE8F1;' `
    -Description 'Review configuration and create VM'

Add-WizardCard -Step 'Review' -Name 'SummaryCard' `
    -Title 'Ready to Create Virtual Machine' `
    -Content @'
Review your configuration and click Finish to create the VM.

The wizard will:
1. Create the VM with specified settings
2. Configure memory and processor allocation
3. Create and attach virtual hard disk
4. Connect network adapter to virtual switch
5. Apply all optional settings

Click Finish to proceed with VM creation.
Click Previous to make changes.
'@

# ========================================
# SHOW WIZARD AND EXECUTE
# ========================================

$result = Show-PoshWizard

if ($result) {
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host "  HYPER-V VIRTUAL MACHINE CREATION WIZARD" -ForegroundColor White
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""

    # Convert generation string to number
    $genNumber = if ($result.VMGeneration -eq 'Generation 2') { 2 } else { 1 }

    # Helper function to handle array values (workaround for serialization bug)
    function Get-SingleValue {
        param([object]$Value)
        if ($Value -is [array]) {
            return $Value[0]
        }
        return $Value
    }

    # Display configuration summary
    Write-Host "[VM Configuration]" -ForegroundColor Green
    Write-Host "  Name                : $((Get-SingleValue $result.VMName))" -ForegroundColor White
    Write-Host "  Generation          : $((Get-SingleValue $result.VMGeneration)) ($genNumber)" -ForegroundColor White
    Write-Host "  Path                : $((Get-SingleValue $result.VMPath))" -ForegroundColor White
    Write-Host ""

    Write-Host "[Resources]" -ForegroundColor Yellow
    Write-Host "  Startup Memory      : $((Get-SingleValue $result.MemoryStartupMB)) MB" -ForegroundColor White
    Write-Host "  Dynamic Memory      : $((Get-SingleValue $result.EnableDynamicMemory))" -ForegroundColor White
    if ((Get-SingleValue $result.EnableDynamicMemory)) {
        Write-Host "  Memory Range        : $((Get-SingleValue $result.MemoryMinimumMB)) MB - $((Get-SingleValue $result.MemoryMaximumMB)) MB" -ForegroundColor White
    }
    Write-Host "  Processors          : $((Get-SingleValue $result.ProcessorCount))" -ForegroundColor White
    Write-Host ""

    Write-Host "[Storage]" -ForegroundColor Cyan
    if ((Get-SingleValue $result.CreateNewVHD)) {
        Write-Host "  Create VHD          : Yes" -ForegroundColor White
        Write-Host "  VHD Name            : $((Get-SingleValue $result.VHDName))" -ForegroundColor White
        Write-Host "  VHD Size            : $((Get-SingleValue $result.VHDSizeGB)) GB" -ForegroundColor White
        Write-Host "  VHD Type            : $((Get-SingleValue $result.VHDType))" -ForegroundColor White
    } else {
        Write-Host "  Create VHD          : No (attach manually later)" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "[Network]" -ForegroundColor Magenta
    if ((Get-SingleValue $result.AddNetworkAdapter)) {
        Write-Host "  Network Adapter     : Yes" -ForegroundColor White
        Write-Host "  Virtual Switch      : $((Get-SingleValue $result.SwitchName))" -ForegroundColor White
        Write-Host "  MAC Address Type    : $((Get-SingleValue $result.MACAddressType))" -ForegroundColor White
        if ((Get-SingleValue $result.MACAddressType) -eq 'Static' -and (Get-SingleValue $result.StaticMACAddress)) {
            Write-Host "  Static MAC          : $((Get-SingleValue $result.StaticMACAddress))" -ForegroundColor White
        }
    } else {
        Write-Host "  Network Adapter     : No (configure manually later)" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "[Options]" -ForegroundColor DarkYellow
    Write-Host "  Start After Creation: $((Get-SingleValue $result.StartAfterCreation))" -ForegroundColor White
    Write-Host "  Auto Checkpoints    : $((Get-SingleValue $result.EnableAutomaticCheckpoints))" -ForegroundColor White
    Write-Host "  Integration Services: $((Get-SingleValue $result.EnableIntegrationServices))" -ForegroundColor White
    if ((Get-SingleValue $result.VMNotes)) {
        Write-Host "  Notes               : $((Get-SingleValue $result.VMNotes))" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""

    # Check if Hyper-V module is available
    if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
        Write-Host "[WARNING] Hyper-V PowerShell module is not installed!" -ForegroundColor Yellow
        Write-Host "   This script will show the configuration but cannot create the VM." -ForegroundColor Yellow
        Write-Host "   Install the Hyper-V role to enable VM creation." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    # Ask for confirmation
    Write-Host "Would you like to create this VM now? (Y/N): " -NoNewline -ForegroundColor Yellow
    $confirmation = Read-Host
    
    if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
        try {
            Write-Host ""
            Write-Host "Creating virtual machine..." -ForegroundColor Cyan
            
            # Create VM
            $vmParams = @{
                Name = (Get-SingleValue $result.VMName)
                Generation = $genNumber
                Path = (Get-SingleValue $result.VMPath)
                MemoryStartupBytes = [int64](Get-SingleValue $result.MemoryStartupMB) * 1MB
            }
            
            $vm = New-VM @vmParams
            Write-Host "[OK] VM created successfully" -ForegroundColor Green
            
            # Configure memory
            if ((Get-SingleValue $result.EnableDynamicMemory)) {
                Set-VMMemory -VMName (Get-SingleValue $result.VMName) `
                    -DynamicMemoryEnabled $true `
                    -MinimumBytes ([int64](Get-SingleValue $result.MemoryMinimumMB) * 1MB) `
                    -MaximumBytes ([int64](Get-SingleValue $result.MemoryMaximumMB) * 1MB)
                Write-Host "[OK] Dynamic memory configured" -ForegroundColor Green
            }
            
            # Configure processors
            Set-VMProcessor -VMName (Get-SingleValue $result.VMName) -Count ([int](Get-SingleValue $result.ProcessorCount))
            Write-Host "[OK] Processors configured" -ForegroundColor Green
            
            # Create and attach VHD
            if ((Get-SingleValue $result.CreateNewVHD)) {
                $vhdPath = Join-Path (Get-SingleValue $result.VMPath) (Get-SingleValue $result.VHDName)
                $vhdSizeBytes = [int64](Get-SingleValue $result.VHDSizeGB) * 1GB
                
                if ((Get-SingleValue $result.VHDType) -eq 'Fixed Size') {
                    New-VHD -Path $vhdPath -SizeBytes $vhdSizeBytes -Fixed | Out-Null
                } else {
                    New-VHD -Path $vhdPath -SizeBytes $vhdSizeBytes -Dynamic | Out-Null
                }
                
                Add-VMHardDiskDrive -VMName (Get-SingleValue $result.VMName) -Path $vhdPath
                Write-Host "[OK] Virtual hard disk created and attached" -ForegroundColor Green
            }
            
            # Configure network
            if ((Get-SingleValue $result.AddNetworkAdapter)) {
                $switchExists = Get-VMSwitch -Name (Get-SingleValue $result.SwitchName) -ErrorAction SilentlyContinue
                if ($switchExists) {
                    Connect-VMNetworkAdapter -VMName (Get-SingleValue $result.VMName) -SwitchName (Get-SingleValue $result.SwitchName)
                    Write-Host "[OK] Network adapter connected" -ForegroundColor Green
                    
                    if ((Get-SingleValue $result.MACAddressType) -eq 'Static' -and (Get-SingleValue $result.StaticMACAddress)) {
                        Set-VMNetworkAdapter -VMName (Get-SingleValue $result.VMName) -StaticMacAddress (Get-SingleValue $result.StaticMACAddress)
                        Write-Host "[OK] Static MAC address configured" -ForegroundColor Green
                    }
                } else {
                    Write-Host "[WARNING] Virtual switch '$((Get-SingleValue $result.SwitchName))' not found - skipped network configuration" -ForegroundColor Yellow
                }
            }
            
            # Configure checkpoints
            if ((Get-SingleValue $result.EnableAutomaticCheckpoints)) {
                Set-VM -Name (Get-SingleValue $result.VMName) -AutomaticCheckpointsEnabled $true
                Write-Host "[OK] Automatic checkpoints enabled" -ForegroundColor Green
            }
            
            # Set notes
            if ((Get-SingleValue $result.VMNotes)) {
                Set-VM -Name (Get-SingleValue $result.VMName) -Notes (Get-SingleValue $result.VMNotes)
                Write-Host "[OK] VM notes saved" -ForegroundColor Green
            }
            
            # Start VM if requested
            if ((Get-SingleValue $result.StartAfterCreation)) {
                Start-VM -Name (Get-SingleValue $result.VMName)
                Write-Host "[OK] VM started" -ForegroundColor Green
            }
            
            Write-Host ""
            Write-Host "===============================================================" -ForegroundColor Cyan
            Write-Host "  VIRTUAL MACHINE CREATED SUCCESSFULLY!" -ForegroundColor Green
            Write-Host "===============================================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "VM Name: $((Get-SingleValue $result.VMName))" -ForegroundColor White
            Write-Host "Use Hyper-V Manager or PowerShell to manage this VM." -ForegroundColor White
            Write-Host ""
            
        } catch {
            Write-Host ""
            Write-Host "[ERROR] Failed to create VM" -ForegroundColor Red
            Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
            Write-Host ""
        }
    } else {
        Write-Host ""
        Write-Host "VM creation cancelled." -ForegroundColor Yellow
        Write-Host ""
    }
}


