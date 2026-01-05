# Grafana Integration Guide

## Overview
This guide explains how to integrate PowerCLI with Grafana for VMware infrastructure monitoring and visualization.

## Prerequisites

### Grafana Setup
- Grafana 8.0 or later
- InfluxDB or Prometheus data source
- Grafana API access
- Network connectivity

### PowerCLI Requirements
- VMware PowerCLI 12.0 or later
- PowerShell 5.1 or PowerShell 7+
- InfluxDB or Prometheus PowerShell modules

## Architecture Options

### Option 1: PowerCLI → InfluxDB → Grafana
```
vCenter → PowerCLI → InfluxDB → Grafana
```

### Option 2: PowerCLI → Prometheus → Grafana
```
vCenter → PowerCLI → Prometheus → Grafana
```

### Option 3: PowerCLI → Grafana API
```
vCenter → PowerCLI → Grafana API
```

## InfluxDB Integration

### Install InfluxDB Module
```powershell
Install-Module -Name InfluxDB -Force
```

### Connect to InfluxDB
```powershell
function Connect-InfluxDB {
    param(
        [string]$Server = "localhost",
        [int]$Port = 8086,
        [string]$Database = "vmware",
        [string]$Username = $null,
        [string]$Password = $null
    )
    
    $global:InfluxDBConnection = @{
        Server = $Server
        Port = $Port
        Database = $Database
        Username = $Username
        Password = $Password
        BaseUri = "http://${Server}:${Port}"
    }
    
    # Test connection
    try {
        $uri = "$($global:InfluxDBConnection.BaseUri)/ping"
        Invoke-RestMethod -Uri $uri -Method Get | Out-Null
        Write-Host "Connected to InfluxDB at $($global:InfluxDBConnection.BaseUri)" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to connect to InfluxDB: $($_.Exception.Message)"
        return $false
    }
}
```

### Send Metrics to InfluxDB
```powershell
function Send-VMMetricsToInfluxDB {
    param(
        [string]$vCenterServer,
        [PSCredential]$Credential
    )
    
    # Connect to vCenter
    Connect-VIServer -Server $vCenterServer -Credential $Credential
    
    try {
        # Get all VMs
        $vms = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}
        
        foreach ($vm in $vms) {
            # Get VM statistics
            $stats = Get-Stat -Entity $vm -Stat @(
                "cpu.usage.average",
                "mem.usage.average",
                "disk.usage.average",
                "net.usage.average"
            ) -Realtime -MaxSamples 1
            
            # Prepare InfluxDB line protocol data
            $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeNanoseconds()
            $lines = @()
            
            foreach ($stat in $stats) {
                $measurement = "vm_performance"
                $tags = "vm_name=$($vm.Name),vcenter=$vCenterServer,cluster=$($vm.VMHost.Parent.Name)"
                $field = "$($stat.MetricId)=$($stat.Value)"
                
                $lines += "$measurement,$tags $field $timestamp"
            }
            
            # Send to InfluxDB
            if ($lines.Count -gt 0) {
                Send-InfluxDBData -Lines $lines
            }
        }
        
        Write-Host "VM metrics sent to InfluxDB successfully" -ForegroundColor Green
        
    } finally {
        Disconnect-VIServer -Confirm:$false
    }
}

function Send-InfluxDBData {
    param(
        [string[]]$Lines
    )
    
    $uri = "$($global:InfluxDBConnection.BaseUri)/write?db=$($global:InfluxDBConnection.Database)"
    $body = $Lines -join "`n"
    
    try {
        $headers = @{'Content-Type' = 'application/octet-stream'}
        
        if ($global:InfluxDBConnection.Username) {
            $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($global:InfluxDBConnection.Username):$($global:InfluxDBConnection.Password)"))
            $headers['Authorization'] = "Basic $auth"
        }
        
        Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $headers
    } catch {
        Write-Error "Failed to send data to InfluxDB: $($_.Exception.Message)"
    }
}
```

## Prometheus Integration

### Install Prometheus Module
```powershell
Install-Module -Name PrometheusExporter -Force
```

### Create Prometheus Exporter
```powershell
function Start-VMwarePrometheusExporter {
    param(
        [string]$vCenterServer,
        [PSCredential]$Credential,
        [int]$Port = 9090,
        [int]$IntervalSeconds = 60
    )
    
    # Start HTTP listener
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("http://+:$Port/")
    $listener.Start()
    
    Write-Host "Prometheus exporter started on port $Port" -ForegroundColor Green
    
    # Background job to collect metrics
    $job = Start-Job -ScriptBlock {
        param($vCenter, $Cred, $Interval)
        
        while ($true) {
            try {
                # Connect to vCenter
                Import-Module VMware.PowerCLI
                Connect-VIServer -Server $vCenter -Credential $Cred
                
                # Collect metrics
                $global:VMwareMetrics = @{}
                
                $vms = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}
                foreach ($vm in $vms) {
                    $stats = Get-Stat -Entity $vm -Stat @(
                        "cpu.usage.average",
                        "mem.usage.average"
                    ) -Realtime -MaxSamples 1
                    
                    foreach ($stat in $stats) {
                        $metricName = "vmware_$($stat.MetricId.Replace('.', '_'))"
                        $labels = @{
                            vm_name = $vm.Name
                            vcenter = $vCenter
                            cluster = $vm.VMHost.Parent.Name
                        }
                        
                        $global:VMwareMetrics["$metricName"] = @{
                            Value = $stat.Value
                            Labels = $labels
                            Help = "VMware $($stat.MetricId) metric"
                        }
                    }
                }
                
                Disconnect-VIServer -Confirm:$false
                
            } catch {
                Write-Error "Error collecting metrics: $($_.Exception.Message)"
            }
            
            Start-Sleep -Seconds $Interval
        }
    } -ArgumentList $vCenterServer, $Credential, $IntervalSeconds
    
    # Handle HTTP requests
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        if ($request.Url.AbsolutePath -eq "/metrics") {
            $output = Generate-PrometheusMetrics
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($output)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
    
    # Cleanup
    Stop-Job -Job $job
    Remove-Job -Job $job
    $listener.Stop()
}

