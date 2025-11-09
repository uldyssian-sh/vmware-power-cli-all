# Troubleshooting Common Issues

This guide covers the most common issues encountered when installing and using VMware PowerCLI, along with their solutions.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Connection Issues](#connection-issues)
- [Authentication Issues](#authentication-issues)
- [Performance Issues](#performance-issues)
- [Module Loading Issues](#module-loading-issues)
- [Certificate Issues](#certificate-issues)
- [Network Issues](#network-issues)
- [Advanced Troubleshooting](#advanced-troubleshooting)

## Installation Issues

### Issue: "Execution of scripts is disabled on this system"

**Error Message:**
```
.\Install-PowerCLI-All.ps1 : File cannot be loaded because running scripts is disabled on this system.
```

**Cause:** PowerShell execution policy is set to Restricted.

**Solutions:**

1. **Temporary bypass (recommended for testing):**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   .\Install-PowerCLI-All.ps1
   ```

2. **Permanent change for current user:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Check current policy:**
   ```powershell
   Get-ExecutionPolicy -List
   ```

### Issue: "Administrator rights are required"

**Error Message:**
```
Install-Module : Administrator rights are required to install modules in 'C:\Program Files\WindowsPowerShell\Modules'.
```

**Cause:** Script is attempting to install to system-wide location instead of user scope.

**Solution:**
Our script already uses `-Scope CurrentUser`, but if you encounter this:

```powershell
# Verify user module path exists
$userModulePath = if ($PSVersionTable.PSEdition -eq 'Core') {
    Join-Path $HOME 'Documents\PowerShell\Modules'
} else {
    Join-Path $HOME 'Documents\WindowsPowerShell\Modules'
}

# Create if it doesn't exist
if (-not (Test-Path $userModulePath)) {
    New-Item -Path $userModulePath -ItemType Directory -Force
}

# Ensure it's in PSModulePath
if ($env:PSModulePath -notlike "*$userModulePath*") {
    $env:PSModulePath = "$userModulePath;$env:PSModulePath"
}
```

### Issue: "Package provider 'NuGet' is not available"

**Error Message:**
```
Install-Module : NuGet provider is required to interact with NuGet-based repositories.
```

**Solution:**
```powershell
# Install NuGet provider for current user
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser

# If that fails, try bootstrapping
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
```

### Issue: "PowerShell Gallery is untrusted"

**Error Message:**
```
Untrusted repository
You are installing the modules from an untrusted repository...
```

**Solutions:**

1. **Use the -TrustPSGallery parameter:**
   ```powershell
   .\Install-PowerCLI-All.ps1 -TrustPSGallery
   ```

2. **Manually trust the repository:**
   ```powershell
   Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
   ```

3. **Answer 'Yes' to the prompt during installation**

## Connection Issues

### Issue: "Could not connect using the requested protocol"

**Error Message:**
```
Connect-VIServer : Could not connect using the requested protocol.
```

**Causes and Solutions:**

1. **Incorrect server name/IP:**
   ```powershell
   # Test connectivity
   Test-NetConnection -ComputerName vcenter.example.com -Port 443

   # Try with IP address instead of hostname
   Connect-VIServer -Server 192.168.1.100
   ```

2. **Port blocking:**
   ```powershell
   # Test specific ports
   Test-NetConnection -ComputerName vcenter.example.com -Port 443  # HTTPS
   Test-NetConnection -ComputerName vcenter.example.com -Port 80   # HTTP
   ```

3. **Protocol issues:**
   ```powershell
   # Force specific protocol
   Connect-VIServer -Server vcenter.example.com -Protocol https
   ```

### Issue: "The underlying connection was closed"

**Error Message:**
```
The underlying connection was closed: Could not establish trust relationship for the SSL/TLS secure channel.
```

**Cause:** SSL certificate issues.

**Solutions:**

1. **Ignore certificate warnings (not recommended for production):**
   ```powershell
   Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
   ```

2. **Warn about certificates but continue:**
   ```powershell
   Set-PowerCLIConfiguration -InvalidCertificateAction Warn -Confirm:$false
   ```

3. **Install proper certificates in production environments**

## Authentication Issues

### Issue: "Login failure"

**Error Message:**
```
Connect-VIServer : Login failure
```

**Solutions:**

1. **Verify credentials:**
   ```powershell
   # Use Get-Credential for secure input
   $cred = Get-Credential
   Connect-VIServer -Server vcenter.example.com -Credential $cred
   ```

2. **Check domain authentication:**
   ```powershell
   # For domain users, use domain\username format
   $cred = Get-Credential -UserName "domain\username"
   Connect-VIServer -Server vcenter.example.com -Credential $cred
   ```

3. **Try different authentication methods:**
   ```powershell
   # Use UPN format
   Connect-VIServer -Server vcenter.example.com -User "user@domain.com"

   # Use local vCenter account
   Connect-VIServer -Server vcenter.example.com -User "administrator@vsphere.local"
   ```

### Issue: "The session is not authenticated"

**Cause:** Session timeout or authentication token expired.

**Solution:**
```powershell
# Reconnect to refresh session
Disconnect-VIServer -Server * -Confirm:$false
Connect-VIServer -Server vcenter.example.com
```

## Performance Issues

### Issue: Slow module import

**Symptoms:** PowerCLI takes a long time to import.

**Solutions:**

1. **Import specific modules only:**
   ```powershell
   # Instead of importing all PowerCLI
   Import-Module VMware.VimAutomation.Core
   ```

2. **Use module auto-loading:**
   ```powershell
   # Don't import explicitly, let PowerShell auto-load
   Connect-VIServer -Server vcenter.example.com
   ```

3. **Check for conflicting modules:**
   ```powershell
   # List all VMware modules
   Get-Module -ListAvailable VMware.*

   # Remove old versions
   Get-Module VMware.* | Where-Object { $_.Version -lt "12.0" } | Uninstall-Module
   ```

### Issue: Slow cmdlet execution

**Solutions:**

1. **Use filtering at the source:**
   ```powershell
   # Good - filter on server
   Get-VM -Name "web*"

   # Bad - filter locally
   Get-VM | Where-Object { $_.Name -like "web*" }
   ```

2. **Limit returned properties:**
   ```powershell
   Get-VM | Select-Object Name, PowerState, NumCpu
   ```

3. **Use Get-View for better performance:**
   ```powershell
   # Faster for large datasets
   Get-View -ViewType VirtualMachine -Property Name, Runtime.PowerState
   ```

## Module Loading Issues

### Issue: "Module 'VMware.PowerCLI' was not imported"

**Solutions:**

1. **Check module installation:**
   ```powershell
   Get-Module -ListAvailable VMware.*
   ```

2. **Verify module path:**
   ```powershell
   $env:PSModulePath -split ';'
   ```

3. **Manual import:**
   ```powershell
   Import-Module VMware.PowerCLI -Force
   ```

4. **Reinstall if necessary:**
   ```powershell
   Uninstall-Module VMware.PowerCLI -AllVersions
   .\Install-PowerCLI-All.ps1
   ```

### Issue: "Multiple versions of the same module"

**Error Message:**
```
WARNING: The names of some imported commands from the module 'VMware.VimAutomation.Core' include unapproved verbs...
```

**Solution:**
```powershell
# Remove old versions
Get-Module VMware.* -ListAvailable |
    Group-Object Name |
    ForEach-Object {
        $_.Group | Sort-Object Version -Descending | Select-Object -Skip 1
    } |
    Uninstall-Module -Force
```

## Certificate Issues

### Issue: Self-signed certificate warnings

**Solutions:**

1. **For lab environments:**
   ```powershell
   Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
   ```

2. **For production (install proper certificates):**
   ```powershell
   # Import certificate to trusted root
   Import-Certificate -FilePath "vcenter-cert.crt" -CertStoreLocation Cert:\LocalMachine\Root
   ```

3. **Temporary bypass:**
   ```powershell
   Connect-VIServer -Server vcenter.example.com -Force
   ```

## Network Issues

### Issue: Proxy server blocking connections

**Solutions:**

1. **Configure proxy:**
   ```powershell
   # Set proxy for current session
   $proxy = New-Object System.Net.WebProxy('http://proxy.company.com:8080')
   $proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
   [System.Net.WebRequest]::DefaultWebProxy = $proxy
   ```

2. **Bypass proxy for vCenter:**
   ```powershell
   # Add vCenter to proxy bypass list
   $proxy.BypassProxyOnLocal = $true
   $proxy.BypassList = @("vcenter.example.com", "*.local")
   ```

### Issue: Firewall blocking connections

**Solutions:**

1. **Check required ports:**
   - **443 (HTTPS)** - Primary vCenter communication
   - **80 (HTTP)** - Redirects to HTTPS
   - **9443** - vSphere Web Client

2. **Test connectivity:**
   ```powershell
   Test-NetConnection -ComputerName vcenter.example.com -Port 443
   ```

## Advanced Troubleshooting

### Enable Debug Logging

```powershell
# Enable verbose logging
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# Run commands with detailed output
Connect-VIServer -Server vcenter.example.com -Verbose -Debug
```

### PowerShell Transcription

```powershell
# Start transcript for session logging
Start-Transcript -Path "C:\Logs\PowerCLI-Session.log"

# Your PowerCLI commands here

# Stop transcript
Stop-Transcript
```

### Network Tracing

```powershell
# Enable .NET network tracing (advanced)
$env:DOTNET_SYSTEM_NET_HTTP_SOCKETSHTTPHANDLER_HTTP2SUPPORT = "false"
```

### Module Diagnostic Information

```powershell
# Get detailed module information
Get-Module VMware.PowerCLI | Format-List *

# Check module dependencies
Get-Module VMware.PowerCLI | Select-Object -ExpandProperty RequiredModules

# Verify module integrity
Get-AuthenticodeSignature (Get-Module VMware.PowerCLI).Path
```

### Environment Information Collection

```powershell
# Collect environment information for support
$info = @{
    PowerShellVersion = $PSVersionTable
    OperatingSystem = [System.Environment]::OSVersion
    DotNetVersion = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
    PowerCLIModules = Get-Module VMware.* -ListAvailable
    ExecutionPolicy = Get-ExecutionPolicy -List
    ModulePath = $env:PSModulePath -split ';'
}

$info | ConvertTo-Json -Depth 3 | Out-File "PowerCLI-Environment.json"
```

## Getting Additional Help

If these solutions don't resolve your issue:

1. **Check the [VMware PowerCLI Documentation](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.powercli.ug.doc/)**
2. **Visit the [VMware PowerCLI Community](https://communities.vmware.com/t5/VMware-PowerCLI/bd-p/2006)**
3. **Create an issue in our [GitHub repository](https://github.com/uldyssian-sh/vmware-power-cli-all/issues)**
4. **Check VMware KB articles for specific error messages**

## Preventive Measures

### Regular Maintenance

```powershell
# Update PowerCLI regularly
Update-Module VMware.PowerCLI -Force

# Clean up old module versions
Get-InstalledModule VMware.* | ForEach-Object {
    Get-InstalledModule $_.Name -AllVersions |
    Sort-Object Version -Descending |
    Select-Object -Skip 1 |
    Uninstall-Module -Force
}
```

### Health Checks

```powershell
# Verify PowerCLI health
Import-Module VMware.PowerCLI
Get-PowerCLIVersion
Test-Path (Get-Module VMware.PowerCLI).ModuleBase
```

Remember: Always test solutions in a non-production environment first!# Updated Sun Nov  9 12:23:42 CET 2025
# Complete refresh Sun Nov  9 12:26:27 CET 2025
