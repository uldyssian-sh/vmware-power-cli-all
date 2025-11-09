# Getting Started with VMware PowerCLI

Welcome to VMware PowerCLI! This tutorial will guide you through your first steps with PowerCLI, from installation to performing basic vSphere operations.

## What is VMware PowerCLI?

VMware PowerCLI is a powerful command-line tool built on PowerShell that allows you to automate and manage your VMware vSphere environment. With PowerCLI, you can:

- Automate virtual machine management
- Configure and monitor ESXi hosts
- Manage vCenter Server settings
- Generate comprehensive reports
- Perform bulk operations efficiently

## Prerequisites

Before starting, ensure you have:
- PowerShell 5.1 or later (PowerShell 7.x recommended)
- Network access to your vCenter Server or ESXi hosts
- Valid credentials for your VMware environment
- Basic PowerShell knowledge (helpful but not required)

## Step 1: Installation

### Quick Installation

Use our automated installer for the easiest setup:

```powershell
# Download and run the installer
irm https://raw.githubusercontent.com/uldyssian-sh/vmware-power-cli-all/main/Install-PowerCLI-All.ps1 | iex
```

### Manual Installation

If you prefer manual installation:

```powershell
# Clone the repository
git clone https://github.com/uldyssian-sh/vmware-power-cli-all.git
cd vmware-power-cli-all

# Run the installer with options
.\Install-PowerCLI-All.ps1 -TrustPSGallery -DisableCeip
```

### Verify Installation

```powershell
# Check if PowerCLI is installed
Get-Module -ListAvailable VMware.*

# Import PowerCLI
Import-Module VMware.PowerCLI

# Check version
Get-PowerCLIVersion
```

## Step 2: Initial Configuration

### Configure PowerCLI Settings

```powershell
# Disable CEIP (Customer Experience Improvement Program)
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false

# Configure certificate handling (adjust for your environment)
# For lab environments:
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# For production environments:
Set-PowerCLIConfiguration -InvalidCertificateAction Warn -Confirm:$false

# Set default server mode to handle multiple connections
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false
```

### View Current Configuration

```powershell
# Display all PowerCLI configuration settings
Get-PowerCLIConfiguration
```

## Step 3: Connect to vCenter Server

### Basic Connection

```powershell
# Connect to vCenter Server
Connect-VIServer -Server vcenter.example.com

# You'll be prompted for credentials
# Or provide credentials directly:
$credential = Get-Credential
Connect-VIServer -Server vcenter.example.com -Credential $credential
```

### Advanced Connection Options

```powershell
# Connect with specific protocol
Connect-VIServer -Server vcenter.example.com -Protocol https

# Connect to multiple vCenter servers
Connect-VIServer -Server vcenter1.example.com, vcenter2.example.com

# Connect with session timeout
Connect-VIServer -Server vcenter.example.com -SessionIdleTimeoutMinutes 60
```

### Verify Connection

```powershell
# Check connected servers
$global:DefaultVIServers

# Get connection details
Get-VIServer | Format-Table Name, Version, Build, User
```

## Step 4: Basic PowerCLI Operations

### Explore Your Environment

```powershell
# Get datacenters
Get-Datacenter

# Get clusters
Get-Cluster

# Get ESXi hosts
Get-VMHost

# Get virtual machines (first 10)
Get-VM | Select-Object -First 10
```

### Virtual Machine Operations

```powershell
# Get specific VM
Get-VM -Name "WebServer01"

# Get VMs by pattern
Get-VM -Name "Web*"

# Get VM details
Get-VM -Name "WebServer01" | Format-List *

# Check VM power state
Get-VM | Select-Object Name, PowerState | Format-Table
```

### Basic VM Management

```powershell
# Start a VM
Start-VM -VM "WebServer01"

# Stop a VM (graceful shutdown)
Stop-VM -VM "WebServer01" -Confirm:$false

# Restart a VM
Restart-VM -VM "WebServer01" -Confirm:$false

# Suspend a VM
Suspend-VM -VM "WebServer01" -Confirm:$false
```

### Get VM Information

```powershell
# Get VM configuration details
Get-VM -Name "WebServer01" | Select-Object Name, NumCpu, MemoryGB, ProvisionedSpaceGB, UsedSpaceGB

# Get VM network information
Get-VM -Name "WebServer01" | Get-NetworkAdapter

# Get VM storage information
Get-VM -Name "WebServer01" | Get-HardDisk
```

## Step 5: Working with ESXi Hosts

### Host Information

```powershell
# Get all hosts
Get-VMHost

# Get host details
Get-VMHost -Name "esxi01.example.com" | Format-List *

# Get host hardware information
Get-VMHost | Select-Object Name, Model, ProcessorType, NumCpu, MemoryTotalGB
```

### Host Management

```powershell
# Enter maintenance mode
Set-VMHost -VMHost "esxi01.example.com" -State Maintenance

# Exit maintenance mode
Set-VMHost -VMHost "esxi01.example.com" -State Connected

# Restart host
Restart-VMHost -VMHost "esxi01.example.com" -Confirm:$false
```

## Step 6: Working with Datastores

### Datastore Information

```powershell
# Get all datastores
Get-Datastore

# Get datastore details
Get-Datastore | Select-Object Name, Type, CapacityGB, FreeSpaceGB, @{
    Name = 'UsedSpaceGB'
    Expression = { [math]::Round($_.CapacityGB - $_.FreeSpaceGB, 2) }
}

# Get datastores with low free space
Get-Datastore | Where-Object { ($_.FreeSpaceGB / $_.CapacityGB) -lt 0.1 }
```

## Step 7: Creating Your First Automation Script

