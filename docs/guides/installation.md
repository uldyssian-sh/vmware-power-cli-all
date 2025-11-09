# Installation Guide

This comprehensive guide covers all aspects of installing VMware PowerCLI using our automated installation suite.

## Table of Contents

- [Quick Start](#quick-start)
- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
- [Advanced Configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)
- [Verification](#verification)

## Quick Start

### One-Line Installation (Recommended)

```powershell
# Download and execute with recommended settings
irm https://raw.githubusercontent.com/uldyssian-sh/vmware-power-cli-all/main/Install-PowerCLI-All.ps1 | iex
```

### Manual Download and Installation

```powershell
# Download the script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/uldyssian-sh/vmware-power-cli-all/main/Install-PowerCLI-All.ps1" -OutFile "Install-PowerCLI-All.ps1"

# Review the script (recommended)
Get-Content .\Install-PowerCLI-All.ps1 | Out-Host -Paging

# Execute with options
.\Install-PowerCLI-All.ps1 -TrustPSGallery -DisableCeip
```

## System Requirements

### Minimum Requirements

| Component | Requirement |
|-----------|-------------|
| **PowerShell** | 5.1 or later |
| **Operating System** | Windows 10, macOS 10.15+, Ubuntu 18.04+ |
| **Memory** | 2 GB RAM |
| **Disk Space** | 500 MB free space |
| **Network** | Internet connection to PowerShell Gallery |

### Recommended Requirements

| Component | Recommendation |
|-----------|----------------|
| **PowerShell** | 7.4 or later |
| **Memory** | 4 GB RAM |
| **Disk Space** | 1 GB free space |
| **Network** | High-speed internet connection |

### Supported Platforms

#### Windows
- Windows 10 (1903 or later)
- Windows 11
- Windows Server 2019
- Windows Server 2022
- PowerShell 5.1 (Windows PowerShell)
- PowerShell 7.x (PowerShell Core)

#### macOS
- macOS 10.15 (Catalina) or later
- PowerShell 7.x only

#### Linux
- Ubuntu 18.04 LTS or later
- CentOS 7 or later
- Red Hat Enterprise Linux 7 or later
- SUSE Linux Enterprise Server 12 or later
- PowerShell 7.x only

## Installation Methods

Our script uses a three-tier fallback strategy to ensure maximum compatibility:

### Method 1: PSResourceGet (Modern)

```powershell
Install-PSResource -Name VMware.PowerCLI -Scope CurrentUser -TrustRepository
```

**Advantages:**
- Modern PowerShell package management
- Better dependency resolution
- Improved performance
- Enhanced security features

**Requirements:**
- PowerShell 7.x
- PSResourceGet module

### Method 2: PowerShellGet (Classic)

```powershell
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Repository PSGallery -AllowClobber -Force
```

**Advantages:**
- Wide compatibility
- Mature and stable
- Works with PowerShell 5.1+

**Requirements:**
- PowerShell 5.1+
- PowerShellGet module
- NuGet provider

### Method 3: Save-Module (Fallback)

```powershell
Save-Module -Name VMware.PowerCLI -Path $TempPath -Repository PSGallery -Force
# Manual staging to user module directory
```

**Advantages:**
- Works in restricted environments
- No direct installation required
- Manual control over module placement

**Use Cases:**
- Corporate environments with installation restrictions
- Air-gapped systems (with manual transfer)
- Troubleshooting installation issues

## Advanced Configuration

### Script Parameters

#### -TrustPSGallery
Marks PowerShell Gallery as a trusted repository to suppress installation prompts.

```powershell
.\Install-PowerCLI-All.ps1 -TrustPSGallery
```

**Benefits:**
- Automated installation without user prompts
- Suitable for scripted deployments
- Reduces installation time

**Security Considerations:**
- Only use in trusted environments
- Review organizational security policies
- Consider using private repositories for sensitive environments

#### -DisableCeip
Opts out of VMware's Customer Experience Improvement Program.

```powershell
.\Install-PowerCLI-All.ps1 -DisableCeip
```

**Privacy Benefits:**
- No telemetry data sent to VMware
- Complies with data privacy requirements
- Reduces network traffic

### Environment Configuration

#### Execution Policy

```powershell
# Check current execution policy
Get-ExecutionPolicy

# Set execution policy for current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Temporary bypass for current session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

#### Module Path Configuration

```powershell
# View current module paths
$env:PSModulePath -split ';'

# Add custom module path (if needed)
$customPath = "C:\CustomModules"
$env:PSModulePath = "$customPath;$env:PSModulePath"
```

### Corporate Environment Setup

#### Proxy Configuration

```powershell
# Configure proxy for PowerShell Gallery access
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy('http://proxy.company.com:8080')
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
```

#### Private Repository Setup

```powershell
# Register private PowerShell repository
Register-PSRepository -Name "CompanyRepo" -SourceLocation "https://nuget.company.com/api/v2" -InstallationPolicy Trusted

# Install from private repository
Install-Module -Name VMware.PowerCLI -Repository CompanyRepo -Scope CurrentUser
```

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Execution of scripts is disabled on this system"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Issue: "Administrator rights are required"

**Cause:** Script is trying to install to AllUsers scope

**Solution:**
- Our script already uses CurrentUser scope
- Check if corporate policy blocks user-scope installations
- Contact IT administrator for assistance

#### Issue: "Unable to download from URI"

**Causes:**
- Network connectivity issues
- Proxy configuration problems
- Firewall restrictions

**Solutions:**
```powershell
# Test connectivity
Test-NetConnection -ComputerName www.powershellgallery.com -Port 443

# Configure TLS version
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check proxy settings
netsh winhttp show proxy
```

#### Issue: "Package provider 'NuGet' is not available"

**Solution:**
```powershell
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
```

#### Issue: "PowerShell Gallery is not trusted"

**Solutions:**
```powershell
# Option 1: Trust PowerShell Gallery
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Option 2: Use -TrustPSGallery parameter
.\Install-PowerCLI-All.ps1 -TrustPSGallery

# Option 3: Answer 'Yes' to prompts during installation
```

### Advanced Troubleshooting

#### Enable Verbose Logging

```powershell
.\Install-PowerCLI-All.ps1 -Verbose -Debug
```

#### Manual Module Installation

```powershell
# Download module manually
Save-Module -Name VMware.PowerCLI -Path "C:\Temp\Modules" -Repository PSGallery

# Copy to user module directory
$userModules = if ($PSVersionTable.PSEdition -eq 'Core') {
    Join-Path $HOME 'Documents\PowerShell\Modules'
} else {
    Join-Path $HOME 'Documents\WindowsPowerShell\Modules'
}

Copy-Item -Path "C:\Temp\Modules\VMware.PowerCLI" -Destination $userModules -Recurse -Force
```

#### Check Module Installation

```powershell
# List installed VMware modules
Get-Module -ListAvailable VMware.*

# Check module versions
Get-Module -ListAvailable VMware.* | Select-Object Name, Version, ModuleBase

# Import specific module
Import-Module VMware.PowerCLI -Force
```

## Verification

### Post-Installation Verification

#### 1. Module Import Test

```powershell
# Import PowerCLI
Import-Module VMware.PowerCLI

# Verify import success
Get-Module VMware.*
```

#### 2. Cmdlet Availability Test

```powershell
# List available PowerCLI cmdlets
Get-Command -Module VMware.* | Measure-Object

# Test specific cmdlets
Get-Command Connect-VIServer
Get-Command Get-VM
```

#### 3. Version Verification

```powershell
# Check PowerCLI version
Get-PowerCLIVersion

# Check individual module versions
Get-Module VMware.* | Format-Table Name, Version
```

#### 4. Configuration Test

```powershell
# Check PowerCLI configuration
Get-PowerCLIConfiguration

# Test connection capability (without actually connecting)
Get-Help Connect-VIServer -Examples
```

### Performance Verification

#### Module Load Time Test

```powershell
Measure-Command { Import-Module VMware.PowerCLI }
```

#### Memory Usage Test

```powershell
# Before import
$beforeMemory = [System.GC]::GetTotalMemory($false)

# Import modules
Import-Module VMware.PowerCLI

# After import
$afterMemory = [System.GC]::GetTotalMemory($false)
$memoryUsed = ($afterMemory - $beforeMemory) / 1MB

Write-Host "Memory used: $($memoryUsed.ToString('F2')) MB"
```

## Next Steps

After successful installation:

1. **Connect to vCenter Server**
   ```powershell
   Connect-VIServer -Server vcenter.example.com
   ```

2. **Explore Available Cmdlets**
   ```powershell
   Get-Command -Module VMware.* | Out-GridView
   ```

3. **Review Documentation**
   - [PowerCLI User Guide](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.powercli.ug.doc/GUID-D93F7E10-B4E1-4F6E-8731-9D8F8F6B3F2A.html)
   - [PowerCLI Cmdlet Reference](https://developer.vmware.com/docs/powercli/)

4. **Join the Community**
   - [VMware PowerCLI Community](https://communities.vmware.com/t5/VMware-PowerCLI/bd-p/2006)
   - [PowerShell Community](https://devblogs.microsoft.com/powershell-community/)

## Support

If you encounter issues not covered in this guide:

1. Check the [Troubleshooting Guide](../troubleshooting/common-issues.md)
2. Search [existing issues](https://github.com/uldyssian-sh/vmware-power-cli-all/issues)
3. Create a [new issue](https://github.com/uldyssian-sh/vmware-power-cli-all/issues/new/choose) with detailed information# Updated Sun Nov  9 12:23:42 CET 2025
# Complete refresh Sun Nov  9 12:26:27 CET 2025
# Auto-updated 20251109_123235
# Updated Sun Nov  9 12:50:13 CET 2025
# Updated Sun Nov  9 12:52:13 CET 2025
