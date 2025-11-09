# Bulk VM Operations Script
# Comprehensive script for performing bulk operations on virtual machines

#Requires -Modules VMware.PowerCLI

<#
.SYNOPSIS
    Perform bulk operations on virtual machines with advanced filtering and safety checks
    
.DESCRIPTION
    This script provides a comprehensive set of bulk operations for virtual machines
    including power management, configuration changes, snapshot management, and reporting.
    All operations include safety checks and confirmation prompts.
    
.PARAMETER Server
    vCenter Server hostname or IP address
    
.PARAMETER Operation
    The operation to perform: PowerOn, PowerOff, Restart, Suspend, Snapshot, RemoveSnapshot, 
    SetMemory, SetCPU, SetNetwork, Report, Clone
    
.PARAMETER Filter
    VM name filter (supports wildcards)
    
.PARAMETER Credential
    PSCredential object for vCenter authentication
    
.PARAMETER WhatIf
    Show what would be done without actually performing the operation
    
.PARAMETER Force
    Skip confirmation prompts (use with caution)
    
.EXAMPLE
    .\bulk-vm-operations.ps1 -Server "vcenter.example.com" -Operation PowerOn -Filter "Test*"
    
.EXAMPLE
    .\bulk-vm-operations.ps1 -Server "vcenter.example.com" -Operation SetMemory -Filter "Web*" -Memory 8
    
.EXAMPLE
    .\bulk-vm-operations.ps1 -Server "vcenter.example.com" -Operation Report -Filter "*" -OutputPath "C:\Reports"
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Server,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("PowerOn", "PowerOff", "Restart", "Suspend", "Snapshot", "RemoveSnapshot", 
                 "SetMemory", "SetCPU", "SetNetwork", "Report", "Clone")]
    [string]$Operation,
    
    [Parameter(Mandatory = $true)]
    [string]$Filter,
    
    [Parameter(Mandatory = $false)]
    [PSCredential]$Credential,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    # Operation-specific parameters
    [Parameter(Mandatory = $false)]
    [int]$Memory,
    
    [Parameter(Mandatory = $false)]
    [int]$CPU,
    
    [Parameter(Mandatory = $false)]
    [string]$NetworkName,
    
    [Parameter(Mandatory = $false)]
    [string]$SnapshotName = "Bulk-Operation-$(Get-Date -Format 'yyyy-MM-dd-HH-mm')",
    
    [Parameter(Mandatory = $false)]
    [string]$SnapshotDescription = "Snapshot created by bulk operations script",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Reports",
    
    [Parameter(Mandatory = $false)]
    [string]$ClonePrefix = "Clone-",
    
    [Parameter(Mandatory = $false)]
    [string]$TargetDatastore,
    
    [Parameter(Mandatory = $false)]
    [string]$TargetHost
)

# Initialize script
$ErrorActionPreference = "Stop"
$startTime = Get-Date

Write-Host "=== Bulk VM Operations Script ===" -ForegroundColor Cyan
Write-Host "Operation: $Operation" -ForegroundColor Yellow
Write-Host "Filter: $Filter" -ForegroundColor Yellow
Write-Host "Server: $Server" -ForegroundColor Yellow
Write-Host "Start Time: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

# Import PowerCLI
try {
    Import-Module VMware.PowerCLI -ErrorAction Stop
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -ParticipateInCEIP $false -Confirm:$false | Out-Null
}
catch {
    Write-Error "Failed to import PowerCLI: $($_.Exception.Message)"
    exit 1
}

# Get credentials if not provided
if (-not $Credential) {
    $Credential = Get-Credential -Message "Enter vCenter credentials for $Server"
}

# Connect to vCenter
try {
    Write-Host "Connecting to vCenter Server: $Server..." -ForegroundColor Yellow
    $viConnection = Connect-VIServer -Server $Server -Credential $Credential
    Write-Host "✓ Connected successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to vCenter: $($_.Exception.Message)"
    exit 1
}

# Function definitions
function Get-FilteredVMs {
    param([string]$FilterPattern)
    
    try {
        $vms = Get-VM -Name $FilterPattern -ErrorAction Stop
        Write-Host "Found $($vms.Count) VMs matching filter '$FilterPattern'" -ForegroundColor Cyan
        return $vms
    }
    catch {
        Write-Warning "No VMs found matching filter '$FilterPattern'"
        return @()
    }
}

