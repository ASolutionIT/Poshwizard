# Contributing to PoshWizard

First off, thank you for considering contributing to PoshWizard! It's people like you that make PoshWizard such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Project Structure](#project-structure)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by the [PoshWizard Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to conduct@asolutionit.com.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/asolutionit/PoshWizard/issues) to avoid duplicates.

When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (script snippets, screenshots, etc.)
- **Describe the behavior you observed** and **what you expected**
- **Include version information**: PoshWizard version, PowerShell version, Windows version, .NET Framework version

**Bug Report Template:**

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Create script with '...'
2. Run wizard with '...'
3. Click on '...'
4. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- PoshWizard Version: [e.g., 1.4.1]
- PowerShell Version: [e.g., 5.1.19041.4648]
- Windows Version: [e.g., Windows 11 23H2]
- .NET Framework: [e.g., 4.8]

**Additional context**
Any other relevant information.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful**
- **Provide examples** of how it would work
- **List any alternative solutions** you've considered

### Pull Requests

1. **Fork the repository** and create your branch from `master`
2. **Make your changes** following our coding standards
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Ensure the code builds** without errors
6. **Write clear commit messages**
7. **Submit a pull request**

**Pull Request Guidelines:**

- Keep PRs focused on a single feature/fix
- Reference any related issues
- Include screenshots for UI changes
- Update CHANGELOG.md
- Add tests if applicable
- Ensure all existing tests pass

## Development Setup

### Prerequisites

- Windows 10/11 (for WPF development)
- Visual Studio 2019/2022 or VS Code
- .NET Framework 4.8 SDK
- PowerShell 5.1 or higher
- Git

### Initial Setup

```powershell
# Clone the repository
git clone https://github.com/asolutionit/PoshWizard.git
cd PoshWizard

# Build the solution
dotnet build WizardFramework.sln --configuration Debug

# Run a demo script to test
.\PoshWizard\Examples\Demo-AllControls.ps1
```

## Building and Testing

### Building

- Run `dotnet build WizardFramework.sln --configuration Debug` to build the solution in debug mode.
- Run `dotnet build WizardFramework.sln --configuration Release` to build the solution in release mode.

### Testing

- Run `.\PoshWizard\Examples\Demo-AllControls.ps1` to test the wizard with a demo script.
- Write unit tests for new code using xUnit.
- Write integration tests for end-to-end scenarios.

## Project Structure

```
PoshWizard/
│   ├── Controls/
│   ├── Converters/
│   ├── Launcher/
│   └── Views/
├── PoshWizard/
│   ├── Public/
│   ├── Private/
│   ├── Classes/
│   ├── bin/
│   └── Examples/
├── Docs/
├── Scripts/
├── Assets/
└── WizardFramework.sln
```

## Coding Standards

### C# Code

