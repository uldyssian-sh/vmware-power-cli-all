FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

LABEL maintainer="VMware PowerCLI Community" \
      version="1.0.0" \
      description="Enterprise VMware PowerCLI container with security hardening"

# Security: Create non-root user
RUN groupadd -r powercli && useradd -r -g powercli -s /bin/bash powercli

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set working directory
WORKDIR /app

# Copy PowerCLI installation script
COPY Install-PowerCLI-All.ps1 /app/
COPY scripts/ /app/scripts/

# Install PowerCLI as non-root user
USER powercli

RUN pwsh -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
RUN pwsh -File /app/Install-PowerCLI-All.ps1 -TrustPSGallery -DisableCeip

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pwsh -Command "Get-Module -ListAvailable VMware.PowerCLI | Select-Object -First 1"

# Security: Run as non-root
USER powercli

# Default command
CMD ["pwsh", "-NoLogo", "-NoExit"]# Auto-updated 20251109_123235
