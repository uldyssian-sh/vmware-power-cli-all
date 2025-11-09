# Basic vCenter Connection Example
# This script demonstrates how to connect to a vCenter Server using PowerCLI

#Requires -Modules VMware.PowerCLI

<#
.SYNOPSIS
    Connect to VMware vCenter Server with secure credential handling
    
.DESCRIPTION
    This example shows the basic pattern for connecting to vCenter Server
    using PowerCLI with proper credential management and error handling.
    
.PARAMETER Server
    The vCenter Server hostname or IP address
    
.PARAMETER Credential
    PSCredential object for authentication
    
.EXAMPLE
    .\connect-vcenter.ps1 -Server "vcenter.example.com"
    
.EXAMPLE
    $cred = Get-Credential
    .\connect-vcenter.ps1 -Server "vcenter.example.com" -Credential $cred
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Server,
    
    [Parameter(Mandatory = $false)]
    [PSCredential]$Credential
)

# Import PowerCLI module
try {
    Import-Module VMware.PowerCLI -ErrorAction Stop
    Write-Host "✓ PowerCLI module imported successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to import PowerCLI module: $($_.Exception.Message)"
    exit 1
}

# Configure PowerCLI settings for better security
try {
    # Disable CEIP participation
    Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false | Out-Null
    
    # Set certificate validation (adjust based on your environment)
    Set-PowerCLIConfiguration -InvalidCertificateAction Warn -Confirm:$false | Out-Null
    
    Write-Host "✓ PowerCLI configuration updated" -ForegroundColor Green
}
catch {
    Write-Warning "Could not update PowerCLI configuration: $($_.Exception.Message)"
}

# Get credentials if not provided
if (-not $Credential) {
    try {
        $Credential = Get-Credential -Message "Enter credentials for vCenter Server: $Server"
        if (-not $Credential) {
            Write-Error "Credentials are required to connect to vCenter Server"
            exit 1
        }
    }
    catch {
        Write-Error "Failed to get credentials: $($_.Exception.Message)"
        exit 1
    }
}

# Connect to vCenter Server
try {
    Write-Host "Connecting to vCenter Server: $Server..." -ForegroundColor Yellow
    
    $connection = Connect-VIServer -Server $Server -Credential $Credential -ErrorAction Stop
    
    Write-Host "✓ Successfully connected to vCenter Server: $($connection.Name)" -ForegroundColor Green
    Write-Host "  Version: $($connection.Version)" -ForegroundColor Cyan
    Write-Host "  Build: $($connection.Build)" -ForegroundColor Cyan
    Write-Host "  User: $($connection.User)" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to connect to vCenter Server '$Server': $($_.Exception.Message)"
    exit 1
}

# Display basic environment information
try {
    Write-Host "`nEnvironment Information:" -ForegroundColor Yellow
    
    # Get datacenter count
    $datacenters = Get-Datacenter -ErrorAction SilentlyContinue
    Write-Host "  Datacenters: $($datacenters.Count)" -ForegroundColor Cyan
    
    # Get cluster count
    $clusters = Get-Cluster -ErrorAction SilentlyContinue
    Write-Host "  Clusters: $($clusters.Count)" -ForegroundColor Cyan
    
    # Get ESXi host count
    $vmhosts = Get-VMHost -ErrorAction SilentlyContinue
    Write-Host "  ESXi Hosts: $($vmhosts.Count)" -ForegroundColor Cyan
    
    # Get VM count
    $vms = Get-VM -ErrorAction SilentlyContinue
    Write-Host "  Virtual Machines: $($vms.Count)" -ForegroundColor Cyan
}
catch {
    Write-Warning "Could not retrieve environment information: $($_.Exception.Message)"
}

# Example: List first 5 VMs
try {
    Write-Host "`nFirst 5 Virtual Machines:" -ForegroundColor Yellow
    
    $sampleVMs = Get-VM | Select-Object -First 5
    if ($sampleVMs) {
        $sampleVMs | Format-Table Name, PowerState, NumCpu, MemoryGB, @{
            Name = 'UsedSpaceGB'
            Expression = { [math]::Round($_.UsedSpaceGB, 2) }
        } -AutoSize
    }
    else {
        Write-Host "  No virtual machines found" -ForegroundColor Gray
    }
}
catch {
    Write-Warning "Could not retrieve virtual machine information: $($_.Exception.Message)"
}

# Connection cleanup reminder
Write-Host "`nConnection established successfully!" -ForegroundColor Green
Write-Host "Remember to disconnect when finished:" -ForegroundColor Yellow
Write-Host "  Disconnect-VIServer -Server '$Server' -Confirm:`$false" -ForegroundColor Gray

# Optional: Keep session open for interactive use
$keepOpen = Read-Host "`nKeep connection open for interactive use? (y/N)"
if ($keepOpen -notmatch '^[Yy]') {
    try {
        Disconnect-VIServer -Server $Server -Confirm:$false
        Write-Host "✓ Disconnected from vCenter Server" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not disconnect cleanly: $($_.Exception.Message)"
    }
# Complete refresh Sun Nov  9 12:26:27 CET 2025
# Auto-updated 20251109_123235
