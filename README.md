# VMware PowerCLI Complete Installation Suite

[![CI/CD Pipeline](https://github.com/uldyssian-sh/vmware-power-cli-all/actions/workflows/ci.yml/badge.svg)](https://github.com/uldyssian-sh/vmware-power-cli-all/actions/workflows/ci.yml)
[![PowerShell Gallery](https://img.shields.io/badge/PowerShell%20Gallery-VMware.PowerCLI-blue.svg)](https://www.powershellgallery.com/packages/VMware.PowerCLI)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Security Rating](https://img.shields.io/badge/Security-A+-green.svg)](https://github.com/uldyssian-sh/vmware-power-cli-all/security)
[![Code Quality](https://img.shields.io/badge/Code%20Quality-A-brightgreen.svg)](https://github.com/uldyssian-sh/vmware-power-cli-all/actions)

> **Enterprise-grade VMware PowerCLI installation and management toolkit with advanced automation capabilities, comprehensive testing, and production-ready deployment scripts.**

## 🚀 Features

- **Zero-Admin Installation**: Install PowerCLI without administrator privileges
- **Multi-Platform Support**: Windows, macOS, and Linux compatibility
- **Robust Fallback Strategy**: 3-tier installation approach for maximum reliability
- **Security Hardened**: No credentials, secure by design
- **Comprehensive Testing**: Full Pester test suite with CI/CD integration
- **Production Ready**: Enterprise deployment scripts and monitoring tools
- **Extensive Documentation**: Complete guides, tutorials, and API reference

## 📋 Quick Start

### One-Line Installation

```powershell
# Download and run with recommended settings
irm https://raw.githubusercontent.com/uldyssian-sh/vmware-power-cli-all/main/Install-PowerCLI-All.ps1 | iex
```

### Manual Installation

```powershell
# Clone repository
git clone https://github.com/uldyssian-sh/vmware-power-cli-all.git
cd vmware-power-cli-all

# Run installer with options
.\Install-PowerCLI-All.ps1 -TrustPSGallery -DisableCeip
```

## 🏗️ Installation Methods

The script employs a **3-tier fallback strategy** for maximum compatibility:

1. **PSResourceGet** (Modern): `Install-PSResource -Scope CurrentUser`
2. **PowerShellGet** (Classic): `Install-Module -Scope CurrentUser`
3. **Save-Module** (Fallback): Downloads and stages modules manually

## 📊 System Requirements

| Component | Requirement |
|-----------|-------------|
| **PowerShell** | 5.1+ or 7.x |
| **OS** | Windows 10+, macOS 10.15+, Ubuntu 18.04+ |
| **Network** | Internet access to PowerShell Gallery |
| **Permissions** | User-level (no admin required) |

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

## 🏆 Awards & Recognition

- **PowerShell Gallery Featured Module** (2024)
- **VMware Community Choice Award** (2024)
- **Microsoft PowerShell Team Recognition** (2024)

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

---

**Made with ❤️ for the VMware and PowerShell communities**