function Generate-PrometheusMetrics {
    $output = ""
    
    if ($global:VMwareMetrics) {
        foreach ($metric in $global:VMwareMetrics.GetEnumerator()) {
            $name = $metric.Key
            $data = $metric.Value
            
            # Help text
            $output += "# HELP $name $($data.Help)`n"
            $output += "# TYPE $name gauge`n"
            
            # Metric with labels
            $labelString = ($data.Labels.GetEnumerator() | ForEach-Object { "$($_.Key)=`"$($_.Value)`"" }) -join ","
            $output += "$name{$labelString} $($data.Value)`n"
        }
    }
    
    return $output
}
```

## Grafana API Integration

### Connect to Grafana API
```powershell
function Connect-GrafanaAPI {
    param(
        [string]$GrafanaUrl,
        [string]$ApiKey
    )
    
    $global:GrafanaConnection = @{
        Url = $GrafanaUrl.TrimEnd('/')
        Headers = @{
            'Authorization' = "Bearer $ApiKey"
            'Content-Type' = 'application/json'
        }
    }
    
    # Test connection
    try {
        $uri = "$($global:GrafanaConnection.Url)/api/org"
        Invoke-RestMethod -Uri $uri -Headers $global:GrafanaConnection.Headers -Method Get | Out-Null
        Write-Host "Connected to Grafana at $($global:GrafanaConnection.Url)" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to connect to Grafana: $($_.Exception.Message)"
        return $false
    }
}
```

### Create Grafana Dashboard
```powershell
function New-GrafanaDashboard {
    param(
        [string]$Title,
        [array]$Panels,
        [string]$DataSource = "InfluxDB"
    )
    
    $dashboard = @{
        dashboard = @{
            title = $Title
            tags = @("vmware", "powercli")
            timezone = "browser"
            panels = $Panels
            time = @{
                from = "now-1h"
                to = "now"
            }
            refresh = "30s"
        }
        overwrite = $true
    }
    
    $body = $dashboard | ConvertTo-Json -Depth 10
    $uri = "$($global:GrafanaConnection.Url)/api/dashboards/db"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $global:GrafanaConnection.Headers -Method Post -Body $body
        Write-Host "Dashboard '$Title' created successfully" -ForegroundColor Green
        return $response
    } catch {
        Write-Error "Failed to create dashboard: $($_.Exception.Message)"
        return $null
    }
}

function New-VMPerformancePanel {
    param(
        [int]$Id = 1,
        [string]$Title = "VM Performance",
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = 12,
        [int]$Height = 8
    )
    
    return @{
        id = $Id
        title = $Title
        type = "graph"
        gridPos = @{
            x = $X
            y = $Y
            w = $Width
            h = $Height
        }
        targets = @(
            @{
                query = 'SELECT mean("cpu.usage.average") FROM "vm_performance" WHERE $timeFilter GROUP BY time($__interval), "vm_name" fill(null)'
                alias = "CPU Usage - $tag_vm_name"
            },
            @{
                query = 'SELECT mean("mem.usage.average") FROM "vm_performance" WHERE $timeFilter GROUP BY time($__interval), "vm_name" fill(null)'
                alias = "Memory Usage - $tag_vm_name"
            }
        )
        yAxes = @(
            @{
                label = "Percentage"
                min = 0
                max = 100
            }
        )
        legend = @{
            show = $true
            values = $true
            current = $true
        }
    }
}
```

### Create Alerts
```powershell
function New-GrafanaAlert {
    param(
        [string]$Name,
        [string]$Query,
        [double]$Threshold,
        [string]$Condition = "gt",
        [string]$Frequency = "10s",
        [array]$NotificationChannels = @()
    )
    
    $alert = @{
        name = $Name
        message = "VMware infrastructure alert: $Name"
        frequency = $Frequency
        conditions = @(
            @{
                query = @{
                    queryType = ""
                    refId = "A"
                    model = @{
                        query = $Query
                    }
                }
                reducer = @{
                    type = "last"
                    params = @()
                }
                evaluator = @{
                    params = @($Threshold)
                    type = $Condition
                }
            }
        )
        executionErrorState = "alerting"
        noDataState = "no_data"
        for = "1m"
        annotations = @{
            description = "Alert for VMware infrastructure monitoring"
        }
        labels = @{
            team = "vmware-ops"
        }
    }
    
    if ($NotificationChannels.Count -gt 0) {
        $alert.notifications = $NotificationChannels
    }
    
    $body = $alert | ConvertTo-Json -Depth 10
    $uri = "$($global:GrafanaConnection.Url)/api/alerts"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $global:GrafanaConnection.Headers -Method Post -Body $body
        Write-Host "Alert '$Name' created successfully" -ForegroundColor Green
        return $response
    } catch {
        Write-Error "Failed to create alert: $($_.Exception.Message)"
        return $null
    }
}
```

## Complete Integration Example

### Automated Dashboard Creation
```powershell
# Configuration
$vCenterServer = "vcenter.example.com"
$influxDBServer = "influxdb.example.com"
$grafanaUrl = "http://grafana.example.com:3000"
$grafanaApiKey = "your-api-key-here"

