# vRealize Operations Manager Integration Guide

## Overview
This guide explains how to integrate PowerCLI scripts with vRealize Operations Manager (vROps) for enhanced monitoring and automation.

## Prerequisites

### vROps Requirements
- vRealize Operations Manager 8.0 or later
- REST API access enabled
- Authentication token or credentials
- Network connectivity from PowerCLI environment

### PowerCLI Requirements
- VMware PowerCLI 12.0 or later
- PowerShell 5.1 or PowerShell 7+
- RestMethod capabilities

## Authentication

### API Token Authentication
```powershell
# Generate API token in vROps
$vROpsServer = "vrops.example.com"
$apiToken = "your-api-token-here"

$headers = @{
    'Authorization' = "vRealizeOpsToken $apiToken"
    'Content-Type' = 'application/json'
    'Accept' = 'application/json'
}
```

### Username/Password Authentication
```powershell
$vROpsServer = "vrops.example.com"
$credential = Get-Credential

# Create authentication payload
$authBody = @{
    username = $credential.UserName
    password = $credential.GetNetworkCredential().Password
} | ConvertTo-Json

# Get authentication token
$authResponse = Invoke-RestMethod -Uri "https://$vROpsServer/suite-api/api/auth/token/acquire" -Method Post -Body $authBody -ContentType "application/json"
$token = $authResponse.token

$headers = @{
    'Authorization' = "vRealizeOpsToken $token"
    'Content-Type' = 'application/json'
    'Accept' = 'application/json'
}
```

## Core Functions

### Get vROps Resources
```powershell
function Get-vROpsResources {
    param(
        [string]$vROpsServer,
        [hashtable]$Headers,
        [string]$ResourceKind = "VirtualMachine",
        [string]$Name = $null
    )
    
    $uri = "https://$vROpsServer/suite-api/api/resources"
    $params = @{
        resourceKind = $ResourceKind
    }
    
    if ($Name) {
        $params.name = $Name
    }
    
    $queryString = ($params.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
    $fullUri = "$uri?$queryString"
    
    try {
        $response = Invoke-RestMethod -Uri $fullUri -Headers $Headers -Method Get
        return $response.resourceList
    } catch {
        Write-Error "Failed to get vROps resources: $($_.Exception.Message)"
        return $null
    }
}
```

### Get Resource Metrics
```powershell
function Get-vROpsMetrics {
    param(
        [string]$vROpsServer,
        [hashtable]$Headers,
        [string]$ResourceId,
        [string[]]$MetricKeys,
        [datetime]$StartTime = (Get-Date).AddHours(-1),
        [datetime]$EndTime = (Get-Date)
    )
    
    $uri = "https://$vROpsServer/suite-api/api/resources/$ResourceId/stats"
    
    $body = @{
        statKey = $MetricKeys
        begin = [long]($StartTime - (Get-Date "1970-01-01")).TotalMilliseconds
        end = [long]($EndTime - (Get-Date "1970-01-01")).TotalMilliseconds
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Post -Body $body
        return $response.values
    } catch {
        Write-Error "Failed to get metrics: $($_.Exception.Message)"
        return $null
    }
}
```

### Create Custom Metric
```powershell
function Set-vROpsCustomMetric {
    param(
        [string]$vROpsServer,
        [hashtable]$Headers,
        [string]$ResourceId,
        [string]$MetricKey,
        [double]$Value,
        [datetime]$Timestamp = (Get-Date)
    )
    
    $uri = "https://$vROpsServer/suite-api/api/resources/$ResourceId/stats"
    
    $body = @{
        stat-content = @(
            @{
                statKey = $MetricKey
                timestamps = @([long]($Timestamp - (Get-Date "1970-01-01")).TotalMilliseconds)
                data = @($Value)
            }
        )
    } | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Post -Body $body
        Write-Host "Custom metric '$MetricKey' set successfully for resource $ResourceId"
        return $response
    } catch {
        Write-Error "Failed to set custom metric: $($_.Exception.Message)"
        return $null
    }
}
```

## Integration Examples

### VM Performance Monitoring
```powershell
# Connect to vCenter and vROps
Import-Module VMware.PowerCLI
Connect-VIServer -Server "vcenter.example.com"

# vROps connection
$vROpsServer = "vrops.example.com"
$headers = @{
    'Authorization' = "vRealizeOpsToken $apiToken"
    'Content-Type' = 'application/json'
}

# Get VMs from vCenter
$vms = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}

foreach ($vm in $vms) {
    # Get corresponding vROps resource
    $vROpsResource = Get-vROpsResources -vROpsServer $vROpsServer -Headers $headers -ResourceKind "VirtualMachine" -Name $vm.Name
    
    if ($vROpsResource) {
        # Get performance metrics from vROps
        $metrics = Get-vROpsMetrics -vROpsServer $vROpsServer -Headers $headers -ResourceId $vROpsResource.identifier -MetricKeys @("cpu|usage_average", "mem|usage_average")
        
        # Process metrics and take action if needed
        foreach ($metric in $metrics) {
            if ($metric.statKey -eq "cpu|usage_average" -and $metric.data[-1] -gt 80) {
                Write-Warning "High CPU usage detected on $($vm.Name): $($metric.data[-1])%"
                # Take corrective action
            }
        }
    }
}
```

