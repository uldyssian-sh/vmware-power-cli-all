$ErrorActionPreference = "Stop"
﻿<#
.SYNOPSIS
  Install or update VMware PowerCLI (all modules) strictly to *CurrentUser* and
  print a summary to the PowerCLI console. Includes robust fallbacks & diagnostics.

.DESCRIPTION
  Order of operations (first success wins):
    1) PSResourceGet  : Install-PSResource -Scope CurrentUser
    2) PowerShellGet  : Install-Module    -Scope CurrentUser
    3) PowerShellGet  : Save-Module to a user-writable path, then Import-Module

  The script:
    - Forces TLS 1.2 for gallery downloads
    - Ensures PSGallery exists (optionally marks Trusted)
    - Ensures NuGet provider exists for CurrentUser
    - Verifies & creates the user module path
    - Imports PowerCLI and lists all VMware.* modules

  Zero elevation required (unless your org blocks user-scoped installs entirely).

.NOTES
  Author: LT
  Version: 1.0
  Target: VMware vSphere 7/8
#>

[CmdletBinding()]
param(
  # Best-effort: mark PSGallery as Trusted (to suppress prompts); no failure on denial.
  [switch]$TrustPSGallery,

  # Quietly opt out of CEIP at user scope (avoids interactive prompt).
  [switch]$DisableCeip
)

# ----------------- Console helpers -----------------
function Write-Info($m){ Write-Host "[INFO ] $m" -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host "[WARN ] $m" -ForegroundColor Yellow }
function Write-Ok  ($m){ Write-Host "[ OK  ] $m" -ForegroundColor Green }
function Write-Err ($m){ Write-Host "[FAIL ] $m" -ForegroundColor Red }

# ----------------- Paths & env -----------------
function Get-UserModulePath {
  if ($PSVersionTable.PSEdition -eq 'Core') {
    # PowerShell 7+
    return Join-Path $HOME 'Documents\PowerShell\Modules'
  } else {
    # Windows PowerShell 5.1
    return Join-Path $HOME 'Documents\WindowsPowerShell\Modules'
  }
}

$UserModules = Get-UserModulePath
if (-not (Test-Path $UserModules)) {
  try {
    New-Item -Path $UserModules -ItemType Directory -Force | Out-Null
    Write-Ok "Ensured user module path: $UserModules"
  } catch {
    Write-Err "Cannot create user module path '$UserModules'. $_"
    exit 1
  }
}

# Ensure $UserModules is in PSModulePath (some locked-down images remove it)
if (";$env:PSModulePath;" -notlike "*;$UserModules;*") {
  $env:PSModulePath = "$UserModules;$env:PSModulePath"
  Write-Info "Prepended user module path to PSModulePath."
}

# ----------------- Environment checks -----------------
Write-Info "PowerShell $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion) on $([System.Environment]::OSVersion.VersionString)"
if ($PSVersionTable.PSVersion.Major -lt 5) {
  Write-Err "PowerShell 5.1+ or 7+ is required."
  exit 1
}

# Use TLS 1.2 for gallery connectivity
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch { }

# ----------------- PSGallery & NuGet provider -----------------
$psg = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if (-not $psg) {
  Write-Info "Registering PSGallery…"
  try {
    Register-PSRepository -Default -ErrorAction Stop
    $psg = Get-PSRepository -Name PSGallery -ErrorAction Stop
    Write-Ok "PSGallery registered."
  } catch {
    Write-Err "Failed to register PSGallery. $_"
    exit 1
  }
}

if ($TrustPSGallery) {
  try {
    if ($psg.InstallationPolicy -ne 'Trusted') {
      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
      Write-Ok "PSGallery marked as Trusted."
    } else {
      Write-Info "PSGallery already Trusted."
    }
  } catch {
    Write-Warn "Could not set PSGallery to Trusted (policy may block). You may see prompts."
  }
}

# NuGet provider strictly for CurrentUser (PowerShellGet path)
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
  Write-Info "Installing NuGet provider to CurrentUser…"
  try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
    Write-Ok "NuGet provider installed (CurrentUser)."
  } catch {
    Write-Warn "NuGet provider install (CurrentUser) failed. Continuing; PSResourceGet may still work."
  }
}

# ----------------- Attempt 1: PSResourceGet -----------------
$installer = $null
$attempts  = @()

