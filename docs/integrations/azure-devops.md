# Azure DevOps Integration Guide

## Overview
This guide explains how to integrate PowerCLI scripts with Azure DevOps for automated VMware infrastructure management.

## Prerequisites

### Azure DevOps Setup
- Azure DevOps organization and project
- Self-hosted agents with PowerCLI installed
- Service connections for vCenter
- Appropriate permissions

### PowerCLI Requirements
- VMware PowerCLI 12.0 or later
- PowerShell 5.1 or PowerShell 7+
- Network access to vCenter servers

## Installation

### Self-Hosted Agent Setup
```powershell
# Install PowerCLI on Windows agents
Install-Module -Name VMware.PowerCLI -Force -AllowClobber -Scope AllUsers

# Configure PowerCLI
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false

# Install Azure DevOps agent
# Follow Microsoft documentation for agent installation
```

### Linux Agent Setup
```bash
# Install PowerShell
sudo snap install powershell --classic

# Install PowerCLI
pwsh -c "Install-Module -Name VMware.PowerCLI -Force -AllowClobber -Scope AllUsers"
```

## Configuration

### Service Connections
1. Navigate to Project Settings → Service connections
2. Create new service connection:
   - Connection type: Generic
   - Server URL: `https://vcenter.example.com`
   - Username: `administrator@vsphere.local`
   - Password: `[secure-password]`
   - Service connection name: `vCenter-Connection`

### Variable Groups
Create variable group `VMware-Config`:
- `VCENTER_SERVER`: vcenter.example.com
- `VCENTER_TIMEOUT`: 300
- `POWERCLI_VERSION`: 12.7.0

## Pipeline Examples

### Basic YAML Pipeline
```yaml
trigger:
- main

pool:
  name: 'Self-Hosted-PowerCLI'

variables:
- group: VMware-Config

stages:
- stage: VMwareOperations
  displayName: 'VMware Operations'
  jobs:
  - job: PowerCLITasks
    displayName: 'PowerCLI Tasks'
    steps:
    - task: PowerShell@2
      displayName: 'Connect to vCenter'
      inputs:
        targetType: 'inline'
        script: |
          Import-Module VMware.PowerCLI
          
          # Connect using service connection
          $securePassword = ConvertTo-SecureString "$(vCenter-Connection.password)" -AsPlainText -Force
          $credential = New-Object System.Management.Automation.PSCredential("$(vCenter-Connection.username)", $securePassword)
          
          Connect-VIServer -Server $(VCENTER_SERVER) -Credential $credential
          
          # Your PowerCLI commands here
          Get-VM | Select-Object Name, PowerState | Format-Table
          
          Disconnect-VIServer -Confirm:$false
```

### VM Deployment Pipeline
```yaml
parameters:
- name: vmName
  displayName: 'VM Name'
  type: string
  default: 'TestVM'
- name: template
  displayName: 'VM Template'
  type: string
  default: 'Windows2019'
  values:
  - Windows2019
  - Ubuntu20
  - CentOS8

trigger: none

pool:
  name: 'Self-Hosted-PowerCLI'

variables:
- group: VMware-Config

stages:
- stage: DeployVM
  displayName: 'Deploy Virtual Machine'
  jobs:
  - job: VMDeployment
    displayName: 'VM Deployment'
    steps:
    - task: PowerShell@2
      displayName: 'Deploy VM from Template'
      inputs:
        targetType: 'inline'
        script: |
          Import-Module VMware.PowerCLI
          
          try {
              # Connect to vCenter
              $securePassword = ConvertTo-SecureString "$(vCenter-Connection.password)" -AsPlainText -Force
              $credential = New-Object System.Management.Automation.PSCredential("$(vCenter-Connection.username)", $securePassword)
              Connect-VIServer -Server $(VCENTER_SERVER) -Credential $credential
              
              # Deploy VM
              $template = Get-Template -Name "${{ parameters.template }}"
              $datastore = Get-Datastore | Where-Object {$_.FreeSpaceGB -gt 50} | Select-Object -First 1
              $vmhost = Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"} | Get-Random
              
              Write-Host "Deploying VM: ${{ parameters.vmName }}"
              Write-Host "Template: ${{ parameters.template }}"
              Write-Host "Datastore: $($datastore.Name)"
              Write-Host "Host: $($vmhost.Name)"
              
              $vm = New-VM -Name "${{ parameters.vmName }}" -Template $template -Datastore $datastore -VMHost $vmhost
              Start-VM -VM $vm
              
              Write-Host "##vso[task.setvariable variable=deployedVM;isOutput=true]${{ parameters.vmName }}"
              Write-Host "VM deployed successfully!"
              
          } catch {
              Write-Error "Deployment failed: $($_.Exception.Message)"
              exit 1
          } finally {
              Disconnect-VIServer -Confirm:$false -ErrorAction SilentlyContinue
          }
```