### Automated Capacity Planning
```powershell
function Get-CapacityRecommendations {
    param(
        [string]$vROpsServer,
        [hashtable]$Headers,
        [string]$ClusterName
    )
    
    # Get cluster resource from vROps
    $cluster = Get-vROpsResources -vROpsServer $vROpsServer -Headers $headers -ResourceKind "ClusterComputeResource" -Name $ClusterName
    
    if ($cluster) {
        # Get capacity metrics
        $capacityMetrics = Get-vROpsMetrics -vROpsServer $vROpsServer -Headers $headers -ResourceId $cluster.identifier -MetricKeys @(
            "cpu|capacity_remaining",
            "mem|capacity_remaining",
            "datastore|capacity_remaining"
        ) -StartTime (Get-Date).AddDays(-30)
        
        # Analyze trends and generate recommendations
        $recommendations = @()
        
        foreach ($metric in $capacityMetrics) {
            $trend = ($metric.data | Measure-Object -Average).Average
            
            switch ($metric.statKey) {
                "cpu|capacity_remaining" {
                    if ($trend -lt 20) {
                        $recommendations += "Consider adding CPU resources to cluster $ClusterName"
                    }
                }
                "mem|capacity_remaining" {
                    if ($trend -lt 20) {
                        $recommendations += "Consider adding memory resources to cluster $ClusterName"
                    }
                }
                "datastore|capacity_remaining" {
                    if ($trend -lt 20) {
                        $recommendations += "Consider adding storage resources to cluster $ClusterName"
                    }
                }
            }
        }
        
        return $recommendations
    }
}

# Generate capacity recommendations
$recommendations = Get-CapacityRecommendations -vROpsServer $vROpsServer -Headers $headers -ClusterName "Production-Cluster"
$recommendations | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
```

### Custom Health Monitoring
```powershell
function Monitor-VMwareToolsHealth {
    param(
        [string]$vCenterServer,
        [string]$vROpsServer,
        [hashtable]$Headers
    )
    
    # Connect to vCenter
    Connect-VIServer -Server $vCenterServer
    
    try {
        # Get all VMs
        $vms = Get-VM
        
        foreach ($vm in $vms) {
            # Check VMware Tools status
            $toolsStatus = $vm.ExtensionData.Guest.ToolsStatus
            $toolsVersion = $vm.ExtensionData.Guest.ToolsVersion
            
            # Get vROps resource
            $vROpsResource = Get-vROpsResources -vROpsServer $vROpsServer -Headers $headers -ResourceKind "VirtualMachine" -Name $vm.Name
            
            if ($vROpsResource) {
                # Create custom health metric
                $healthScore = switch ($toolsStatus) {
                    "toolsOk" { 100 }
                    "toolsOld" { 75 }
                    "toolsNotRunning" { 25 }
                    "toolsNotInstalled" { 0 }
                    default { 50 }
                }
                
                # Send custom metric to vROps
                Set-vROpsCustomMetric -vROpsServer $vROpsServer -Headers $headers -ResourceId $vROpsResource.identifier -MetricKey "custom|vmware_tools_health" -Value $healthScore
                
                Write-Host "Updated VMware Tools health metric for $($vm.Name): $healthScore"
            }
        }
    } finally {
        Disconnect-VIServer -Confirm:$false
    }
}

# Run health monitoring
Monitor-VMwareToolsHealth -vCenterServer "vcenter.example.com" -vROpsServer $vROpsServer -Headers $headers
```

