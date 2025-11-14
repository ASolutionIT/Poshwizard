# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.4.x   | Yes                |
| 1.3.x   | Yes                |
| 1.2.x   | No                 |
| < 1.2   | No                 |

## Security Features

PoshWizard includes several built-in security features:

### Secure Password Handling
- Uses `SecureString` for password parameters
- Masked input with optional reveal button
- Passwords never logged in plaintext
- Secure conversion only when needed

### Secure Temporary File Handling
- Temporary scripts created with restricted file ACLs
- Automatic cleanup of temporary files after execution
- Restricted access to wizard-generated files
- Proper file permissions prevent unauthorized access

### Audit Logging
- CMTrace-compatible structured logging
- All script executions logged with timestamps
- Parameter passing logged (sensitive data excluded)
- Execution results and errors logged
- Logs stored in `logs/` directory with proper permissions

### Code Signature Verification Support
- Framework for validating signed PowerShell scripts
- Configurable signature verification policies
- Audit logging for security events

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **support@asolutionit.com**

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

Please include the following information:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

This information will help us triage your report more quickly.

## Disclosure Policy

When we receive a security bug report, we will:

1. Confirm the problem and determine the affected versions
2. Audit code to find any similar problems
3. Prepare fixes for all supported releases
4. Release patches as soon as possible

## Security Best Practices for Users

Since PoshWizard executes scripts with full PowerShell capabilities, security depends on proper deployment practices:

### Script Validation & Review
- **Always review PowerShell scripts before deployment** - PoshWizard has no restrictions
- Validate script logic and dependencies
- Test scripts in non-production environments first
- Use code review processes for production scripts

### Code Signing
- Sign all production wizard scripts with code signing certificates
- Implement signature verification policies in your environment
- Maintain secure certificate storage and management
- Document signing procedures for your organization

### Credential Management
- Never hardcode credentials in scripts
- Use Windows Credential Manager or Azure Key Vault for secrets
- Leverage PoshWizard's secure password controls
- Implement MFA for sensitive operations

### Execution Environment
- Run PoshWizard with minimum necessary privileges
- Use AppLocker or other application whitelisting to restrict script execution
- Run in isolated environments for untrusted scripts
- Implement network segmentation for sensitive operations

### Input Validation
- Use PoshWizard's built-in validation attributes
- Implement additional validation in your scripts
- Sanitize all user inputs before use
- Validate data types and ranges

### Logging & Monitoring
- Regularly review execution logs in `logs/` directory
- Monitor for unexpected script behavior or errors
- Configure appropriate log retention policies
- Protect log files from unauthorized access
- Implement centralized logging for audit trails

## Known Security Considerations

### .NET Framework 4.8 Dependency
PoshWizard requires .NET Framework 4.8. Keep this updated with the latest Windows security patches.

### PowerShell 5.1 Compatibility
Designed for Windows PowerShell 5.1. Be aware of PowerShell Core/7+ differences if integrating.

### WPF UI Thread
UI operations run on the main thread. Long-running operations should use background threads to prevent UI freezing.

### Named Pipes Communication
PoshWizard uses named pipes for IPC. Ensure proper access controls in multi-user environments.

## Security Updates

Security updates will be released as patch versions (e.g., 1.4.1 -> 1.4.2) and announced via:

- GitHub Security Advisories
- Release notes in CHANGELOG.md
- Email notifications to registered users

## Compliance

PoshWizard is designed to help users build compliant administrative tools. However:

- Users are responsible for their own compliance requirements
- Audit logging features should be configured per organizational policies
- Data privacy regulations (GDPR, CCPA, etc.) are the user's responsibility

## Contact

For general support and questions:
- **Email**: support@asolutionit.com
- **GitHub Issues**: https://github.com/asolutionit/PoshWizard/issues

---

**Maintained by A Solution IT LLC**

