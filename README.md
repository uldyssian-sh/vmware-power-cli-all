# VMware PowerCLI Complete Toolkit

<div align="center">


  
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

- **VM Management**: Bulk operations, configuration, migration
- **Host Operations**: ESXi configuration, maintenance, updates
- **Storage Management**: vSAN health, datastore operations
- **Network Configuration**: vSwitch setup, NSX automation

## 📚 Documentation

- [Getting Started](https://github.com/uldyssian-sh/vmware-power-cli-all/wiki/Getting-Started)
- [Script Reference](https://github.com/uldyssian-sh/vmware-power-cli-all/wiki/Scripts)
- [Best Practices](https://github.com/uldyssian-sh/vmware-power-cli-all/wiki/Best-Practices)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
