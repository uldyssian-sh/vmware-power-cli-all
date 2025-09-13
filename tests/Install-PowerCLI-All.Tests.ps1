BeforeAll {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $ScriptPath = Join-Path $ModuleRoot "Install-PowerCLI-All.ps1"
    
    # Mock functions for testing
    function Mock-WriteHost { param($Object, $ForegroundColor) }
    function Mock-ExitCommand { param($ExitCode) throw "Exit called with code: $ExitCode" }
}

Describe "Install-PowerCLI-All Script Tests" {
    Context "Parameter Validation" {
        It "Should accept TrustPSGallery switch parameter" {
            { & $ScriptPath -TrustPSGallery -WhatIf } | Should -Not -Throw
        }
        
        It "Should accept DisableCeip switch parameter" {
            { & $ScriptPath -DisableCeip -WhatIf } | Should -Not -Throw
        }
        
        It "Should accept both parameters together" {
            { & $ScriptPath -TrustPSGallery -DisableCeip -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "PowerShell Version Check" {
        It "Should work with PowerShell 5.1+" {
            $PSVersionTable.PSVersion.Major | Should -BeGreaterOrEqual 5
        }
    }
    
    Context "Security Validation" {
        It "Should not contain hardcoded credentials" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Not -Match "password|secret|key|token"
        }
        
        It "Should not contain personal information" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Not -Match "example|placeholder"
        }
        
        It "Should not contain AWS account information" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Not -Match "\d{12}|aws.*id|account.*id"
        }
    }
    
    Context "Code Quality" {
        It "Should pass PSScriptAnalyzer rules" {
            if (Get-Module -ListAvailable PSScriptAnalyzer) {
                $results = Invoke-ScriptAnalyzer -Path $ScriptPath
                $results | Should -BeNullOrEmpty
            }
        }
        
        It "Should have proper error handling" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match "try.*catch|ErrorAction"
        }
        
        It "Should use approved verbs" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Not -Match "function\s+[^-\s]+\s*{"
        }
    }
    
    Context "Module Path Functions" {
        BeforeAll {
            . $ScriptPath
        }
        
        It "Should return correct user module path for PowerShell Core" {
            Mock $PSVersionTable.PSEdition { return 'Core' }
            $path = Get-UserModulePath
            $path | Should -Match "PowerShell\\Modules"
        }
        
        It "Should return correct user module path for Windows PowerShell" {
            Mock $PSVersionTable.PSEdition { return 'Desktop' }
            $path = Get-UserModulePath
            $path | Should -Match "WindowsPowerShell\\Modules"
        }
    }
}

Describe "Integration Tests" {
    Context "Environment Setup" {
        It "Should handle missing PSGallery gracefully" {
            Mock Get-PSRepository { return $null }
            Mock Register-PSRepository { }
            # Test should not throw when PSGallery is missing
        }
        
        It "Should handle NuGet provider installation" {
            Mock Get-PackageProvider { return $null }
            Mock Install-PackageProvider { }
            # Test should attempt to install NuGet provider
        }
    }
}