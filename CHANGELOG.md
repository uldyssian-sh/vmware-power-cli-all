# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive test suite with Pester
- GitHub Actions CI/CD pipeline
- Security scanning and vulnerability assessment
- Cross-platform compatibility testing
- Advanced documentation and tutorials
- Community contribution guidelines

### Changed
- Enhanced error handling and diagnostics
- Improved console output formatting
- Better cross-platform path handling

### Security
- Removed any potential sensitive information exposure
- Enhanced input validation and sanitization
- Implemented secure coding practices

## [1.0.0] - 2024-01-15

### Added
- Initial release of VMware PowerCLI Complete Installation Suite
- Three-tier installation strategy (PSResourceGet, PowerShellGet, Save-Module)
- User-scope installation without administrator privileges
- Cross-platform support (Windows, macOS, Linux)
- Robust error handling and fallback mechanisms
- Console-friendly output with color coding
- Optional CEIP (Customer Experience Improvement Program) opt-out
- Optional PSGallery trust configuration
- Comprehensive module verification and listing

### Features
- **Zero-Admin Installation**: Install PowerCLI without elevated privileges
- **Multi-Platform Support**: Works on Windows PowerShell 5.1 and PowerShell 7.x
- **Robust Fallbacks**: Three different installation methods for maximum compatibility
- **Security Hardened**: No hardcoded credentials or sensitive information
- **User-Friendly**: Clear console output with progress indicators

### Technical Details
- Supports PowerShell 5.1+ and PowerShell 7.x
- Automatic TLS 1.2 configuration for secure downloads
- Dynamic user module path detection and creation
- PSModulePath environment variable management
- NuGet provider installation for CurrentUser scope
- PSGallery repository registration and configuration

### Installation Methods
1. **PSResourceGet (Modern)**
   ```powershell
   Install-PSResource -Name VMware.PowerCLI -Scope CurrentUser
   ```

2. **PowerShellGet (Classic)**
   ```powershell
   Install-Module -Name VMware.PowerCLI -Scope CurrentUser
   ```

3. **Save-Module (Fallback)**
   ```powershell
   Save-Module -Name VMware.PowerCLI -Path $TempPath
   # Manual staging to user module directory
   ```

### Parameters
- `-TrustPSGallery`: Marks PowerShell Gallery as trusted to suppress prompts
- `-DisableCeip`: Opts out of VMware Customer Experience Improvement Program

### Compatibility
- **Windows**: PowerShell 5.1, PowerShell 7.x
- **macOS**: PowerShell 7.x
- **Linux**: PowerShell 7.x
- **VMware vSphere**: 6.7, 7.0, 8.0
- **VMware vCenter**: 6.7, 7.0, 8.0

### Known Issues
- Some corporate environments may block user-scope package installations
- Certificate validation warnings may appear in restrictive environments
- PowerShell execution policy may need adjustment for script execution

### Migration Notes
- This is the initial release, no migration required
- Existing PowerCLI installations will be updated to the latest version
- User-scope installations take precedence over system-wide installations

---

## Release Notes Format

### Types of Changes
- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes

### Version Numbering
This project uses [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality additions
- **PATCH** version for backwards-compatible bug fixes

### Release Process
1. Update CHANGELOG.md with new version
2. Create release branch
3. Run full test suite
4. Create GitHub release with release notes
5. Merge to main branch
6. Deploy to PowerShell Gallery (planned)