# VMware PowerCLI Installation Suite - Makefile
# Cross-platform automation for development and testing

.PHONY: help install test lint clean docs build release

# Default target
help: ## Show this help message
	@echo "VMware PowerCLI Installation Suite - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Installation and setup
install: ## Install development dependencies
	@echo "Installing development dependencies..."
	@pwsh -Command "Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck"
	@pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser"
	@pwsh -Command "Install-Module -Name platyPS -Force -Scope CurrentUser"
	@echo "✓ Development dependencies installed"

setup: install ## Setup development environment
	@echo "Setting up development environment..."
	@mkdir -p logs reports coverage
	@echo "✓ Development environment ready"

# Testing
test: ## Run all tests
	@echo "Running Pester tests..."
	@pwsh -Command "Invoke-Pester -Path ./tests/ -Output Detailed"

test-coverage: ## Run tests with coverage report
	@echo "Running tests with coverage analysis..."
	@pwsh -Command "\
		$$config = New-PesterConfiguration; \
		$$config.Run.Path = './tests'; \
		$$config.TestResult.Enabled = $$true; \
		$$config.TestResult.OutputPath = './reports/test-results.xml'; \
		$$config.CodeCoverage.Enabled = $$true; \
		$$config.CodeCoverage.Path = './Install-PowerCLI-All.ps1'; \
		$$config.CodeCoverage.OutputPath = './coverage/coverage.xml'; \
		Invoke-Pester -Configuration $$config"

test-integration: ## Run integration tests
	@echo "Running integration tests..."
	@pwsh -Command "Invoke-Pester -Path ./tests/integration/ -Output Detailed"

# Code quality
lint: ## Run PSScriptAnalyzer
	@echo "Running PSScriptAnalyzer..."
	@pwsh -Command "\
		$$results = Invoke-ScriptAnalyzer -Path . -Recurse -ReportSummary; \
		if ($$results) { \
			$$results | Format-Table; \
			Write-Error 'PSScriptAnalyzer found issues'; \
			exit 1 \
		} else { \
			Write-Host '✓ No PSScriptAnalyzer issues found' -ForegroundColor Green \
		}"

format: ## Format PowerShell code
	@echo "Formatting PowerShell code..."
	@pwsh -Command "\
		Get-ChildItem -Path . -Filter '*.ps1' -Recurse | ForEach-Object { \
			$$content = Get-Content $$_.FullName -Raw; \
			$$formatted = Invoke-Formatter -ScriptDefinition $$content; \
			Set-Content -Path $$_.FullName -Value $$formatted -NoNewline \
		}"

security-scan: ## Run security analysis
	@echo "Running security analysis..."
	@pwsh -Command "\
		$$results = Invoke-ScriptAnalyzer -Path . -Recurse -IncludeRule PSAvoidPlainTextForPassword,PSAvoidUsingConvertToSecureStringWithPlainText,PSAvoidUsingUsernameAndPasswordParams; \
		if ($$results) { \
			$$results | Format-Table; \
			Write-Warning 'Security issues found' \
		} else { \
			Write-Host '✓ No security issues found' -ForegroundColor Green \
		}"

# Documentation
docs: ## Generate documentation
	@echo "Generating documentation..."
	@pwsh -Command "\
		if (Get-Module -ListAvailable platyPS) { \
			Import-Module platyPS; \
			New-MarkdownHelp -Module VMware.PowerCLI -OutputFolder ./docs/api -Force \
		} else { \
			Write-Warning 'platyPS module not available. Install with: Install-Module platyPS' \
		}"

docs-serve: ## Serve documentation locally (requires Python)
	@echo "Starting local documentation server..."
	@cd docs && python -m http.server 8000

# Validation
validate: lint test ## Run all validation checks
	@echo "✓ All validation checks completed"

validate-ci: ## Run CI validation (no interactive prompts)
	@echo "Running CI validation..."
	@$(MAKE) lint
	@$(MAKE) test
	@$(MAKE) security-scan
	@echo "✓ CI validation completed"

# Build and release
build: validate ## Build release package
	@echo "Building release package..."
	@mkdir -p dist
	@pwsh -Command "\
		$$version = '1.0.0'; \
		$$files = @('Install-PowerCLI-All.ps1', 'README.md', 'LICENSE', 'CHANGELOG.md'); \
		Compress-Archive -Path $$files -DestinationPath \"./dist/vmware-powercli-installer-v$$version.zip\" -Force"
	@echo "✓ Release package created in ./dist/"

release-notes: ## Generate release notes
	@echo "Generating release notes..."
	@pwsh -Command "\
		$$changelog = Get-Content CHANGELOG.md -Raw; \
		$$latestSection = ($$changelog -split '## \[')[1]; \
		$$releaseNotes = '## ' + $$latestSection.Split('## ')[0]; \
		$$releaseNotes | Out-File -FilePath './dist/RELEASE_NOTES.md' -Encoding UTF8"

