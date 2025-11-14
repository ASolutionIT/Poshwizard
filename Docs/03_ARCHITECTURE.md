# PoshWizard Architecture

## Overview

PoshWizard uses a **hybrid architecture** that combines the best of both worlds:

- **PowerShell Module** (`PoshWizard.psd1`) - Your scripting interface
- **WPF Executable** (`PoshWizard.exe`) - The professional UI engine

This separation of concerns keeps the codebase clean, maintainable, and extensible.

---

## How It Works: Execution Flow

When you run a PoshWizard script, here's what happens:

```
Your PowerShell Script
    ↓
Import-Module PoshWizard
    ↓
New-PoshWizard, Add-WizardStep, Add-WizardTextBox, etc.
    ↓
Show-PoshWizard
    ↓
[PowerShell Module generates a temporary script]
    ↓
[Module launches PoshWizard.exe with the generated script]
    ↓
[WPF Application displays the wizard UI]
    ↓
[User interacts with the wizard]
    ↓
[User clicks Finish or Cancel]
    ↓
[EXE returns results to PowerShell]
    ↓
Your script processes the results
```

---

## Component Responsibilities

| Component | Responsibility | Technology |
|-----------|-----------------|------------|
| **PowerShell Module** | Define wizard structure, handle logic, process results | PowerShell 5.1 |
| **WPF Executable** | Render UI, collect input, display live execution console | C#, WPF, .NET 4.8 |

### **PowerShell Module (`PoshWizard.psd1`)**

**What it does:**
- Provides cmdlets for defining wizards (`New-PoshWizard`, `Add-WizardStep`, etc.)
- Stores wizard definitions in memory
- Generates temporary PowerShell scripts from your definitions
- Launches the WPF executable with the generated script
- Captures results from the executable
- Cleans up temporary files
- Returns results to your calling script

**Why PowerShell:**
- ✅ Familiar to IT professionals
- ✅ Dynamic and flexible
- ✅ No compilation needed
- ✅ Easy to update and extend
- ✅ Can be modified without rebuilding

### **WPF Executable (`PoshWizard.exe`)**

**What it does:**
- Displays the wizard UI with Windows 11-style design
- Handles user input and validation
- Manages theme switching (light/dark)
- Displays live execution console for `ScriptBody` output
- Handles animations and transitions
- Manages logging and error display
- Returns collected data to the PowerShell module

**Why WPF/C#:**
- ✅ Professional Windows 11-style UI
- ✅ Smooth animations and transitions
- ✅ Real-time execution console
- ✅ Proper theme support (light/dark)
- ✅ Better performance for complex UIs
- ✅ Native Windows integration

---

## Real-World Example: What's Actually Happening

Here's a simple wizard script and what happens under the hood:

```powershell
# Your script (Demo-Simple.ps1)
$modulePath = Join-Path $PSScriptRoot 'PoshWizard\PoshWizard.psd1'
Import-Module $modulePath -Force

# Step 1: Define the wizard
New-PoshWizard -Title 'Server Setup' -Theme 'Auto'

Add-WizardStep -Name 'Config' -Title 'Configuration' -Order 1
Add-WizardTextBox -Step 'Config' -Name 'ServerName' -Label 'Server Name' -Mandatory
Add-WizardDropdown -Step 'Config' -Name 'Environment' -Label 'Environment' `
    -Choices @('Dev', 'Test', 'Prod') -Mandatory

# Step 2: Show the wizard
$result = Show-PoshWizard

