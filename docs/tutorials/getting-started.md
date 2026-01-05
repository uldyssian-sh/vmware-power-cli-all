# Getting Started Tutorial

## Overview
Quick start guide for using the VMware PowerCLI All toolkit.

## Prerequisites

### System Requirements
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or PowerShell 7+
- VMware PowerCLI 12.0+
- Network access to vCenter/ESXi

### Installation
1. Clone the repository
2. Install PowerCLI modules
3. Configure environment
4. Test connectivity

## First Steps

### 1. Connect to vCenter
```powershell
# Import the toolkit
Import-Module .\Install-PowerCLI-All.ps1

# Connect to vCenter
Connect-VIServer -Server vcenter.example.com
```

### 2. Basic VM Operations
```powershell
# List all VMs
Get-VM

# Get VM information
Get-VM -Name "TestVM" | Select Name, PowerState, NumCpu, MemoryGB
```

### 3. Host Management
```powershell
# List ESXi hosts
Get-VMHost

# Get host information
Get-VMHost | Select Name, ConnectionState, Version
```

## Common Tasks

### VM Management
```powershell
# Create new VM
New-VM -Name "NewVM" -VMHost (Get-VMHost)[0] -Datastore (Get-Datastore)[0]

# Power operations
Start-VM -VM "NewVM"
Stop-VM -VM "NewVM" -Confirm:$false
```

### Storage Operations
```powershell
# List datastores
Get-Datastore | Select Name, FreeSpaceGB, CapacityGB

# Storage information
Get-Datastore | Where {$_.FreeSpaceGB -lt 10}
```

### Network Configuration
```powershell
# List port groups
Get-VirtualPortGroup

# Network adapter information
Get-VM | Get-NetworkAdapter
```

## Best Practices

### Error Handling
```powershell
try {
    $vm = Get-VM -Name "TestVM" -ErrorAction Stop
    Write-Host "VM found: $($vm.Name)"
} catch {
    Write-Error "VM not found: $($_.Exception.Message)"
}
```

### Logging
```powershell
# Enable transcript logging
Start-Transcript -Path "C:\Logs\PowerCLI-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

## Next Steps
1. Explore advanced scripts in the examples folder
2. Review best practices documentation
3. Set up automated workflows
4. Join the PowerCLI community

## Troubleshooting
- Check PowerCLI version compatibility
- Verify network connectivity
- Review credential configuration
- Check VMware documentation