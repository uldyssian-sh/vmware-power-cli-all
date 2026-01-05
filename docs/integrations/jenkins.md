# Jenkins Integration Guide

## Overview
This guide explains how to integrate PowerCLI scripts with Jenkins for automated VMware infrastructure management.

## Prerequisites

### Jenkins Setup
- Jenkins server with PowerShell plugin
- Windows or Linux agents with PowerCLI installed
- Network access to vCenter servers
- Secure credential storage

### PowerCLI Requirements
- VMware PowerCLI 12.0 or later
- PowerShell 5.1 or PowerShell 7+
- Appropriate vCenter permissions

## Installation

### Jenkins Plugins
Install the following Jenkins plugins:
- PowerShell Plugin
- Credentials Plugin
- Pipeline Plugin
- Build Timeout Plugin

### PowerCLI on Jenkins Agents
```powershell
# Install PowerCLI on Windows agents
Install-Module -Name VMware.PowerCLI -Force -AllowClobber -Scope AllUsers

# Configure PowerCLI
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false
```

## Configuration

### Credentials Management
1. Navigate to Jenkins → Manage Jenkins → Manage Credentials
2. Add vCenter credentials:
   - Kind: Username with password
   - Scope: Global
   - ID: `vcenter-credentials`
   - Username: `administrator@vsphere.local`
   - Password: `[secure-password]`

### Environment Variables
Configure global environment variables:
- `VCENTER_SERVER`: vCenter FQDN
- `POWERCLI_TIMEOUT`: Script timeout (default: 300)

## Pipeline Examples

### Basic PowerCLI Pipeline
```groovy
pipeline {
    agent { label 'windows-powercli' }
    
    environment {
        VCENTER_SERVER = 'vcenter.example.com'
    }
    
    stages {
        stage('Connect to vCenter') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'vcenter-credentials', 
                                                usernameVariable: 'VCENTER_USER', 
                                                passwordVariable: 'VCENTER_PASS')]) {
                    powershell '''
                        Import-Module VMware.PowerCLI
                        $securePassword = ConvertTo-SecureString $env:VCENTER_PASS -AsPlainText -Force
                        $credential = New-Object System.Management.Automation.PSCredential($env:VCENTER_USER, $securePassword)
                        Connect-VIServer -Server $env:VCENTER_SERVER -Credential $credential
                        
                        # Your PowerCLI commands here
                        Get-VM | Select-Object Name, PowerState | Format-Table
                        
                        Disconnect-VIServer -Confirm:$false
                    '''
                }
            }
        }
    }
    
    post {
        always {
            powershell 'Disconnect-VIServer -Confirm:$false -ErrorAction SilentlyContinue'
        }
    }
}
```

### VM Deployment Pipeline
```groovy
pipeline {
    agent { label 'windows-powercli' }
    
    parameters {
        string(name: 'VM_NAME', defaultValue: 'TestVM', description: 'VM Name')
        choice(name: 'VM_TEMPLATE', choices: ['Windows2019', 'Ubuntu20'], description: 'VM Template')
        string(name: 'DATASTORE', defaultValue: 'datastore1', description: 'Target Datastore')
    }
    
    stages {
        stage('Deploy VM') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'vcenter-credentials', 
                                                usernameVariable: 'VCENTER_USER', 
                                                passwordVariable: 'VCENTER_PASS')]) {
                    powershell """
                        Import-Module VMware.PowerCLI
                        \$securePassword = ConvertTo-SecureString \$env:VCENTER_PASS -AsPlainText -Force
                        \$credential = New-Object System.Management.Automation.PSCredential(\$env:VCENTER_USER, \$securePassword)
                        Connect-VIServer -Server \$env:VCENTER_SERVER -Credential \$credential
                        
                        # Deploy VM from template
                        \$template = Get-Template -Name "${params.VM_TEMPLATE}"
                        \$datastore = Get-Datastore -Name "${params.DATASTORE}"
                        \$vmhost = Get-VMHost | Get-Random
                        
                        New-VM -Name "${params.VM_NAME}" -Template \$template -Datastore \$datastore -VMHost \$vmhost
                        Start-VM -VM "${params.VM_NAME}"
                        
                        Write-Host "VM ${params.VM_NAME} deployed successfully"
                        
                        Disconnect-VIServer -Confirm:\$false
                    """
                }
            }
        }
    }
}
```