### Multi-Stage Pipeline
```yaml
trigger:
- main

pool:
  name: 'Self-Hosted-PowerCLI'

variables:
- group: VMware-Config

stages:
- stage: Validation
  displayName: 'Validation Stage'
  jobs:
  - job: ValidateEnvironment
    displayName: 'Validate Environment'
    steps:
    - task: PowerShell@2
      displayName: 'Validate PowerCLI and Connectivity'
      inputs:
        targetType: 'inline'
        script: |
          # Check PowerCLI version
          $powercliVersion = Get-Module -ListAvailable VMware.PowerCLI | Select-Object -First 1
          Write-Host "PowerCLI Version: $($powercliVersion.Version)"
          
          # Test connectivity
          Test-NetConnection -ComputerName $(VCENTER_SERVER) -Port 443

- stage: Operations
  displayName: 'VMware Operations'
  dependsOn: Validation
  condition: succeeded()
  jobs:
  - job: MaintenanceTasks
    displayName: 'Maintenance Tasks'
    steps:
    - task: PowerShell@2
      displayName: 'Update VMware Tools'
      inputs:
        targetType: 'filePath'
        filePath: 'scripts/Update-VMwareTools.ps1'
        arguments: '-vCenter $(VCENTER_SERVER)'
    
    - task: PowerShell@2
      displayName: 'Cleanup Snapshots'
      inputs:
        targetType: 'filePath'
        filePath: 'scripts/Cleanup-Snapshots.ps1'
        arguments: '-vCenter $(VCENTER_SERVER) -DaysOld 7'

- stage: Reporting
  displayName: 'Generate Reports'
  dependsOn: Operations
  condition: always()
  jobs:
  - job: GenerateReports
    displayName: 'Generate Reports'
    steps:
    - task: PowerShell@2
      displayName: 'Generate Infrastructure Report'
      inputs:
        targetType: 'inline'
        script: |
          # Generate HTML report
          $reportPath = "$(Agent.TempDirectory)/vmware-report.html"
          # Report generation logic here
          
          Write-Host "##vso[task.addattachment type=Distributedtask.Core.Summary;name=VMware Report;]$reportPath"
    
    - task: PublishTestResults@2
      displayName: 'Publish Test Results'
      inputs:
        testResultsFormat: 'NUnit'
        testResultsFiles: '**/*-results.xml'
        failTaskOnFailedTests: false
```

## Task Templates

### PowerCLI Connection Task
```yaml
# templates/powercli-connect.yml
parameters:
- name: vCenterServer
  type: string
- name: serviceConnection
  type: string

steps:
- task: PowerShell@2
  displayName: 'Connect to vCenter'
  inputs:
    targetType: 'inline'
    script: |
      Import-Module VMware.PowerCLI
      
      $securePassword = ConvertTo-SecureString "$(${{ parameters.serviceConnection }}.password)" -AsPlainText -Force
      $credential = New-Object System.Management.Automation.PSCredential("$(${{ parameters.serviceConnection }}.username)", $securePassword)
      
      Connect-VIServer -Server ${{ parameters.vCenterServer }} -Credential $credential
      
      # Store connection info for subsequent tasks
      Write-Host "##vso[task.setvariable variable=vCenterConnected;isOutput=true]true"
```

### VM Health Check Task
```yaml
# templates/vm-health-check.yml
parameters:
- name: vmPattern
  type: string
  default: '*'

steps:
- task: PowerShell@2
  displayName: 'VM Health Check'
  inputs:
    targetType: 'inline'
    script: |
      $vms = Get-VM -Name "${{ parameters.vmPattern }}"
      $healthReport = @()
      
      foreach ($vm in $vms) {
          $health = [PSCustomObject]@{
              Name = $vm.Name
              PowerState = $vm.PowerState
              ToolsStatus = $vm.ExtensionData.Guest.ToolsStatus
              ToolsVersion = $vm.ExtensionData.Guest.ToolsVersion
              CPUUsage = $vm.ExtensionData.Summary.QuickStats.OverallCpuUsage
              MemoryUsage = $vm.ExtensionData.Summary.QuickStats.GuestMemoryUsage
          }
          $healthReport += $health
      }
      
      $healthReport | ConvertTo-Json | Out-File "$(Agent.TempDirectory)/vm-health.json"
      $healthReport | Format-Table
```