### Simple VM Report Script

Create a file called `vm-report.ps1`:

```powershell
# Simple VM Report Script
param(
    [Parameter(Mandatory=$true)]
    [string]$vCenterServer
)

# Connect to vCenter
Connect-VIServer -Server $vCenterServer

# Generate report
$report = Get-VM | Select-Object @{
    Name = 'VM Name'
    Expression = { $_.Name }
}, @{
    Name = 'Power State'
    Expression = { $_.PowerState }
}, @{
    Name = 'vCPUs'
    Expression = { $_.NumCpu }
}, @{
    Name = 'Memory (GB)'
    Expression = { $_.MemoryGB }
}, @{
    Name = 'Used Space (GB)'
    Expression = { [math]::Round($_.UsedSpaceGB, 2) }
}, @{
    Name = 'Host'
    Expression = { (Get-VMHost -VM $_).Name }
}

# Display report
$report | Format-Table -AutoSize

# Export to CSV
$report | Export-Csv -Path "VM-Report-$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation

# Disconnect
Disconnect-VIServer -Server $vCenterServer -Confirm:$false

Write-Host "Report generated successfully!" -ForegroundColor Green
```

### Run the script:

```powershell
.\vm-report.ps1 -vCenterServer "vcenter.example.com"
```

## Step 8: Best Practices

### Error Handling

```powershell
try {
    Connect-VIServer -Server "vcenter.example.com" -ErrorAction Stop
    # Your operations here
}
catch {
    Write-Error "Failed to connect: $($_.Exception.Message)"
    exit 1
}
finally {
    # Cleanup
    Disconnect-VIServer -Server * -Confirm:$false -ErrorAction SilentlyContinue
}
```

### Using Filters Efficiently

```powershell
# Good - filter at source
Get-VM -Name "Web*" | Where-Object { $_.PowerState -eq "PoweredOn" }

# Better - use Get-View for large datasets
Get-View -ViewType VirtualMachine -Filter @{"Name" = "Web*"; "Runtime.PowerState" = "poweredOn"}
```

### Credential Management

```powershell
# Store credentials securely
$credential = Get-Credential
$credential | Export-Clixml -Path "C:\Secure\vcenter-creds.xml"

# Load credentials
$credential = Import-Clixml -Path "C:\Secure\vcenter-creds.xml"
Connect-VIServer -Server "vcenter.example.com" -Credential $credential
```

## Step 9: Common Tasks and Examples

### Bulk VM Operations

```powershell
# Start all VMs with "Test" in the name
Get-VM -Name "*Test*" | Where-Object { $_.PowerState -eq "PoweredOff" } | Start-VM

# Set memory for multiple VMs
Get-VM -Name "Web*" | Set-VM -MemoryGB 8 -Confirm:$false

# Create snapshots for multiple VMs
Get-VM -Name "Prod*" | New-Snapshot -Name "Before-Update" -Description "Pre-update snapshot"
```

### Resource Monitoring

```powershell
# Get CPU and memory usage
Get-VM | Where-Object { $_.PowerState -eq "PoweredOn" } | ForEach-Object {
    $vm = $_
    $stats = Get-Stat -Entity $vm -Stat "cpu.usage.average", "mem.usage.average" -Start (Get-Date).AddHours(-1)

    [PSCustomObject]@{
        VM = $vm.Name
        CPUUsage = ($stats | Where-Object { $_.MetricId -eq "cpu.usage.average" } | Measure-Object -Property Value -Average).Average
        MemoryUsage = ($stats | Where-Object { $_.MetricId -eq "mem.usage.average" } | Measure-Object -Property Value -Average).Average
    }
}
```

### Network Configuration

```powershell
# Get VM network information
Get-VM | Get-NetworkAdapter | Select-Object Parent, Name, Type, NetworkName, MacAddress

# Change VM network
Get-VM -Name "WebServer01" | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName "Production-VLAN" -Confirm:$false
```

## Step 10: Cleanup and Disconnection

### Proper Cleanup

```powershell
# Disconnect from all vCenter servers
Disconnect-VIServer -Server * -Confirm:$false

# Clear variables (optional)
Remove-Variable -Name DefaultVIServers -ErrorAction SilentlyContinue
```

## Next Steps

Now that you've completed this tutorial, you can:

1. **Explore Advanced Features**:
   - [Advanced VM Management](advanced-vm-management.md)
   - [Host Configuration](host-configuration.md)
   - [Storage Management](storage-management.md)

2. **Learn Automation**:
   - [PowerCLI Scripting Best Practices](scripting-best-practices.md)
   - [Scheduled Automation](scheduled-automation.md)
   - [Error Handling and Logging](error-handling.md)

3. **Join the Community**:
   - [VMware PowerCLI Community](https://communities.vmware.com/t5/VMware-PowerCLI/bd-p/2006)
   - [PowerShell Community](https://devblogs.microsoft.com/powershell-community/)

## Troubleshooting

If you encounter issues:

1. Check the [Troubleshooting Guide](../troubleshooting/common-issues.md)
2. Verify your PowerCLI installation: `Get-PowerCLIVersion`
3. Check connectivity: `Test-NetConnection -ComputerName vcenter.example.com -Port 443`
4. Review PowerCLI configuration: `Get-PowerCLIConfiguration`

## Additional Resources

- [VMware PowerCLI Documentation](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.powercli.ug.doc/)
- [PowerCLI Cmdlet Reference](https://developer.vmware.com/docs/powercli/)
- [VMware Code Samples](https://github.com/vmware/PowerCLI-Example-Scripts)

Happy automating with PowerCLI! 🚀# Updated Sun Nov  9 12:23:42 CET 2025
