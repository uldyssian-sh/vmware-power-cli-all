# 🚀 VMware PowerCLI Complete Installation Suite

[![CI/CD Pipeline](https://github.com/uldyssian-sh/vmware-power-cli-all/actions/workflows/ci.yml/badge.svg)](https://github.com/uldyssian-sh/vmware-power-cli-all/actions/workflows/ci.yml)
[![PowerShell Gallery](https://img.shields.io/badge/PowerShell%20Gallery-VMware.PowerCLI-blue.svg)](https://www.powershellgallery.com/packages/VMware.PowerCLI)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/uldyssian-sh/vmware-power-cli-all?style=social)](https://github.com/uldyssian-sh/vmware-power-cli-all/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/uldyssian-sh/vmware-power-cli-all?style=social)](https://github.com/uldyssian-sh/vmware-power-cli-all/network/members)

> **🎯 Enterprise-grade VMware PowerCLI installation and management toolkit with advanced automation capabilities, comprehensive testing, and production-ready deployment scripts.**

**Author**: LT - [GitHub Profile](https://github.com/uldyssian-sh)

**⚡ Zero-admin installation • 🔒 Security hardened • 🌐 Cross-platform • 📊 Enterprise ready**

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🔧 **Zero-Admin Installation** | Install PowerCLI without administrator privileges |
| 🌍 **Cross-Platform** | Windows, macOS, and Linux compatibility |
| 🛡️ **3-Tier Fallback** | PSResourceGet → PowerShellGet → Save-Module |
| 🔒 **Security First** | No hardcoded credentials, secure by design |
| 🧪 **Comprehensive Testing** | Full Pester test suite with CI/CD integration |
| 🏢 **Enterprise Ready** | Production deployment scripts and monitoring |
| 📚 **Rich Documentation** | Complete guides, tutorials, and examples |

## ⚡ Quick Start

### 🎯 One-Line Installation (Recommended)

```powershell
# Download and execute with optimal settings
irm https://raw.githubusercontent.com/uldyssian-sh/vmware-power-cli-all/main/Install-PowerCLI-All.ps1 | iex
```

### 📦 Manual Installation

```powershell
# 1. Clone repository
git clone https://github.com/uldyssian-sh/vmware-power-cli-all.git
cd vmware-power-cli-all

# 2. Run installer with enterprise options
.\Install-PowerCLI-All.ps1 -TrustPSGallery -DisableCeip -Verbose

# 3. Verify installation
Get-PowerCLIVersion
```

## 🏗️ Installation Strategy

**Smart 3-Tier Fallback System** for maximum compatibility:

```
┌─────────────────┐
│ Start Install   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐    Yes    ┌─────────────────┐
│ PSResourceGet?  │ ────────► │ Install-Resource│
└─────────┬───────┘           └─────────┬───────┘
          │ No                          │
          ▼                             │
┌─────────────────┐    Yes    ┌─────────┴───────┐
│ PowerShellGet?  │ ────────► │ Install-Module  │
└─────────┬───────┘           └─────────┬───────┘
          │ No                          │
          ▼                             │
┌─────────────────┐           ┌─────────▼───────┐
│ Save-Module +   │ ────────► │   ✅ Success    │
│ Manual Stage    │           └─────────────────┘
└─────────────────┘
```

1. 🆕 **PSResourceGet** (Modern) - Latest PowerShell package management
2. 🔄 **PowerShellGet** (Classic) - Traditional module installation
3. 💾 **Save-Module** (Fallback) - Manual staging for restricted environments

## 📊 System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| 💻 **PowerShell** | 5.1 | 7.4+ |
| 🖥️ **Windows** | 10 (1903+) | 11 |
| 🍎 **macOS** | 10.15 | 13+ |
| 🐧 **Linux** | Ubuntu 18.04 | Ubuntu 22.04+ |
| 🌐 **Network** | Internet access | High-speed connection |
| 🔐 **Permissions** | User-level | User-level (no admin!) |
| 💾 **Disk Space** | 500 MB | 1 GB |
| 🧠 **Memory** | 2 GB | 4 GB |

## 🔧 Advanced Usage

### Enterprise Deployment

```powershell
# Silent installation for enterprise environments
.\Install-PowerCLI-All.ps1 -TrustPSGallery -DisableCeip -Verbose

# Verify installation
Get-Module VMware.* -ListAvailable | Format-Table Name, Version, ModuleBase
```

### Custom Configuration

```powershell
# Configure PowerCLI settings
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
```

## 📚 Documentation

- **[Installation Guide](docs/guides/installation.md)** - Detailed installation instructions
- **[Troubleshooting](docs/troubleshooting/common-issues.md)** - Common issues and solutions
- **[API Reference](docs/api/powercli-cmdlets.md)** - Complete cmdlet reference
- **[Tutorials](docs/tutorials/)** - Step-by-step learning guides
- **[Examples](examples/)** - Real-world automation scripts

## 🧪 Testing

Run the complete test suite:

```powershell
# Install Pester
Install-Module -Name Pester -Force -Scope CurrentUser

# Run tests
Invoke-Pester -Path .\tests\ -Output Detailed
```

## 🔒 Security

- **No Hardcoded Credentials**: All sensitive data externalized
- **Secure by Design**: User-scope installation only
- **Regular Security Scans**: Automated vulnerability testing
- **Code Signing**: All scripts digitally signed (coming soon)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📈 Project Stats

![GitHub stars](https://img.shields.io/github/stars/uldyssian-sh/vmware-power-cli-all?style=social)
![GitHub forks](https://img.shields.io/github/forks/uldyssian-sh/vmware-power-cli-all?style=social)
![GitHub issues](https://img.shields.io/github/issues/uldyssian-sh/vmware-power-cli-all)
![GitHub pull requests](https://img.shields.io/github/issues-pr/uldyssian-sh/vmware-power-cli-all)

## 🏆 Project Highlights

- 🌟 **23+ comprehensive files** with enterprise-grade structure
- 🔧 **8 automation scripts** for advanced PowerCLI operations
- 📋 **Full CI/CD pipeline** with multi-platform testing
- 🛡️ **Security scanning** and vulnerability assessment
- 📚 **Complete documentation** suite with tutorials
- 🤝 **Community-driven** with contribution guidelines

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/uldyssian-sh/vmware-power-cli-all/issues)
- **Discussions**: [GitHub Discussions](https://github.com/uldyssian-sh/vmware-power-cli-all/discussions)
- **Wiki**: [Project Wiki](https://github.com/uldyssian-sh/vmware-power-cli-all/wiki)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- VMware PowerCLI Team for the excellent PowerShell modules
- PowerShell Community for continuous support and feedback
- Contributors who help improve this project

## 🚀 Getting Started

1. **[📖 Read the Tutorial](docs/tutorials/getting-started.md)** - Complete beginner's guide
2. **[⚡ Quick Install](#-quick-start)** - Get up and running in 30 seconds
3. **[🔧 Advanced Usage](docs/guides/installation.md)** - Enterprise deployment options
4. **[❓ Need Help?](docs/troubleshooting/common-issues.md)** - Troubleshooting guide

---

<div align="center">

**⭐ Star this repo if it helped you! ⭐**

**Made with ❤️ for the VMware and PowerShell communities**

[Report Bug](https://github.com/uldyssian-sh/vmware-power-cli-all/issues) • [Request Feature](https://github.com/uldyssian-sh/vmware-power-cli-all/issues) • [Contribute](CONTRIBUTING.md)

</div>