### Scheduled Maintenance Pipeline
```groovy
pipeline {
    agent { label 'windows-powercli' }
    
    triggers {
        cron('0 2 * * 0') // Run every Sunday at 2 AM
    }
    
    stages {
        stage('Weekly Maintenance') {
            parallel {
                stage('Update VMware Tools') {
                    steps {
                        powershell '''
                            Import-Module VMware.PowerCLI
                            # Connect and update VMware Tools
                            # Implementation here
                        '''
                    }
                }
                
                stage('Snapshot Cleanup') {
                    steps {
                        powershell '''
                            Import-Module VMware.PowerCLI
                            # Clean up old snapshots
                            # Implementation here
                        '''
                    }
                }
                
                stage('Health Check') {
                    steps {
                        powershell '''
                            Import-Module VMware.PowerCLI
                            # Perform health checks
                            # Implementation here
                        '''
                    }
                }
            }
        }
    }
    
    post {
        success {
            emailext (
                subject: "Weekly Maintenance Completed Successfully",
                body: "All maintenance tasks completed without errors.",
                to: "vmware-admins@company.com"
            )
        }
        failure {
            emailext (
                subject: "Weekly Maintenance Failed",
                body: "One or more maintenance tasks failed. Please check the build logs.",
                to: "vmware-admins@company.com"
            )
        }
    }
}
```

## Best Practices

### Security
- Use Jenkins credentials store for sensitive data
- Implement least-privilege access
- Enable audit logging
- Use encrypted connections

### Performance
- Use dedicated Jenkins agents for PowerCLI
- Implement connection pooling
- Set appropriate timeouts
- Monitor resource usage

### Error Handling
```groovy
stage('PowerCLI Task') {
    steps {
        script {
            try {
                powershell '''
                    # Your PowerCLI commands
                '''
            } catch (Exception e) {
                currentBuild.result = 'FAILURE'
                error("PowerCLI task failed: ${e.getMessage()}")
            }
        }
    }
}
```

### Logging and Reporting
```groovy
post {
    always {
        publishHTML([
            allowMissing: false,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: 'reports',
            reportFiles: 'powercli-report.html',
            reportName: 'PowerCLI Report'
        ])
    }
}
```

## Troubleshooting

### Common Issues
1. **PowerCLI module not found**
   - Ensure PowerCLI is installed on Jenkins agent
   - Check module path and permissions

2. **Connection timeouts**
   - Verify network connectivity
   - Check firewall settings
   - Increase timeout values

3. **Permission errors**
   - Verify vCenter user permissions
   - Check Jenkins agent service account

4. **Certificate errors**
   - Configure PowerCLI certificate settings
   - Import trusted certificates

### Debug Mode
```groovy
environment {
    POWERCLI_DEBUG = 'true'
}

steps {
    powershell '''
        $VerbosePreference = "Continue"
        $DebugPreference = "Continue"
        # Your PowerCLI commands
    '''
}
```

## Advanced Features

### Multi-vCenter Support
```groovy
stage('Multi-vCenter Operations') {
    steps {
        powershell '''
            $vCenters = @("vcenter1.lab.local", "vcenter2.lab.local")
            foreach ($vCenter in $vCenters) {
                Connect-VIServer -Server $vCenter -Credential $credential
                # Perform operations
                Disconnect-VIServer -Server $vCenter -Confirm:$false
            }
        '''
    }
}
```

### Parallel Execution
```groovy
stage('Parallel VM Operations') {
    parallel {
        stage('Production VMs') {
            steps {
                powershell '# Production VM tasks'
            }
        }
        stage('Development VMs') {
            steps {
                powershell '# Development VM tasks'
            }
        }
    }
}
```

## Integration Examples

### Slack Notifications
```groovy
post {
    success {
        slackSend(
            channel: '#vmware-ops',
            color: 'good',
            message: "PowerCLI deployment completed successfully: ${env.BUILD_URL}"
        )
    }
}
```

### JIRA Integration
```groovy
post {
    failure {
        jiraCreateIssue(
            site: 'company-jira',
            project: 'VMWARE',
            issueType: 'Bug',
            summary: "Jenkins PowerCLI job failed: ${env.JOB_NAME}",
            description: "Build ${env.BUILD_NUMBER} failed. Check logs: ${env.BUILD_URL}"
        )
    }
}
```

## Resources

- [Jenkins PowerShell Plugin Documentation](https://plugins.jenkins.io/powershell/)
- [VMware PowerCLI Documentation](https://developer.vmware.com/powercli)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [PowerCLI Best Practices](../guides/best-practices.md)