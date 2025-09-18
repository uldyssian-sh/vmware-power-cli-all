#!/usr/bin/env pwsh

BeforeAll {
    $script:ModuleName = 'VMware.PowerCLI'
    $script:ScriptPath = Join-Path $PSScriptRoot '..' 'Install-PowerCLI-All.ps1'
}

Describe 'Install-PowerCLI-All Script Tests' {
    Context 'Script Validation' {
        It 'Should exist' {
            Test-Path $script:ScriptPath | Should -Be $true
        }

        It 'Should have valid PowerShell syntax' {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script:ScriptPath -Raw), [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }

        It 'Should pass PSScriptAnalyzer rules' {
            if (Get-Module -ListAvailable PSScriptAnalyzer) {
                $results = Invoke-ScriptAnalyzer -Path $script:ScriptPath
                $results | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Parameter Validation' {
        It 'Should accept TrustPSGallery parameter' {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$null)
            $params = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.ParameterAst]}, $true)
            $params.Name.VariablePath.UserPath | Should -Contain 'TrustPSGallery'
        }

        It 'Should accept DisableCeip parameter' {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$null)
            $params = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.ParameterAst]}, $true)
            $params.Name.VariablePath.UserPath | Should -Contain 'DisableCeip'
        }
    }

    Context 'Function Tests' {
        BeforeAll {
            . $script:ScriptPath
        }

        It 'Should define Get-UserModulePath function' {
            Get-Command Get-UserModulePath -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should return valid user module path' {
            $path = Get-UserModulePath
            $path | Should -Not -BeNullOrEmpty
            $path | Should -Match 'Documents'
        }
    }

    Context 'Environment Checks' {
        It 'Should work with PowerShell 5.1+' {
            $PSVersionTable.PSVersion.Major | Should -BeGreaterOrEqual 5
        }

        It 'Should have access to PowerShell Gallery' {
            $gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
            $gallery | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Security Tests' {
        It 'Should not contain hardcoded credentials' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Not -Match 'password\s*='
            $content | Should -Not -Match 'secret\s*='
            $content | Should -Not -Match 'apikey\s*='
        }

        It 'Should use secure protocols' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Tls12'
        }
    }
}