# Maintenance
clean: ## Clean build artifacts and temporary files
	@echo "Cleaning build artifacts..."
	@rm -rf dist/ reports/ coverage/ logs/ temp/
	@pwsh -Command "Get-ChildItem -Path . -Name '*.tmp', '*.log', 'TestResults.xml' -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue"
	@echo "✓ Cleaned build artifacts"

clean-modules: ## Remove installed development modules
	@echo "Removing development modules..."
	@pwsh -Command "\
		$$modules = @('Pester', 'PSScriptAnalyzer', 'platyPS'); \
		foreach ($$module in $$modules) { \
			if (Get-Module -ListAvailable $$module) { \
				Uninstall-Module $$module -AllVersions -Force -ErrorAction SilentlyContinue; \
				Write-Host \"Removed $$module\" -ForegroundColor Yellow \
			} \
		}"

update-deps: ## Update development dependencies
	@echo "Updating development dependencies..."
	@pwsh -Command "\
		Update-Module Pester -Force; \
		Update-Module PSScriptAnalyzer -Force; \
		Update-Module platyPS -Force -ErrorAction SilentlyContinue"
	@echo "✓ Dependencies updated"

# Git operations
git-hooks: ## Install Git hooks
	@echo "Installing Git hooks..."
	@cp .githooks/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✓ Git hooks installed"

# Development helpers
dev-install: ## Install PowerCLI using the development script
	@echo "Installing PowerCLI using development script..."
	@pwsh -Command "./Install-PowerCLI-All.ps1 -TrustPSGallery -DisableCeip -Verbose"

dev-test-install: ## Test installation in isolated environment
	@echo "Testing installation in clean environment..."
	@pwsh -Command "\
		$$env:PSModulePath = [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine'); \
		./Install-PowerCLI-All.ps1 -TrustPSGallery -DisableCeip -Verbose"

benchmark: ## Run performance benchmarks
	@echo "Running performance benchmarks..."
	@pwsh -Command "\
		$$installTime = Measure-Command { ./Install-PowerCLI-All.ps1 -TrustPSGallery -DisableCeip }; \
		$$importTime = Measure-Command { Import-Module VMware.PowerCLI }; \
		Write-Host \"Installation time: $$($installTime.TotalSeconds) seconds\" -ForegroundColor Cyan; \
		Write-Host \"Import time: $$($importTime.TotalSeconds) seconds\" -ForegroundColor Cyan"

# Platform-specific targets
windows-test: ## Run Windows-specific tests
	@echo "Running Windows-specific tests..."
	@powershell -Command "Invoke-Pester -Path ./tests/windows/ -Output Detailed"

linux-test: ## Run Linux-specific tests
	@echo "Running Linux-specific tests..."
	@pwsh -Command "Invoke-Pester -Path ./tests/linux/ -Output Detailed"

macos-test: ## Run macOS-specific tests
	@echo "Running macOS-specific tests..."
	@pwsh -Command "Invoke-Pester -Path ./tests/macos/ -Output Detailed"

# Continuous Integration targets
ci-setup: ## Setup CI environment
	@echo "Setting up CI environment..."
	@$(MAKE) install
	@echo "✓ CI environment ready"

ci-test: ## Run CI test suite
	@echo "Running CI test suite..."
	@$(MAKE) validate-ci
	@echo "✓ CI tests completed"

ci-build: ## Build for CI
	@echo "Building for CI..."
	@$(MAKE) build
	@echo "✓ CI build completed"

# Information targets
info: ## Show project information
	@echo "VMware PowerCLI Installation Suite"
	@echo "=================================="
	@echo "Version: 1.0.0"
	@echo "PowerShell Version: $$(pwsh -Command '$$PSVersionTable.PSVersion')"
	@echo "Platform: $$(pwsh -Command '[System.Environment]::OSVersion.Platform')"
	@echo "Architecture: $$(pwsh -Command '[System.Environment]::Is64BitProcess')"

status: ## Show project status
	@echo "Project Status:"
	@echo "==============="
	@echo "Git Status:"
	@git status --porcelain
	@echo ""
	@echo "Last Commit:"
	@git log -1 --oneline
	@echo ""
	@echo "Branch:"
	@git branch --show-current

# Default development workflow
dev: clean install lint test ## Complete development workflow
	@echo "✓ Development workflow completed successfully"

# Production release workflow  
release: clean validate build release-notes ## Complete release workflow
	@echo "✓ Release workflow completed successfully"
	@echo "Release package available in ./dist/"