- Follow [Microsoft C# Coding Conventions](https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- Use meaningful variable and method names
- Add XML documentation comments for public APIs
- Use async/await for I/O operations
- Keep methods focused and concise (< 50 lines when possible)

**Example:**

```csharp
/// <summary>
/// Loads a PowerShell script and parses its parameters.
/// </summary>
/// <param name="scriptPath">The full path to the PowerShell script.</param>
/// <returns>A ScriptData object containing parsed script information.</returns>
public ScriptData LoadScript(string scriptPath)
{
    // Implementation
}
```

### PowerShell Code

- Follow [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
- Use approved verbs (Get, Set, New, etc.)
- Use PascalCase for function names
- Use camelCase for variables
- Include comment-based help for all exported functions
- **PowerShell 5.1 Compatibility**: Avoid Unicode emojis and glyphs in `.ps1` files. Use ASCII characters only, or save files as UTF-8 with BOM. Reserve emoji usage for Markdown documentation.

**Example:**

```powershell
function Add-WizardTextBox {
    <#
    .SYNOPSIS
    Adds a text box control to a wizard step.
    
    .DESCRIPTION
    Creates a text input field with optional validation, placeholder text,
    and character limits.
    
    .PARAMETER Step
    The name of the wizard step to add the control to.
    
    .PARAMETER Name
    The parameter name for the text box.
    
    .EXAMPLE
    Add-WizardTextBox -Step "User Info" -Name "Username" -Label "Username:" -Mandatory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Step,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Implementation
}
```

### XAML Code

- Use consistent indentation (4 spaces)
- Group related attributes
- Use resource dictionaries for reusable styles
- Follow WPF naming conventions

## Testing Guidelines

PoshWizard uses a three-tier testing strategy focused on PowerShell integration testing:

### Tier 1: PowerShell Integration Tests (Primary - 80%)

**Purpose:** Test actual PowerShell module behavior and end-to-end wizard execution

**Location:** `Tests/Integration/` folder

**What to test:**
- Module loads and exports all cmdlets
- Cmdlets accept correct parameters
- Demo scripts run without errors
- Wizard execution completes successfully
- Return values are correct
- Error handling works properly

**Example test script:**

```powershell
# Tests/Integration/Test-ModuleLoading.ps1
$modulePath = Join-Path $PSScriptRoot '..\..\PoshWizard\PoshWizard.psd1'

# Test 1: Module imports
try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "PASS: Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "FAIL: Module import failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Verify cmdlets exported
$commands = Get-Command -Module PoshWizard -ErrorAction SilentlyContinue
if ($commands.Count -gt 0) {
    Write-Host "PASS: $($commands.Count) cmdlets exported" -ForegroundColor Green
} else {
    Write-Host "FAIL: No cmdlets exported" -ForegroundColor Red
    exit 1
}

# Test 3: Run demo wizard
try {
    & "$PSScriptRoot\..\..\PoshWizard\Examples\Demo-AllControls.ps1"
    Write-Host "PASS: Demo wizard executed" -ForegroundColor Green
} catch {
    Write-Host "FAIL: Demo wizard failed: $_" -ForegroundColor Red
    exit 1
}
```

**Running tests:**
```powershell
# Run all integration tests
Get-ChildItem Tests/Integration/*.ps1 | ForEach-Object { & $_.FullName }
```

### Tier 2: C# Unit Tests (Secondary - 15%)

**Purpose:** Test internal Launcher logic in isolation

**When to use:**
- Testing ReflectionService (script parsing)
- Testing SecurityValidation (blocklist logic)
- Testing parameter extraction
- Testing theme switching logic

**Framework:** xUnit

**Example:**

```csharp
[Fact]
public void LoadScript_ValidPath_ReturnsScriptData()
{
    // Arrange
    var service = new ReflectionService();
    var scriptPath = "path/to/test/script.ps1";
    
    // Act
    var result = service.LoadScript(scriptPath);
    
    // Assert
    Assert.NotNull(result);
}
```

**Coverage goal:** > 70% for critical code paths

### Tier 3: Manual Testing Checklist (Tertiary - 5%)

**Purpose:** Catch UI/UX issues before release

**Before submitting a PR, verify:**

- [ ] All demo scripts run without errors
- [ ] Light and dark themes work correctly
- [ ] All control types render properly
- [ ] Validation works as expected
- [ ] Script execution produces correct output
- [ ] Logs are generated correctly in `logs/` folder
- [ ] Error handling displays user-friendly messages
- [ ] Performance is acceptable (no UI freezing)
- [ ] Theme toggle button works correctly

### CI/CD Pipeline

```
1. Run PowerShell integration tests (quick feedback)
2. Build Release configuration
3. Run C# unit tests (if Launcher changes)
4. Manual testing checklist (before release)
```

### Demo Scripts as Tests

Demo scripts in `PoshWizard/Examples/` serve dual purposes:
1. **Documentation** - Show users how to use PoshWizard
2. **Automated tests** - Validate wizard functionality

When creating demo scripts:
- Include error handling
- Document what the demo demonstrates
- Ensure it runs without user interaction (for CI/CD)
- Validate output where possible

## Creating New Tests

When adding new features:

1. **Add integration test** in `Tests/Integration/Test-FeatureName.ps1`
2. **Add unit tests** if testing internal C# logic
3. **Update demo scripts** to showcase new feature
4. **Run all tests** before submitting PR

## Documentation

### Code Documentation

- Add XML comments to all public C# classes and methods
- Add comment-based help to all exported PowerShell functions
- Keep inline comments focused on "why", not "what"

### User Documentation

- Update relevant `.md` files in `Docs/` folder
- Use numbered filenames for main docs: `01_`, `02_`, `03_`, `04_`
- Include screenshots for UI features
- Provide code examples
- Update `README.md` if adding major features
- Update `CHANGELOG.md` with new features or fixes

### Examples

- Create example scripts in `Examples/` folder
- Include descriptive comments
- Demonstrate best practices
- Show realistic use cases

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
type(scope): subject

body

footer
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**

```
feat(controls): add date picker control with calendar popup

- Implements Add-WizardDate cmdlet
- Adds DatePickerViewModel
- Includes modern Windows 11 styling
- Updates 02_CONTROLS_GUIDE.md
- Updates CHANGELOG.md

Closes #123
```

```
fix(validation): correct regex pattern validation for IP addresses

The IPv4 validation regex was not properly handling edge cases
like 192.168.1.256. Updated to use strict octet validation.

Fixes #456
```

## Building and Testing

### Build Process

```powershell
# Debug build
dotnet build WizardFramework.sln --configuration Debug

# Release build
dotnet build WizardFramework.sln --configuration Release
```

After building, `PoshWizard.exe` will be placed in `PoshWizard/bin/`.

### Testing Your Changes

1. **Run demo scripts** to verify UI and functionality:
   ```powershell
   .\PoshWizard\Examples\Demo-AllControls.ps1
   .\PoshWizard\Examples\Demo-HyperV-CreateVM.ps1
   .\PoshWizard\Examples\Demo-DynamicControls.ps1
   ```

2. **Check logs** in the `logs/` directory for errors

3. **Verify theme switching** works (Light/Dark/Auto)

4. **Test validation** with various input types

## Community

- Join our discussions on [GitHub Discussions](https://github.com/asolutionit/PoshWizard/discussions)
- Report issues on [GitHub Issues](https://github.com/asolutionit/PoshWizard/issues)
- Email: support@asolutionit.com

## Recognition

Contributors will be recognized in:
- The project README.md
- Release notes for contributions
- The project's AUTHORS file (created with first external contributor)

## Important Notes

### PowerShell 5.1 Compatibility

- Avoid Unicode emojis and special glyphs in `.ps1` files
- Use ASCII characters only, or save files as UTF-8 with BOM
- Reserve emoji usage for Markdown documentation only

### No Third-Party Dependencies

- PoshWizard uses only .NET Framework 4.8 and PowerShell 5.1
- Do not add external NuGet packages without explicit approval
- Keep the project lightweight and self-contained

### Documentation Structure

- Main docs use numbered prefixes: `01_`, `02_`, `03_`, `04_`
- This ensures proper ordering in file explorers
- Update table of contents when adding new docs

## Questions?

Feel free to reach out:
- **Email**: support@asolutionit.com
- **GitHub Issues**: [Report bugs or request features](https://github.com/asolutionit/PoshWizard/issues)
- **GitHub Discussions**: [Ask questions and share ideas](https://github.com/asolutionit/PoshWizard/discussions)

---

**Thank you for contributing to PoshWizard!**

Together, we're making PowerShell automation more accessible to everyone.

*Maintained by A Solution IT LLC*

