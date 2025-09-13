# Advanced VM Inventory Report Generator
# This script creates a comprehensive inventory report of all virtual machines

#Requires -Modules VMware.PowerCLI

<#
.SYNOPSIS
    Generate comprehensive VM inventory report with advanced metrics
    
.DESCRIPTION
    Creates detailed inventory reports including VM configuration, performance,
    storage, networking, and compliance information. Supports multiple output
    formats and can be scheduled for regular execution.
    
.PARAMETER Server
    vCenter Server hostname or IP address
    
.PARAMETER OutputPath
    Path where the report files will be saved
    
.PARAMETER Format
    Output format: CSV, HTML, JSON, or Excel
    
.PARAMETER IncludePerformance
    Include performance metrics in the report
    
.PARAMETER IncludeSnapshots
    Include snapshot information
    
.PARAMETER Credential
    PSCredential object for vCenter authentication
    
.EXAMPLE
    .\vm-inventory-report.ps1 -Server "vcenter.example.com" -OutputPath "C:\Reports"
    
.EXAMPLE
    .\vm-inventory-report.ps1 -Server "vcenter.example.com" -Format HTML -IncludePerformance -IncludeSnapshots
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Server,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Reports",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("CSV", "HTML", "JSON", "Excel")]
    [string]$Format = "CSV",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludePerformance,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeSnapshots,
    
    [Parameter(Mandatory = $false)]
    [PSCredential]$Credential
)

# Initialize script
$ErrorActionPreference = "Stop"
$startTime = Get-Date
$reportDate = $startTime.ToString("yyyy-MM-dd_HH-mm-ss")

Write-Host "=== VM Inventory Report Generator ===" -ForegroundColor Cyan
Write-Host "Start Time: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "✓ Created output directory: $OutputPath" -ForegroundColor Green
}

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

# Initialize collections
$vmInventory = @()
$performanceData = @()
$snapshotData = @()