# Step 3: Process the results
if ($result) {
    Write-Host "Server: $($result.ServerName)"
    Write-Host "Environment: $($result.Environment)"
}
```

### **What Happens Behind the Scenes**

1. **Module Collects Definitions**
   - `New-PoshWizard` stores wizard metadata
   - Each `Add-Wizard*` call adds a control definition
   - All stored in `$script:CurrentWizard` object

2. **Module Generates Temporary Script**
   - Creates a PowerShell script with a `param()` block
   - Parameters match your control definitions
   - Includes validation attributes (ValidateSet, ValidatePattern, etc.)
   - Includes your `ScriptBody` if provided
   - Saved to a secure temporary file

3. **Module Launches PoshWizard.exe**
   - Passes the temporary script path to the executable
   - Passes wizard metadata (title, theme, branding, etc.)
   - Waits for the executable to complete

4. **WPF Application Displays Wizard**
   - Reads the script to understand the wizard structure
   - Renders the UI based on control types
   - Applies theme (light/dark)
   - Displays each step with navigation

5. **User Interacts with Wizard**
   - User fills in controls
   - Validation happens on Finish (not during navigation)
   - If `ScriptBody` provided, execution console shows real-time output

6. **User Clicks Finish or Cancel**
   - If Finish: Collects all values and returns as JSON
   - If Cancel: Returns null
   - EXE closes and returns to PowerShell

7. **Module Captures Results**
   - Receives JSON from the executable
   - Converts to PowerShell object
   - Cleans up temporary script file

8. **Your Script Continues**
   - `$result` contains the collected data
   - You process it as needed

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   Your PowerShell Script                     │
│                                                              │
│  Import-Module PoshWizard                                   │
│  New-PoshWizard -Title 'My Wizard'                          │
│  Add-WizardStep -Name 'Config'                              │
│  Add-WizardTextBox -Name 'ServerName'                       │
│  $result = Show-PoshWizard                                  │
│  # Process $result                                          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              PowerShell Module (PoshWizard.psm1)             │
│                                                              │
│  • Stores wizard definitions                                │
│  • Generates temporary script                               │
│  • Launches PoshWizard.exe                                  │
│  • Captures results                                         │
│  • Cleans up temporary files                                │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              WPF Executable (PoshWizard.exe)                │
│                                                              │
│  • Renders Windows 11-style UI                              │
│  • Handles user input                                       │
│  • Validates data                                           │
│  • Displays execution console                               │
│  • Manages themes (light/dark)                              │
│  • Returns results as JSON                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Why This Architecture?

### **PowerShell Module Advantages**
- ✅ Familiar scripting interface for IT professionals
- ✅ Dynamic and flexible - build wizards at runtime
- ✅ No compilation needed - update and run immediately
- ✅ Easy to maintain and extend
- ✅ Can be updated without rebuilding the executable

### **WPF Executable Advantages**
- ✅ Professional Windows 11-style UI with modern design
- ✅ Smooth animations and transitions
- ✅ Real-time execution console for live feedback
- ✅ Proper light/dark theme support
- ✅ Better performance for complex UIs
- ✅ Native Windows integration

### **Together: Best of Both Worlds**
- ✅ Easy to script (PowerShell)
- ✅ Beautiful to use (WPF)
- ✅ Maintainable and extensible
- ✅ No external dependencies
- ✅ Single executable distribution

---

## Distribution: Bundled Package

When you distribute PoshWizard, everything is included in one folder:

```
PoshWizard/
├── PoshWizard.psd1              # Module manifest
├── PoshWizard.psm1              # Module implementation
├── bin/
│   └── PoshWizard.exe           # WPF UI engine (code-signed)
├── Public/
│   ├── Core/
│   │   ├── New-PoshWizard.ps1
│   │   ├── Add-WizardStep.ps1
│   │   └── Show-PoshWizard.ps1
│   ├── Controls/
│   │   ├── Add-WizardTextBox.ps1
│   │   ├── Add-WizardDropdown.ps1
│   │   ├── Add-WizardPassword.ps1
│   │   └── ... (other controls)
│   └── Branding/
│       └── Set-WizardBranding.ps1
├── Private/
│   ├── ConvertTo-WizardScript.ps1
│   ├── ArgumentCompleters.ps1
│   └── ... (internal functions)
└── Classes/
    └── WizardDefinition.ps1
```

**Key Points:**
- ✅ No installation required
- ✅ Just import the module and you're ready
- ✅ The EXE is automatically found in the `bin\` folder
- ✅ No external dependencies or NuGet packages
- ✅ Works on any Windows 10/11 or Server 2016+ device

---

## For Developers: Modifying the EXE

If you need to customize the UI or add features to the WPF application:

### **Project Structure**

```
Launcher/                       # C# WPF Application
├── App.xaml                    # Application entry point
├── App.xaml.cs
├── MainWindow.xaml             # Main UI window
├── MainWindow.xaml.cs
├── ViewModels/
│   ├── MainWindowViewModel.cs
│   └── PageViewModel.cs
├── Views/
│   ├── WizardPage.xaml
│   └── ExecutionConsole.xaml
├── Styles/
│   ├── LightTheme.xaml
│   ├── DarkTheme.xaml
│   └── Controls.xaml
├── Controls/
│   ├── CustomControls.xaml
│   └── CustomControls.xaml.cs
└── Properties/
    └── AssemblyInfo.cs