## Advanced Features

### Parallel Execution
```yaml
jobs:
- job: ParallelOperations
  displayName: 'Parallel Operations'
  strategy:
    parallel: 3
  steps:
  - task: PowerShell@2
    displayName: 'Process VM Batch $(System.JobPositionInPhase)'
    inputs:
      targetType: 'inline'
      script: |
        $batchSize = 10
        $startIndex = $(System.JobPositionInPhase) * $batchSize
        # Process VMs in batches
```

### Conditional Execution
```yaml
- task: PowerShell@2
  displayName: 'Production Only Task'
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  inputs:
    targetType: 'inline'
    script: |
      # Production-specific operations
```

### Environment-Specific Variables
```yaml
variables:
- ${{ if eq(variables['Build.SourceBranch'], 'refs/heads/main') }}:
  - group: VMware-Production
- ${{ else }}:
  - group: VMware-Development
```

## Security Best Practices

### Service Connections
- Use Azure Key Vault for sensitive data
- Implement least-privilege access
- Regular credential rotation
- Enable audit logging

### Pipeline Security
```yaml
resources:
  repositories:
  - repository: templates
    type: git
    name: shared-templates
    ref: refs/heads/main

extends:
  template: secure-pipeline.yml@templates
  parameters:
    serviceConnection: 'vCenter-Connection'
```

## Monitoring and Logging

### Custom Logging
```yaml
- task: PowerShell@2
  displayName: 'Custom Logging'
  inputs:
    targetType: 'inline'
    script: |
      # Enable transcript logging
      Start-Transcript -Path "$(Agent.TempDirectory)/powercli-transcript.log"
      
      try {
          # Your PowerCLI operations
      } finally {
          Stop-Transcript
      }

- task: PublishBuildArtifacts@1
  displayName: 'Publish Logs'
  inputs:
    pathToPublish: '$(Agent.TempDirectory)'
    artifactName: 'PowerCLI-Logs'
```

### Performance Monitoring
```yaml
- task: PowerShell@2
  displayName: 'Performance Monitoring'
  inputs:
    targetType: 'inline'
    script: |
      $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
      
      # Your operations here
      
      $stopwatch.Stop()
      Write-Host "##vso[task.logissue type=warning]Operation completed in $($stopwatch.Elapsed.TotalSeconds) seconds"
```

## Troubleshooting

### Common Issues
1. **Agent connectivity**: Ensure agents can reach vCenter
2. **PowerCLI version**: Keep PowerCLI updated
3. **Permissions**: Verify service account permissions
4. **Timeouts**: Adjust timeout values for long operations

### Debug Pipeline
```yaml
- task: PowerShell@2
  displayName: 'Debug Information'
  inputs:
    targetType: 'inline'
    script: |
      Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
      Write-Host "PowerCLI Modules:"
      Get-Module -ListAvailable VMware.* | Format-Table Name, Version
      Write-Host "Environment Variables:"
      Get-ChildItem Env: | Where-Object {$_.Name -like "*VCENTER*"} | Format-Table
```

## Integration Examples

### Teams Notifications
```yaml
- task: PowerShell@2
  displayName: 'Send Teams Notification'
  condition: always()
  inputs:
    targetType: 'inline'
    script: |
      $webhook = "$(TeamsWebhookURL)"
      $message = @{
          text = "PowerCLI pipeline completed: $(Build.BuildNumber)"
          themeColor = if ("$(Agent.JobStatus)" -eq "Succeeded") { "00FF00" } else { "FF0000" }
      }
      Invoke-RestMethod -Uri $webhook -Method Post -Body ($message | ConvertTo-Json) -ContentType "application/json"
```

### ServiceNow Integration
```yaml
- task: PowerShell@2
  displayName: 'Create ServiceNow Ticket'
  condition: failed()
  inputs:
    targetType: 'inline'
    script: |
      # ServiceNow API integration
      $body = @{
          short_description = "Azure DevOps PowerCLI Pipeline Failed"
          description = "Build $(Build.BuildNumber) failed. Check logs: $(Build.BuildUri)"
      }
      # API call to ServiceNow
```

## Resources

- [Azure DevOps PowerShell Task](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/utility/powershell)
- [VMware PowerCLI Documentation](https://developer.vmware.com/powercli)
- [Azure DevOps YAML Schema](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema)
- [PowerCLI Best Practices](../guides/best-practices.md)