if (Get-Command Install-PSResource -ErrorAction SilentlyContinue) {
  $attempts += 'PSResourceGet'
  try {
    Write-Info "Attempt 1/3 (PSResourceGet): Install-PSResource -Name VMware.PowerCLI -Scope CurrentUser"
    Install-PSResource -Name VMware.PowerCLI -Scope CurrentUser -TrustRepository -Reinstall -ErrorAction Stop
    $installer = 'PSResourceGet'
    Write-Ok "VMware.PowerCLI installed via PSResourceGet (CurrentUser)."
  } catch {
    Write-Warn "PSResourceGet failed: $($_.Exception.Message)"
  }
}

# ----------------- Attempt 2: PowerShellGet Install-Module -----------------
if (-not $installer) {
  $attempts += 'PowerShellGet:Install-Module'
  try {
    Write-Info "Attempt 2/3 (PowerShellGet): Install-Module -Name VMware.PowerCLI -Scope CurrentUser"
    Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Repository PSGallery -AllowClobber -Force -ErrorAction Stop
    $installer = 'PowerShellGet:Install-Module'
    Write-Ok "VMware.PowerCLI installed via PowerShellGet (CurrentUser)."
  } catch {
    Write-Warn "Install-Module failed: $($_.Exception.Message)"
  }
}

# ----------------- Attempt 3: PowerShellGet Save-Module + Import -----------------
if (-not $installer) {
  $attempts += 'PowerShellGet:Save-Module'
  $temp = Join-Path ([System.IO.Path]::GetTempPath()) ("VMware.PowerCLI_" + [Guid]::NewGuid().ToString('N'))
  New-Item -Path $temp -ItemType Directory -Force | Out-Null
  try {
    Write-Info "Attempt 3/3 (PowerShellGet): Save-Module VMware.PowerCLI to $temp"
    Save-Module -Name VMware.PowerCLI -Path $temp -Repository PSGallery -Force -ErrorAction Stop
    # Copy to the canonical user module location
    $savedModuleRoot = Join-Path $temp 'VMware.PowerCLI'
    if (-not (Test-Path $savedModuleRoot)) {
      throw "Save-Module completed but 'VMware.PowerCLI' folder was not found under $temp."
    }
    $destRoot = Join-Path $UserModules 'VMware.PowerCLI'
    if (-not (Test-Path $destRoot)) { New-Item -Path $destRoot -ItemType Directory -Force | Out-Null }
    # Move versioned folders
    Get-ChildItem -Path $savedModuleRoot -Directory | ForEach-Object {
      $dest = Join-Path $destRoot $_.Name
      if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
      Copy-Item -Recurse -Force -Path $_.FullName -Destination $dest
    }
    $installer = 'PowerShellGet:Save-Module'
    Write-Ok "VMware.PowerCLI saved & staged into $destRoot."
  } catch {
    Write-Err "All installation attempts failed. Last error: $($_.Exception.Message)"
    Write-Info "Attempts tried: $($attempts -join ', ')"
    Write-Info "If your organization blocks user-scope package installs, request a private repo or run in an elevated session."
    exit 1
  } finally {
    try { Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue } catch { }
  }
}

# ----------------- Optional CEIP tweak -----------------
if ($DisableCeip -and (Get-Command Set-PowerCLIConfiguration -ErrorAction SilentlyContinue)) {
  try {
    Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP:$false -Confirm:$false | Out-Null
    Write-Ok "PowerCLI CEIP participation disabled (User scope)."
  } catch {
    Write-Warn "Could not set CEIP preference: $($_.Exception.Message)"
  }
}

# ----------------- Import & summarize -----------------
try {
  Import-Module VMware.PowerCLI -ErrorAction Stop
  Write-Ok "VMware.PowerCLI imported."
} catch {
  Write-Err "Import-Module VMware.PowerCLI failed: $($_.Exception.Message)"
  Write-Info "Check PSModulePath includes: $UserModules"
  exit 1
}

$modules = Get-Module -ListAvailable VMware.* |
           Sort-Object Name, Version -Unique |
           Select-Object Name, Version, ModuleBase

Write-Host ""
Write-Host "=== PowerCLI Installation Summary ===" -ForegroundColor Green
"{0,-14}: {1}" -f "Installer", $installer
"{0,-14}: {1}" -f "Modules",   ($modules.Count)
"{0,-14}: {1}" -f "UserPath",  $UserModules
Write-Host ""

$modules |
  Select-Object @{n='Module';e={$_.Name}},
                @{n='Version';e={$_.Version}},
                @{n='Path';e={$_.ModuleBase}} |
  Format-Table -AutoSize

Write-Host ""
Write-Info "Next: Connect-VIServer -Server <vcenter.example.com>"
Write-Info "Tip : Get-Command -Module VMware.* | Out-Host -Paging"
# Complete refresh Sun Nov  9 12:26:27 CET 2025
# Auto-updated 20251109_123235