### Alert Integration
```powershell
function Get-vROpsAlerts {
    param(
        [string]$vROpsServer,
        [hashtable]$Headers,
        [string]$Severity = "CRITICAL"
    )
    
    $uri = "https://$vROpsServer/suite-api/api/alerts"
    $params = @{
        alertStatus = "OPEN"
        alertLevel = $Severity
    }
    
    $queryString = ($params.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
    $fullUri = "$uri?$queryString"
    
    try {
        $response = Invoke-RestMethod -Uri $fullUri -Headers $Headers -Method Get
        return $response.alerts
    } catch {
        Write-Error "Failed to get alerts: $($_.Exception.Message)"
        return $null
    }
}

function Resolve-vROpsAlert {
    param(
        [string]$vROpsServer,
        [hashtable]$Headers,
        [string]$AlertId,
        [string]$Resolution
    )
    
    $uri = "https://$vROpsServer/suite-api/api/alerts/$AlertId"
    
    $body = @{
        alertStatus = "CLOSED"
        notes = $Resolution
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Patch -Body $body
        Write-Host "Alert $AlertId resolved: $Resolution"
        return $response
    } catch {
        Write-Error "Failed to resolve alert: $($_.Exception.Message)"
        return $null
    }
}

# Process critical alerts
$criticalAlerts = Get-vROpsAlerts -vROpsServer $vROpsServer -Headers $headers -Severity "CRITICAL"

foreach ($alert in $criticalAlerts) {
    Write-Host "Processing alert: $($alert.alertDefinitionName) on $($alert.resourceName)"
    
    # Implement automated resolution logic
    switch ($alert.alertDefinitionName) {
        "VM CPU Usage" {
            # Implement CPU optimization
            $resolution = "Automated CPU optimization applied"
            Resolve-vROpsAlert -vROpsServer $vROpsServer -Headers $headers -AlertId $alert.identifier -Resolution $resolution
        }
        "VM Memory Usage" {
            # Implement memory optimization
            $resolution = "Automated memory optimization applied"
            Resolve-vROpsAlert -vROpsServer $vROpsServer -Headers $headers -AlertId $alert.identifier -Resolution $resolution
        }
    }
}
```

## Advanced Integration

### Dashboard Automation
```powershell
function Create-vROpsCustomDashboard {
    param(
        [string]$vROpsServer,
        [hashtable]$Headers,
        [string]$DashboardName,
        [array]$Widgets
    )
    
    $uri = "https://$vROpsServer/suite-api/api/dashboards"
    
    $body = @{
        name = $DashboardName
        description = "Automated dashboard created by PowerCLI"
        widgets = $Widgets
    } | ConvertTo-Json -Depth 5
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Post -Body $body
        Write-Host "Dashboard '$DashboardName' created successfully"
        return $response
    } catch {
        Write-Error "Failed to create dashboard: $($_.Exception.Message)"
        return $null
    }
}
```

### Report Generation
```powershell
function Generate-vROpsReport {
    param(
        [string]$vROpsServer,
        [hashtable]$Headers,
        [string]$ReportDefinitionId,
        [string]$OutputPath
    )
    
    # Generate report
    $uri = "https://$vROpsServer/suite-api/api/reports/$ReportDefinitionId"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Post
        $reportId = $response.id
        
        # Wait for report completion
        do {
            Start-Sleep -Seconds 5
            $status = Invoke-RestMethod -Uri "https://$vROpsServer/suite-api/api/reports/$reportId" -Headers $Headers -Method Get
        } while ($status.status -eq "RUNNING")
        
        if ($status.status -eq "COMPLETED") {
            # Download report
            $downloadUri = "https://$vROpsServer/suite-api/api/reports/$reportId/download"
            Invoke-RestMethod -Uri $downloadUri -Headers $Headers -Method Get -OutFile $OutputPath
            Write-Host "Report downloaded to: $OutputPath"
        }
    } catch {
        Write-Error "Failed to generate report: $($_.Exception.Message)"
    }
}
```

## Best Practices

### Error Handling
```powershell
function Invoke-vROpsAPI {
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Method = "Get",
        [string]$Body = $null,
        [int]$MaxRetries = 3
    )
    
    $retryCount = 0
    
    do {
        try {
            if ($Body) {
                return Invoke-RestMethod -Uri $Uri -Headers $Headers -Method $Method -Body $Body
            } else {
                return Invoke-RestMethod -Uri $Uri -Headers $Headers -Method $Method
            }
        } catch {
            $retryCount++
            if ($retryCount -ge $MaxRetries) {
                throw "API call failed after $MaxRetries attempts: $($_.Exception.Message)"
            }
            Write-Warning "API call failed, retrying in 5 seconds... (Attempt $retryCount/$MaxRetries)"
            Start-Sleep -Seconds 5
        }
    } while ($retryCount -lt $MaxRetries)
}
```

### Performance Optimization
```powershell
# Use parallel processing for multiple API calls
$vms | ForEach-Object -Parallel {
    $vm = $_
    # Process each VM in parallel
} -ThrottleLimit 10
```

## Troubleshooting

### Common Issues
1. **Authentication failures**: Check API token validity
2. **SSL certificate errors**: Configure certificate validation
3. **Rate limiting**: Implement retry logic with backoff
4. **Resource not found**: Verify resource names and IDs

### Debug Mode
```powershell
$DebugPreference = "Continue"
$VerbosePreference = "Continue"

# Enable detailed HTTP logging
$PSDefaultParameterValues['Invoke-RestMethod:Verbose'] = $true
```

## Resources

- [vRealize Operations Manager API Documentation](https://docs.vmware.com/en/vRealize-Operations-Manager/)
- [PowerCLI Best Practices](../guides/best-practices.md)
- [VMware PowerCLI Documentation](https://developer.vmware.com/powercli)