try {
    # Get all VMs
    Write-Host "Collecting VM inventory..." -ForegroundColor Yellow
    $allVMs = Get-VM
    $totalVMs = $allVMs.Count
    Write-Host "Found $totalVMs virtual machines" -ForegroundColor Cyan
    
    # Process each VM
    $counter = 0
    foreach ($vm in $allVMs) {
        $counter++
        $percentComplete = [math]::Round(($counter / $totalVMs) * 100, 1)
        Write-Progress -Activity "Processing VMs" -Status "VM: $($vm.Name)" -PercentComplete $percentComplete
        
        try {
            # Basic VM information
            $vmHost = Get-VMHost -VM $vm
            $cluster = Get-Cluster -VM $vm -ErrorAction SilentlyContinue
            $datacenter = Get-Datacenter -VM $vm
            $folder = Get-Folder -VM $vm
            
            # VM configuration details
            $vmView = Get-View -VIObject $vm
            $vmConfig = $vmView.Config
            
            # Network information
            $networkAdapters = Get-NetworkAdapter -VM $vm
            $networks = ($networkAdapters | ForEach-Object { $_.NetworkName }) -join "; "
            
            # Storage information
            $datastores = Get-Datastore -VM $vm
            $datastoreNames = ($datastores | ForEach-Object { $_.Name }) -join "; "
            
            # Hardware information
            $vmHardware = $vmView.Config.Hardware
            
            # Create VM inventory object
            $vmInfo = [PSCustomObject]@{
                Name = $vm.Name
                PowerState = $vm.PowerState
                OperatingSystem = $vmConfig.GuestFullName
                VMwareTools = $vm.ExtensionData.Guest.ToolsStatus
                vCPUs = $vm.NumCpu
                MemoryGB = $vm.MemoryGB
                ProvisionedSpaceGB = [math]::Round($vm.ProvisionedSpaceGB, 2)
                UsedSpaceGB = [math]::Round($vm.UsedSpaceGB, 2)
                VMHost = $vmHost.Name
                Cluster = if ($cluster) { $cluster.Name } else { "N/A" }
                Datacenter = $datacenter.Name
                Folder = $folder.Name
                Networks = $networks
                Datastores = $datastoreNames
                HardwareVersion = $vmConfig.Version
                CPUReservation = $vmConfig.CpuAllocation.Reservation
                MemoryReservation = $vmConfig.MemoryAllocation.Reservation
                CPULimit = if ($vmConfig.CpuAllocation.Limit -eq -1) { "Unlimited" } else { $vmConfig.CpuAllocation.Limit }
                MemoryLimit = if ($vmConfig.MemoryAllocation.Limit -eq -1) { "Unlimited" } else { $vmConfig.MemoryAllocation.Limit }
                NumDisks = $vmHardware.Device | Where-Object { $_ -is [VMware.Vim.VirtualDisk] } | Measure-Object | Select-Object -ExpandProperty Count
                NumNICs = $networkAdapters.Count
                CreatedDate = $vmConfig.CreateDate
                ModifiedDate = $vmConfig.ModifiedDate
                UUID = $vmConfig.Uuid
                InstanceUUID = $vmConfig.InstanceUuid
                Annotation = $vm.Notes
            }
            
            $vmInventory += $vmInfo
            
            # Collect performance data if requested
            if ($IncludePerformance -and $vm.PowerState -eq "PoweredOn") {
                try {
                    $stats = Get-Stat -Entity $vm -Stat "cpu.usage.average", "mem.usage.average" -Start (Get-Date).AddHours(-24) -Finish (Get-Date) -ErrorAction SilentlyContinue
                    
                    if ($stats) {
                        $cpuAvg = ($stats | Where-Object { $_.MetricId -eq "cpu.usage.average" } | Measure-Object -Property Value -Average).Average
                        $memAvg = ($stats | Where-Object { $_.MetricId -eq "mem.usage.average" } | Measure-Object -Property Value -Average).Average
                        
                        $perfInfo = [PSCustomObject]@{
                            VMName = $vm.Name
                            CPUUsageAvg24h = [math]::Round($cpuAvg, 2)
                            MemoryUsageAvg24h = [math]::Round($memAvg, 2)
                        }
                        
                        $performanceData += $perfInfo
                    }
                }
                catch {
                    Write-Warning "Could not collect performance data for VM: $($vm.Name)"
                }
            }
            
            # Collect snapshot data if requested
            if ($IncludeSnapshots) {
                try {
                    $snapshots = Get-Snapshot -VM $vm -ErrorAction SilentlyContinue
                    foreach ($snapshot in $snapshots) {
                        $snapInfo = [PSCustomObject]@{
                            VMName = $vm.Name
                            SnapshotName = $snapshot.Name
                            Description = $snapshot.Description
                            Created = $snapshot.Created
                            SizeGB = [math]::Round($snapshot.SizeGB, 2)
                            IsCurrent = $snapshot.IsCurrent
                        }
                        
                        $snapshotData += $snapInfo
                    }
                }
                catch {
                    Write-Warning "Could not collect snapshot data for VM: $($vm.Name)"
                }
            }
        }
        catch {
            Write-Warning "Error processing VM '$($vm.Name)': $($_.Exception.Message)"
        }
    }
    
    Write-Progress -Activity "Processing VMs" -Completed
    Write-Host "✓ Collected inventory for $($vmInventory.Count) VMs" -ForegroundColor Green
    
    # Generate reports
    Write-Host "Generating reports..." -ForegroundColor Yellow
    
    $baseFileName = "VM-Inventory-Report_$reportDate"
    
    switch ($Format) {
        "CSV" {
            $csvPath = Join-Path $OutputPath "$baseFileName.csv"
            $vmInventory | Export-Csv -Path $csvPath -NoTypeInformation
            Write-Host "✓ CSV report saved: $csvPath" -ForegroundColor Green
            
            if ($IncludePerformance -and $performanceData.Count -gt 0) {
                $perfCsvPath = Join-Path $OutputPath "VM-Performance-Report_$reportDate.csv"
                $performanceData | Export-Csv -Path $perfCsvPath -NoTypeInformation
                Write-Host "✓ Performance CSV saved: $perfCsvPath" -ForegroundColor Green
            }
            
            if ($IncludeSnapshots -and $snapshotData.Count -gt 0) {
                $snapCsvPath = Join-Path $OutputPath "VM-Snapshots-Report_$reportDate.csv"
                $snapshotData | Export-Csv -Path $snapCsvPath -NoTypeInformation
                Write-Host "✓ Snapshots CSV saved: $snapCsvPath" -ForegroundColor Green
            }
        }
        
        "JSON" {
            $jsonPath = Join-Path $OutputPath "$baseFileName.json"
            $reportData = @{
                GeneratedDate = $startTime
                vCenterServer = $Server
                TotalVMs = $vmInventory.Count
                VMInventory = $vmInventory
            }
            
            if ($IncludePerformance) { $reportData.PerformanceData = $performanceData }
            if ($IncludeSnapshots) { $reportData.SnapshotData = $snapshotData }
            
            $reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
            Write-Host "✓ JSON report saved: $jsonPath" -ForegroundColor Green
        }
        
        "HTML" {
            $htmlPath = Join-Path $OutputPath "$baseFileName.html"
            
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>VM Inventory Report - $Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2E86AB; }
        h2 { color: #A23B72; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .summary { background-color: #e7f3ff; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>VM Inventory Report</h1>
    <div class="summary">
        <strong>vCenter Server:</strong> $Server<br>
        <strong>Generated:</strong> $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))<br>
        <strong>Total VMs:</strong> $($vmInventory.Count)
    </div>
    
    <h2>Virtual Machine Inventory</h2>
    $($vmInventory | ConvertTo-Html -Fragment)
"@
            
            if ($IncludePerformance -and $performanceData.Count -gt 0) {
                $html += "<h2>Performance Data (24h Average)</h2>`n"
                $html += $performanceData | ConvertTo-Html -Fragment
            }
            
            if ($IncludeSnapshots -and $snapshotData.Count -gt 0) {
                $html += "<h2>Snapshot Information</h2>`n"
                $html += $snapshotData | ConvertTo-Html -Fragment
            }
            
            $html += "</body></html>"
            
            $html | Out-File -FilePath $htmlPath -Encoding UTF8
            Write-Host "✓ HTML report saved: $htmlPath" -ForegroundColor Green
        }
    }
    
    # Generate summary statistics
    Write-Host "`n=== Report Summary ===" -ForegroundColor Cyan
    Write-Host "Total VMs: $($vmInventory.Count)" -ForegroundColor White
    Write-Host "Powered On: $(($vmInventory | Where-Object { $_.PowerState -eq 'PoweredOn' }).Count)" -ForegroundColor Green
    Write-Host "Powered Off: $(($vmInventory | Where-Object { $_.PowerState -eq 'PoweredOff' }).Count)" -ForegroundColor Red
    Write-Host "Total vCPUs: $(($vmInventory | Measure-Object -Property vCPUs -Sum).Sum)" -ForegroundColor White
    Write-Host "Total Memory (GB): $(($vmInventory | Measure-Object -Property MemoryGB -Sum).Sum)" -ForegroundColor White
    Write-Host "Total Provisioned Storage (GB): $([math]::Round(($vmInventory | Measure-Object -Property ProvisionedSpaceGB -Sum).Sum, 2))" -ForegroundColor White
    
    if ($IncludeSnapshots -and $snapshotData.Count -gt 0) {
        Write-Host "Total Snapshots: $($snapshotData.Count)" -ForegroundColor Yellow
        Write-Host "Snapshot Storage (GB): $([math]::Round(($snapshotData | Measure-Object -Property SizeGB -Sum).Sum, 2))" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Error during report generation: $($_.Exception.Message)"
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
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Host "`nReport completed in $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
}