```

### **Build Process**

1. **Modify the C# code** in the `Launcher/` folder
2. **Build the solution**:
   ```powershell
   # Using dotnet CLI
   dotnet build WizardFramework.sln --configuration Release
   
   # Or using MSBuild
   msbuild WizardFramework.sln /p:Configuration=Release
   ```

3. **Build automatically places** `PoshWizard.exe` in `PoshWizard\bin\`
4. **The module automatically finds it** - No additional configuration needed

### **Key Files to Modify**

| File | Purpose |
|------|---------|
| `MainWindow.xaml` | Main UI layout |
| `MainWindow.xaml.cs` | UI logic and event handlers |
| `MainWindowViewModel.cs` | Data binding and theme management |
| `LightTheme.xaml` / `DarkTheme.xaml` | Theme definitions |
| `WizardPage.xaml` | Individual step rendering |

### **Important Notes**

- The module always looks for the EXE in `PoshWizard\bin\PoshWizard.exe`
- You can update the UI without changing any PowerShell code
- The EXE communicates with PowerShell via JSON
- All changes should maintain backward compatibility with the module API

---

## Communication Between Module and EXE

### **Module → EXE**

The module passes:
1. **Script Path** - Path to the generated temporary script
2. **Wizard Metadata** - Title, description, theme, branding
3. **Control Definitions** - Steps, controls, validation rules
4. **ScriptBody** (optional) - Code to execute after wizard completes

### **EXE → Module**

The executable returns:
1. **Exit Code** - 0 for success, non-zero for cancel/error
2. **Results JSON** - Collected parameter values
3. **Execution Output** (if ScriptBody) - Console output and logs

### **Data Format**

Results are returned as JSON and converted to PowerShell objects:

```json
{
  "ServerName": "WEB-SERVER-01",
  "Environment": "Production",
  "AdminPassword": "System.Security.SecureString",
  "EnableSSL": true,
  "InstanceCount": 3
}
```

Converted to PowerShell:

```powershell
$result.ServerName        # "WEB-SERVER-01"
$result.Environment       # "Production"
$result.AdminPassword     # SecureString object
$result.EnableSSL         # $true
$result.InstanceCount     # 3
```

---

## Execution Patterns

### **Pattern 1: Simple Mode (Data Collection)**

```powershell
# Define wizard
New-PoshWizard -Title 'My Wizard'
Add-WizardStep -Name 'Config' -Title 'Configuration' -Order 1
Add-WizardTextBox -Step 'Config' -Name 'ServerName' -Label 'Server'

# Show and collect
$result = Show-PoshWizard

# Process results
if ($result) {
    Write-Host "You selected: $($result.ServerName)"
}
```

**Flow:**
1. Module launches EXE
2. User fills in wizard
3. User clicks Finish
4. EXE returns results
5. Your script processes them

### **Pattern 2: Live Execution Mode (ScriptBody)**

```powershell
# Define wizard
New-PoshWizard -Title 'My Wizard'
Add-WizardStep -Name 'Config' -Title 'Configuration' -Order 1
Add-WizardTextBox -Step 'Config' -Name 'ServerName' -Label 'Server'

# Define execution
$scriptBody = {
    Write-Host "Configuring $ServerName..."
    # Your logic here
    Start-Sleep -Seconds 2
    Write-Host "Done!"
}

# Show and execute
Show-PoshWizard -ScriptBody $scriptBody
```

**Flow:**
1. Module launches EXE
2. User fills in wizard
3. User clicks Finish
4. EXE executes ScriptBody
5. Output displays in execution console
6. EXE returns results
7. Your script continues

---

## Key Takeaway

**You write PowerShell. The module handles the complexity. The EXE provides the beautiful UI. Everyone wins.**

The architecture is designed so you never need to think about the EXE—it just works. But if you need to customize the UI or add features, the separation of concerns makes it straightforward to modify the C# code and rebuild.

---

## Related Documentation

- **README.md** - Getting started and quick start guide
- **PoshWizard_CMDLET_Guide.md** - Complete cmdlet reference
- **CONTROLS_GUIDE.md** - Detailed control documentation
- **CONTRIBUTING.md** - Development guidelines and code standards