function Confirm-Operation {
    param(
        [string]$OperationName,
        [array]$TargetVMs,
        [switch]$Force
    )
    
    if ($Force) {
        return $true
    }
    
    Write-Host "`nOperation: $OperationName" -ForegroundColor Yellow
    Write-Host "Target VMs ($($TargetVMs.Count)):" -ForegroundColor Yellow
    $TargetVMs | Select-Object Name, PowerState | Format-Table -AutoSize
    
    $confirmation = Read-Host "Do you want to proceed? (y/N)"
    return ($confirmation -match '^[Yy]')
}

function Write-OperationResult {
    param(
        [string]$VMName,
        [string]$Operation,
        [bool]$Success,
        [string]$Message = ""
    )
    
    $status = if ($Success) { "✓" } else { "✗" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "$status $VMName - $Operation" -ForegroundColor $color
    if ($Message) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

# Main operation logic
try {
    # Get target VMs
    $targetVMs = Get-FilteredVMs -FilterPattern $Filter
    
    if ($targetVMs.Count -eq 0) {
        Write-Warning "No VMs found. Exiting."
        exit 0
    }
    
    # Initialize results tracking
    $results = @()
    $successCount = 0
    $failureCount = 0
    
    # Perform operation based on type
    switch ($Operation) {
        "PowerOn" {
            $vmsToStart = $targetVMs | Where-Object { $_.PowerState -eq "PoweredOff" }
            
            if ($vmsToStart.Count -eq 0) {
                Write-Host "No powered-off VMs found to start." -ForegroundColor Yellow
                break
            }
            
            if (Confirm-Operation -OperationName "Power On VMs" -TargetVMs $vmsToStart -Force:$Force) {
                foreach ($vm in $vmsToStart) {
                    try {
                        if ($PSCmdlet.ShouldProcess($vm.Name, "Power On")) {
                            Start-VM -VM $vm -Confirm:$false | Out-Null
                            Write-OperationResult -VMName $vm.Name -Operation "Power On" -Success $true
                            $successCount++
                        }
                    }
                    catch {
                        Write-OperationResult -VMName $vm.Name -Operation "Power On" -Success $false -Message $_.Exception.Message
                        $failureCount++
                    }
                }
            }
        }
        
        "PowerOff" {
            $vmsToStop = $targetVMs | Where-Object { $_.PowerState -eq "PoweredOn" }
            
            if ($vmsToStop.Count -eq 0) {
                Write-Host "No powered-on VMs found to stop." -ForegroundColor Yellow
                break
            }
            
            if (Confirm-Operation -OperationName "Power Off VMs (Graceful Shutdown)" -TargetVMs $vmsToStop -Force:$Force) {
                foreach ($vm in $vmsToStop) {
                    try {
                        if ($PSCmdlet.ShouldProcess($vm.Name, "Power Off")) {
                            Stop-VM -VM $vm -Confirm:$false | Out-Null
                            Write-OperationResult -VMName $vm.Name -Operation "Power Off" -Success $true
                            $successCount++
                        }
                    }
                    catch {
                        Write-OperationResult -VMName $vm.Name -Operation "Power Off" -Success $false -Message $_.Exception.Message
                        $failureCount++
                    }
                }
            }
        }
        
        "Restart" {
            $vmsToRestart = $targetVMs | Where-Object { $_.PowerState -eq "PoweredOn" }
            
            if ($vmsToRestart.Count -eq 0) {
                Write-Host "No powered-on VMs found to restart." -ForegroundColor Yellow
                break
            }
            
            if (Confirm-Operation -OperationName "Restart VMs" -TargetVMs $vmsToRestart -Force:$Force) {
                foreach ($vm in $vmsToRestart) {
                    try {
                        if ($PSCmdlet.ShouldProcess($vm.Name, "Restart")) {
                            Restart-VM -VM $vm -Confirm:$false | Out-Null
                            Write-OperationResult -VMName $vm.Name -Operation "Restart" -Success $true
                            $successCount++
                        }
                    }
                    catch {
                        Write-OperationResult -VMName $vm.Name -Operation "Restart" -Success $false -Message $_.Exception.Message
                        $failureCount++
                    }
                }
            }
        }
        
        "Suspend" {
            $vmsToSuspend = $targetVMs | Where-Object { $_.PowerState -eq "PoweredOn" }
            
            if ($vmsToSuspend.Count -eq 0) {
                Write-Host "No powered-on VMs found to suspend." -ForegroundColor Yellow
                break
            }
            
            if (Confirm-Operation -OperationName "Suspend VMs" -TargetVMs $vmsToSuspend -Force:$Force) {
                foreach ($vm in $vmsToSuspend) {
                    try {
                        if ($PSCmdlet.ShouldProcess($vm.Name, "Suspend")) {
                            Suspend-VM -VM $vm -Confirm:$false | Out-Null
                            Write-OperationResult -VMName $vm.Name -Operation "Suspend" -Success $true
                            $successCount++
                        }
                    }
                    catch {
                        Write-OperationResult -VMName $vm.Name -Operation "Suspend" -Success $false -Message $_.Exception.Message
                        $failureCount++
                    }
                }
            }
        }
        
        "Snapshot" {
            if (Confirm-Operation -OperationName "Create Snapshots" -TargetVMs $targetVMs -Force:$Force) {
                foreach ($vm in $targetVMs) {
                    try {
                        if ($PSCmdlet.ShouldProcess($vm.Name, "Create Snapshot")) {
                            New-Snapshot -VM $vm -Name $SnapshotName -Description $SnapshotDescription -Confirm:$false | Out-Null
                            Write-OperationResult -VMName $vm.Name -Operation "Create Snapshot" -Success $true -Message "Name: $SnapshotName"
                            $successCount++
                        }
                    }
                    catch {
                        Write-OperationResult -VMName $vm.Name -Operation "Create Snapshot" -Success $false -Message $_.Exception.Message
                        $failureCount++
                    }
                }
            }
        }
        
        "RemoveSnapshot" {
            $vmsWithSnapshots = $targetVMs | Where-Object { (Get-Snapshot -VM $_ -ErrorAction SilentlyContinue).Count -gt 0 }
            
            if ($vmsWithSnapshots.Count -eq 0) {
                Write-Host "No VMs with snapshots found." -ForegroundColor Yellow
                break
            }
            
            if (Confirm-Operation -OperationName "Remove All Snapshots" -TargetVMs $vmsWithSnapshots -Force:$Force) {
                foreach ($vm in $vmsWithSnapshots) {
                    try {
                        if ($PSCmdlet.ShouldProcess($vm.Name, "Remove All Snapshots")) {
                            Get-Snapshot -VM $vm | Remove-Snapshot -Confirm:$false | Out-Null
                            Write-OperationResult -VMName $vm.Name -Operation "Remove Snapshots" -Success $true
                            $successCount++
                        }
                    }
                    catch {
                        Write-OperationResult -VMName $vm.Name -Operation "Remove Snapshots" -Success $false -Message $_.Exception.Message
                        $failureCount++
                    }
                }
            }
        }
        
        "SetMemory" {
            if (-not $Memory) {
                Write-Error "Memory parameter is required for SetMemory operation"
                exit 1
            }
            
            if (Confirm-Operation -OperationName "Set Memory to $Memory GB" -TargetVMs $targetVMs -Force:$Force) {
                foreach ($vm in $targetVMs) {
                    try {
                        if ($PSCmdlet.ShouldProcess($vm.Name, "Set Memory to $Memory GB")) {
                            Set-VM -VM $vm -MemoryGB $Memory -Confirm:$false | Out-Null
                            Write-OperationResult -VMName $vm.Name -Operation "Set Memory" -Success $true -Message "$Memory GB"
                            $successCount++
                        }
                    }
                    catch {
                        Write-OperationResult -VMName $vm.Name -Operation "Set Memory" -Success $false -Message $_.Exception.Message
                        $failureCount++
                    }
                }
            }
        }
        
        "SetCPU" {
            if (-not $CPU) {
                Write-Error "CPU parameter is required for SetCPU operation"
                exit 1
            }
            
            if (Confirm-Operation -OperationName "Set CPU to $CPU cores" -TargetVMs $targetVMs -Force:$Force) {
                foreach ($vm in $targetVMs) {
                    try {
                        if ($PSCmdlet.ShouldProcess($vm.Name, "Set CPU to $CPU cores")) {
                            Set-VM -VM $vm -NumCpu $CPU -Confirm:$false | Out-Null
                            Write-OperationResult -VMName $vm.Name -Operation "Set CPU" -Success $true -Message "$CPU cores"
                            $successCount++
                        }
                    }
                    catch {
                        Write-OperationResult -VMName $vm.Name -Operation "Set CPU" -Success $false -Message $_.Exception.Message
                        $failureCount++
                    }
                }
            }
        }
        
        "SetNetwork" {
            if (-not $NetworkName) {
                Write-Error "NetworkName parameter is required for SetNetwork operation"
                exit 1
            }
            
            if (Confirm-Operation -OperationName "Set Network to $NetworkName" -TargetVMs $targetVMs -Force:$Force) {
                foreach ($vm in $targetVMs) {
                    try {
                        if ($PSCmdlet.ShouldProcess($vm.Name, "Set Network to $NetworkName")) {
                            Get-NetworkAdapter -VM $vm | Set-NetworkAdapter -NetworkName $NetworkName -Confirm:$false | Out-Null
                            Write-OperationResult -VMName $vm.Name -Operation "Set Network" -Success $true -Message $NetworkName
                            $successCount++
                        }
                    }
                    catch {
                        Write-OperationResult -VMName $vm.Name -Operation "Set Network" -Success $false -Message $_.Exception.Message
                        $failureCount++
                    }
                }
            }
        }
        
        "Report" {
            Write-Host "Generating comprehensive VM report..." -ForegroundColor Yellow
            
            if (-not (Test-Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            }
            
            $reportData = foreach ($vm in $targetVMs) {
                try {
                    $vmHost = Get-VMHost -VM $vm
                    $cluster = Get-Cluster -VM $vm -ErrorAction SilentlyContinue
                    $datastores = Get-Datastore -VM $vm
                    $networkAdapters = Get-NetworkAdapter -VM $vm
                    
                    [PSCustomObject]@{
                        Name = $vm.Name
                        PowerState = $vm.PowerState
                        vCPUs = $vm.NumCpu
                        MemoryGB = $vm.MemoryGB
                        ProvisionedSpaceGB = [math]::Round($vm.ProvisionedSpaceGB, 2)
                        UsedSpaceGB = [math]::Round($vm.UsedSpaceGB, 2)
                        Host = $vmHost.Name
                        Cluster = if ($cluster) { $cluster.Name } else { "N/A" }
                        Datastores = ($datastores.Name -join "; ")
                        Networks = ($networkAdapters.NetworkName -join "; ")
                        OperatingSystem = $vm.Guest.OSFullName
                        VMwareTools = $vm.Guest.ToolsStatus
                        HardwareVersion = $vm.HardwareVersion
                        CreatedDate = $vm.CreateDate
                    }
                    $successCount++
                }
                catch {
                    Write-Warning "Error processing VM '$($vm.Name)': $($_.Exception.Message)"
                    $failureCount++
                }
            }
            
            $reportPath = Join-Path $OutputPath "Bulk-VM-Report-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').csv"
            $reportData | Export-Csv -Path $reportPath -NoTypeInformation
            
            Write-Host "✓ Report generated: $reportPath" -ForegroundColor Green
            Write-Host "Report contains $($reportData.Count) VMs" -ForegroundColor Cyan
        }
    }
    
    # Display summary
    Write-Host "`n=== Operation Summary ===" -ForegroundColor Cyan
    Write-Host "Operation: $Operation" -ForegroundColor White
    Write-Host "Total VMs Processed: $($targetVMs.Count)" -ForegroundColor White
    Write-Host "Successful Operations: $successCount" -ForegroundColor Green
    Write-Host "Failed Operations: $failureCount" -ForegroundColor Red
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
}
catch {
    Write-Error "Error during bulk operation: $($_.Exception.Message)"
}
finally {
    # Cleanup
    try {
        Disconnect-VIServer -Server $Server -Confirm:$false
        Write-Host "✓ Disconnected from vCenter" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not disconnect cleanly from vCenter"
    }
}# Complete refresh Sun Nov  9 12:26:27 CET 2025
# Auto-updated 20251109_123235
# Updated Sun Nov  9 12:52:13 CET 2025