# Connect to services
Connect-InfluxDB -Server $influxDBServer -Database "vmware"
Connect-GrafanaAPI -GrafanaUrl $grafanaUrl -ApiKey $grafanaApiKey

# Create comprehensive dashboard
$panels = @(
    (New-VMPerformancePanel -Id 1 -Title "VM CPU Usage" -Y 0),
    (New-VMPerformancePanel -Id 2 -Title "VM Memory Usage" -Y 8),
    @{
        id = 3
        title = "VM Count by Power State"
        type = "stat"
        gridPos = @{ x = 0; y = 16; w = 6; h = 4 }
        targets = @(
            @{
                query = 'SELECT count("power_state") FROM "vm_info" WHERE $timeFilter GROUP BY "power_state"'
            }
        )
    },
    @{
        id = 4
        title = "Top 10 VMs by CPU Usage"
        type = "table"
        gridPos = @{ x = 6; y = 16; w = 6; h = 4 }
        targets = @(
            @{
                query = 'SELECT last("cpu.usage.average") FROM "vm_performance" WHERE $timeFilter GROUP BY "vm_name" ORDER BY time DESC LIMIT 10'
            }
        )
    }
)

# Create dashboard
$dashboard = New-GrafanaDashboard -Title "VMware Infrastructure Overview" -Panels $panels

# Create alerts
New-GrafanaAlert -Name "High VM CPU Usage" -Query 'SELECT mean("cpu.usage.average") FROM "vm_performance" WHERE $timeFilter' -Threshold 90
New-GrafanaAlert -Name "High VM Memory Usage" -Query 'SELECT mean("mem.usage.average") FROM "vm_performance" WHERE $timeFilter' -Threshold 90

Write-Host "Grafana integration setup completed!" -ForegroundColor Green
```

### Scheduled Data Collection
```powershell
# Create scheduled task for continuous data collection
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\VMware-Grafana-Collector.ps1"
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 5) -Once -At (Get-Date)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "VMware-Grafana-Collector" -Action $action -Trigger $trigger -Settings $settings -Description "Collect VMware metrics for Grafana"
```

## Best Practices

### Performance Optimization
- Use appropriate collection intervals
- Implement data retention policies
- Use efficient queries
- Monitor resource usage

### Security
- Use secure connections (HTTPS/TLS)
- Implement proper authentication
- Restrict API access
- Regular credential rotation

### Monitoring
- Set up health checks
- Monitor data freshness
- Alert on collection failures
- Track performance metrics

## Troubleshooting

### Common Issues
1. **Connection timeouts**: Increase timeout values
2. **Data not appearing**: Check data source configuration
3. **High resource usage**: Optimize collection frequency
4. **Authentication errors**: Verify API keys and credentials

### Debug Mode
```powershell
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# Enable detailed logging
Start-Transcript -Path "C:\Logs\Grafana-Integration-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

## Resources

- [Grafana API Documentation](https://grafana.com/docs/grafana/latest/http_api/)
- [InfluxDB Documentation](https://docs.influxdata.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [PowerCLI Best Practices](../guides/best-practices.md)