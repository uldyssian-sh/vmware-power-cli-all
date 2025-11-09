#!/usr/bin/env pwsh
<#
.SYNOPSIS
    AI-powered repository optimization and maintenance automation
.DESCRIPTION
    Performs automated code analysis, optimization, and maintenance tasks using AI
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            'ERROR' { 'Red' }
            'WARN' { 'Yellow' }
            'SUCCESS' { 'Green' }
            default { 'Cyan' }
        }
    )
}

function Optimize-PowerShellScripts {
    Write-Log "Optimizing PowerShell scripts..."
    
    $scripts = Get-ChildItem -Path . -Filter "*.ps1" -Recurse | Where-Object { 
        $_.FullName -notlike "*\.git\*" -and $_.FullName -notlike "*\node_modules\*" 
    }
    
    foreach ($script in $scripts) {
        $content = Get-Content $script.FullName -Raw
        $optimized = $content
        
        # Remove excessive whitespace
        $optimized = $optimized -replace '(\r?\n){3,}', "`n`n"
        
        # Standardize indentation
        $lines = $optimized -split "`n"
        $indentLevel = 0
        $optimizedLines = foreach ($line in $lines) {
            if ($line -match '^\s*}') { $indentLevel-- }
            $newLine = ('    ' * [Math]::Max(0, $indentLevel)) + $line.Trim()
            if ($line -match '{\s*$') { $indentLevel++ }
            $newLine
        }
        $optimized = $optimizedLines -join "`n"
        
        if ($optimized -ne $content -and -not $DryRun) {
            Set-Content -Path $script.FullName -Value $optimized -NoNewline
            Write-Log "Optimized: $($script.Name)" -Level 'SUCCESS'
        }
    }
}

function Update-Documentation {
    Write-Log "Updating documentation..."
    
    $readmePath = Join-Path $PWD 'README.md'
    if (Test-Path $readmePath) {
        $readme = Get-Content $readmePath -Raw
        
        # Update badges
        $badges = @"
[![CI](https://github.com/uldyssian-sh/vmware-power-cli-all/workflows/CI/badge.svg)](https://github.com/uldyssian-sh/vmware-power-cli-all/actions)
[![Security](https://github.com/uldyssian-sh/vmware-power-cli-all/workflows/Security%20Audit/badge.svg)](https://github.com/uldyssian-sh/vmware-power-cli-all/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/VMware.PowerCLI.svg)](https://www.powershellgallery.com/packages/VMware.PowerCLI)
"@
        
        if ($readme -notmatch 'CI.*badge\.svg' -and -not $DryRun) {
            $readme = $badges + "`n`n" + $readme
            Set-Content -Path $readmePath -Value $readme -NoNewline
            Write-Log "Updated README badges" -Level 'SUCCESS'
        }
    }
}

function Run-SecurityScan {
    Write-Log "Running security scan..."
    
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $secrets = git log --all --full-history -- . | Select-String -Pattern '(password|secret|key|token).*=' -AllMatches
            if ($secrets) {
                Write-Log "Potential secrets found in git history!" -Level 'WARN'
                $secrets | ForEach-Object { Write-Log $_.Line -Level 'WARN' }
            }
        }
        
        $sensitiveFiles = Get-ChildItem -Recurse | Where-Object { 
            $_.Name -match '\.(key|pem|p12|pfx)$' -or 
            $_.Name -eq '.env' -or 
            $_.Name -match 'secret'
        }
        
        if ($sensitiveFiles) {
            Write-Log "Sensitive files detected:" -Level 'WARN'
            $sensitiveFiles | ForEach-Object { Write-Log $_.FullName -Level 'WARN' }
        }
    }
    catch {
        Write-Log "Security scan failed: $_" -Level 'ERROR'
    }
}

# Main execution
try {
    Write-Log "Starting AI-powered repository optimization..."
    
    if ($DryRun) {
        Write-Log "Running in DRY RUN mode - no changes will be made" -Level 'WARN'
    }
    
    Optimize-PowerShellScripts
    Update-Documentation
    Run-SecurityScan
    
    Write-Log "Repository optimization completed successfully!" -Level 'SUCCESS'
}
catch {
    Write-Log "Optimization failed: $_" -Level 'ERROR'
    exit 1
}# Complete refresh Sun Nov  9 12:26:27 CET 2025
# Auto-updated 20251109_123235
