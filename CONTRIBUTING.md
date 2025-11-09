# Contributing to VMware PowerCLI Complete Installation Suite

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## 🤝 Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## 🚀 Getting Started

### Prerequisites

- PowerShell 5.1+ or PowerShell 7.x
- Git
- A GitHub account
- Basic knowledge of PowerShell scripting

### Development Setup

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR-USERNAME/vmware-power-cli-all.git
   cd vmware-power-cli-all
   ```

2. **Set up development environment**
   ```powershell
   # Install development dependencies
   Install-Module -Name Pester -Force -Scope CurrentUser
   Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📝 Contribution Types

### Bug Reports
- Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml)
- Include PowerShell version, OS, and error details
- Provide steps to reproduce the issue

### Feature Requests
- Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml)
- Explain the use case and expected behavior
- Consider backward compatibility

### Code Contributions
- Follow PowerShell best practices
- Include appropriate tests
- Update documentation as needed

## 🔧 Development Guidelines

### PowerShell Style Guide

1. **Naming Conventions**
   ```powershell
   # Use approved verbs
   function Get-VMwareModule { }

   # Use PascalCase for functions and variables
   $ModulePath = "C:\Modules"

   # Use descriptive parameter names
   param(
       [string]$ServerName,
       [switch]$TrustCertificate
   )
   ```

2. **Error Handling**
   ```powershell
   try {
       # Risky operation
       Install-Module -Name VMware.PowerCLI -ErrorAction Stop
   }
   catch {
       Write-Error "Failed to install module: $($_.Exception.Message)"
       return
   }
   ```

3. **Help Documentation**
   ```powershell
   <#
   .SYNOPSIS
       Brief description of the function

   .DESCRIPTION
       Detailed description of what the function does

   .PARAMETER ParameterName
       Description of the parameter

   .EXAMPLE
       Example of how to use the function
   #>
   ```

### Testing Requirements

1. **Unit Tests**
   - All new functions must have Pester tests
   - Tests should cover success and failure scenarios
   - Aim for >80% code coverage

2. **Integration Tests**
   - Test real-world scenarios
   - Validate cross-platform compatibility

3. **Security Tests**
   - Ensure no hardcoded credentials
   - Validate input sanitization
   - Check for information disclosure

### Code Quality

1. **PSScriptAnalyzer**
   ```powershell
   # Run before committing
   Invoke-ScriptAnalyzer -Path . -Recurse
   ```

2. **Formatting**
   - Use consistent indentation (4 spaces)
   - Keep lines under 120 characters
   - Use meaningful variable names

## 🧪 Testing Your Changes

### Local Testing

```powershell
# Run all tests
Invoke-Pester -Path .\tests\ -Output Detailed

# Run specific test file
Invoke-Pester -Path .\tests\Install-PowerCLI-All.Tests.ps1

# Run with code coverage
$config = New-PesterConfiguration
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = ".\Install-PowerCLI-All.ps1"
Invoke-Pester -Configuration $config
```

### Cross-Platform Testing

Test on multiple platforms:
- Windows PowerShell 5.1
- PowerShell 7.x on Windows
- PowerShell 7.x on macOS
- PowerShell 7.x on Linux

## 📋 Pull Request Process

1. **Before Submitting**
   - [ ] All tests pass locally
   - [ ] PSScriptAnalyzer shows no errors
   - [ ] Documentation is updated
   - [ ] CHANGELOG.md is updated

2. **Pull Request Template**
   - Use the provided [PR template](.github/PULL_REQUEST_TEMPLATE/pull_request_template.md)
   - Provide clear description of changes
   - Link related issues

3. **Review Process**
   - Maintainers will review within 48 hours
   - Address feedback promptly
   - Keep PR scope focused and small

## 📚 Documentation Standards

### README Updates
- Keep examples current and tested
- Update badges and stats
- Maintain consistent formatting

### Code Comments
```powershell
# Single-line comments for brief explanations
Write-Host "Installing PowerCLI..." -ForegroundColor Green

<#
Multi-line comments for complex logic
or detailed explanations
#>
```

### Wiki Contributions
- Use clear, concise language
- Include code examples
- Add screenshots where helpful

## 🔒 Security Guidelines

### Sensitive Information
- Never commit credentials or API keys
- Use placeholder values in examples
- Sanitize log outputs

### Code Security
- Validate all inputs
- Use secure communication protocols
- Follow principle of least privilege

## 🏷️ Release Process

### Versioning
We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Changelog
Update [CHANGELOG.md](CHANGELOG.md) with:
- New features
- Bug fixes
- Breaking changes
- Deprecations

## 🎯 Project Roadmap

### Current Priorities
1. Cross-platform compatibility improvements
2. Enhanced error handling and diagnostics
3. Performance optimizations
4. Extended test coverage

### Future Goals
- PowerShell Gallery module packaging
- GUI installer option
- Advanced configuration management
- Integration with CI/CD pipelines

## 💬 Communication

### Channels
- **Issues**: Bug reports and feature requests
- **Discussions**: General questions and ideas
- **Pull Requests**: Code contributions

### Response Times
- Issues: Within 24 hours
- Pull Requests: Within 48 hours
- Security Issues: Within 4 hours

## 🏆 Recognition

Contributors will be:
- Listed in the README acknowledgments
- Mentioned in release notes
- Invited to join the maintainer team (for significant contributions)

## 📞 Getting Help

If you need help with contributing:
1. Check existing [issues](https://github.com/uldyssian-sh/vmware-power-cli-all/issues)
2. Start a [discussion](https://github.com/uldyssian-sh/vmware-power-cli-all/discussions)
3. Review the [wiki](https://github.com/uldyssian-sh/vmware-power-cli-all/wiki)

Thank you for contributing to make this project better! 🙏# Updated Sun Nov  9 12:23:42 CET 2025
# Complete refresh Sun Nov  9 12:26:27 CET 2025
# Auto-updated 20251109_123235
# Updated Sun Nov  9 12:50:13 CET 2025
