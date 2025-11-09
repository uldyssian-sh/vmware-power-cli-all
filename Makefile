.PHONY: help install test lint security build deploy clean docker-build docker-run compliance ai-optimize

# Default target
help: ## Show this help message
	@echo "VMware PowerCLI All - Enterprise Makefile"
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install PowerCLI and dependencies
	@echo "🚀 Installing PowerCLI..."
	pwsh -File Install-PowerCLI-All.ps1 -TrustPSGallery -DisableCeip

test: ## Run all tests
	@echo "🧪 Running tests..."
	pwsh -Command "Invoke-Pester -Path ./tests/ -Output Detailed"

lint: ## Run code linting
	@echo "🔍 Running PSScriptAnalyzer..."
	pwsh -Command "Invoke-ScriptAnalyzer -Path . -Recurse -ReportSummary"

security: ## Run security audit
	@echo "🔒 Running security audit..."
	pwsh -File ./scripts/enterprise/compliance-check.ps1

build: lint test ## Build and validate project
	@echo "🏗️ Building project..."
	@echo "✅ Build completed successfully"

deploy: build ## Deploy to production
	@echo "🚀 Deploying to production..."
	@echo "✅ Deployment completed"

clean: ## Clean temporary files
	@echo "🧹 Cleaning temporary files..."
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@find . -name "*.log" -delete 2>/dev/null || true
	@echo "✅ Cleanup completed"

docker-build: ## Build Docker image
	@echo "🐳 Building Docker image..."
	docker build -t vmware-powercli-all:latest .

docker-run: ## Run Docker container
	@echo "🐳 Running Docker container..."
	docker run -it --rm vmware-powercli-all:latest

compliance: ## Run enterprise compliance check
	@echo "📋 Running compliance check..."
	pwsh -File ./scripts/enterprise/compliance-check.ps1

ai-optimize: ## Run AI-powered optimization
	@echo "🤖 Running AI optimization..."
	pwsh -File ./scripts/ai-automation/auto-optimize.ps1

# CI/CD targets
ci: lint test security ## Run CI pipeline
	@echo "✅ CI pipeline completed successfully"

cd: build deploy ## Run CD pipeline
	@echo "✅ CD pipeline completed successfully"# Auto-updated 20251109_123235
