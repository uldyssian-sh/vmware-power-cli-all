# VMware PowerCLI Complete Toolkit

<div align="center">

```
┌─────────────────────────────────────────────────────────────┐
│                PowerCLI Automation Toolkit                 │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ PowerShell  │────│ PowerCLI    │────│ VMware      │     │
│  │   Core      │    │  Modules    │    │ vSphere API │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                   │                   │          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ Automation  │    │ Bulk        │    │ Reporting   │     │
│  │ Scripts     │    │ Operations  │    │ Dashboard   │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
└─────────────────────────────────────────────────────────────┘
```
  
  [![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-5391FE.svg)](https://github.com/PowerShell/PowerShell)
  [![PowerCLI](https://img.shields.io/badge/PowerCLI-13.0+-00A1C9.svg)](https://www.vmware.com/support/developer/PowerCLI/)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
</div>

## 🚀 Overview

Comprehensive PowerCLI toolkit for VMware infrastructure automation. Complete collection of scripts, modules, and best practices for vSphere, vSAN, NSX, and vRealize management.

## ⚡ Quick Start

```powershell
# Install PowerCLI
Install-Module -Name VMware.PowerCLI -Scope CurrentUser

# Clone repository
git clone https://github.com/uldyssian-sh/vmware-power-cli-all.git
cd vmware-power-cli-all

# Connect to vCenter
Connect-VIServer -Server vcenter.example.com

# Run bulk VM creation
.\Scripts\Create-BulkVMs.ps1 -CsvPath "vms.csv"
```

## 📦 Script Categories

```
📁 PowerCLI Toolkit Structure
├── 🖥️  VM-Management/
│   ├── Create-BulkVMs.ps1
│   ├── Configure-VMSettings.ps1
│   └── Migrate-VMs.ps1
├── 🏠 Host-Operations/
│   ├── Configure-ESXiHosts.ps1
│   ├── Update-HostProfiles.ps1
│   └── Maintenance-Mode.ps1
├── 💾 Storage-Management/
│   ├── vSAN-HealthCheck.ps1
│   ├── Datastore-Operations.ps1
│   └── Storage-Policies.ps1
└── 🌐 Network-Config/
    ├── Configure-vSwitches.ps1
    ├── NSX-Automation.ps1
    └── Load-Balancer-Config.ps1
```

## 📚 Documentation

- [Getting Started](https://github.com/uldyssian-sh/vmware-power-cli-all/wiki/Getting-Started)
- [Script Reference](https://github.com/uldyssian-sh/vmware-power-cli-all/wiki/Scripts)
- [Best Practices](https://github.com/uldyssian-sh/vmware-power-cli-all/wiki/Best-Practices)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
