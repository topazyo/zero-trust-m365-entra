Import-Module Pester -ErrorAction SilentlyContinue # Allow to fail if Pester not yet installed by main script
if (-not (Get-Command Invoke-Pester -ErrorAction SilentlyContinue)) {
    Write-Error "Pester is not available. Skipping setup script tests."
    # In a CI environment, this script might exit here or be skipped.
    # For this subtask, we'll proceed assuming Pester will be available when tests are actually run.
}
# Dot-source the main script to access its functions
. ./scripts/setup/install_dependencies.ps1
# Individual helper scripts are standalone, so they are tested by invoking them.
# We can mock their internal cmdlets.
Describe "Setup Scripts Tests" {
    Context "Install-RequiredModules Function" {
        # Mock external cmdlets used by Install-RequiredModules
        BeforeEach {
            # Ensure mocks are reset for each test
            Remove-ModuleMock -ModuleName PowerShellGet -CommandName Get-Module -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName PowerShellGet -CommandName Install-Module -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Microsoft.PowerShell.Core -CommandName Import-Module -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName PowerShellGet -CommandName Install-PackageProvider -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName PowerShellGet -CommandName Get-PackageProvider -ErrorAction SilentlyContinue
            Mock Get-Module -ModuleName PowerShellGet { return $null } -ParameterFilter { $Name -eq $args[0] -and $ListAvailable }
            Mock Install-Module -ModuleName PowerShellGet { Write-Host "Mocked Install-Module for $($Name)" } -Verifiable
            Mock Import-Module -ModuleName Microsoft.PowerShell.Core { Write-Host "Mocked Import-Module for $($Name)" } -Verifiable
            Mock Install-PackageProvider -ModuleName PowerShellGet { Write-Host "Mocked Install-PackageProvider for $($Name)"} -Verifiable
            Mock Get-PackageProvider -ModuleName PowerShellGet { return $true } # Assume NuGet provider is found after install attempt or already there
            $global:PesterModuleVersionInstalled = $null
        }
        AfterEach {
            Remove-ModuleMock -ModuleName PowerShellGet -CommandName Get-Module -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName PowerShellGet -CommandName Install-Module -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Microsoft.PowerShell.Core -CommandName Import-Module -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName PowerShellGet -CommandName Install-PackageProvider -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName PowerShellGet -CommandName Get-PackageProvider -ErrorAction SilentlyContinue
        }
        It "attempts to install and import a module that is not installed" {
            $modulesToInstall = @{ "TestModule1" = "1.0.0" }
            Install-RequiredModules -modules $modulesToInstall
            Should -Invoke Verifiable -CommandName Install-Module -Times 1 -ParametersList @{ Name = "TestModule1"; RequiredVersion = "1.0.0"; Scope = "CurrentUser"; SkipPublisherCheck = $true; AllowClobber = $true; AcceptLicense = $true; Force = $true; ErrorAction = [System.Management.Automation.ActionPreference]::Stop }
            Should -Invoke Verifiable -CommandName Import-Module -Times 1 -ParametersList @{ Name = "TestModule1"; RequiredVersion = "1.0.0"; Force = $true; ErrorAction = [System.Management.Automation.ActionPreference]::Stop }
        }
        It "does not attempt to install if correct version of module is already installed" {
            # Specific mock for this test case
            Mock Get-Module -ModuleName PowerShellGet { return @{ Name = "TestModule2"; Version = [System.Version]::new("2.0.0") } } -ParameterFilter { $Name -eq "TestModule2" -and $ListAvailable } -लेल्याRemovePrevious # Remove general Get-Module mock
            $modulesToInstall = @{ "TestModule2" = "2.0.0" }
            Install-RequiredModules -modules $modulesToInstall
            Should -Invoke Verifiable -CommandName Install-Module -Times 0
            Should -Invoke Verifiable -CommandName Import-Module -Times 1 -ParametersList @{ Name = "TestModule2"; RequiredVersion = "2.0.0"; Force = $true; ErrorAction = [System.Management.Automation.ActionPreference]::Stop }
        }
        It "sets global Pester version if Pester is installed" {
             Mock Get-Module -ModuleName PowerShellGet {
                if ($Name -eq "Pester") { return @{ Name = "Pester"; Version = [System.Version]::new("5.5.0") } } # Return a version object
                return $null
            } -ParameterFilter { $Name -eq $args[0] -and $ListAvailable } -लेल्याRemovePrevious
            Mock Import-Module -ModuleName Microsoft.PowerShell.Core {
                 if($args[0].Name -eq "Pester") { # Simulate Pester's own Get-Module call during import if any
                    Mock Get-Module -ModuleName Pester { return @{ Name = "Pester"; Version = [System.Version]::new("5.5.0") } }
                 }
                Write-Host "Mocked Import-Module for $($args[0].Name)"
            } -Verifiable
            $modulesToInstall = @{ "Pester" = "5.5.0" }
            Install-RequiredModules -modules $modulesToInstall
            $global:PesterModuleVersionInstalled | Should -Be "5.5.0"
        }
        It "attempts to install NuGet provider if not found" {
            Mock Get-PackageProvider -ModuleName PowerShellGet { return $null } -लेल्याRemovePrevious # Simulate NuGet not found initially
            Install-RequiredModules -modules @{}
            Should -Invoke Verifiable -CommandName Install-PackageProvider -Times 1 -ParametersList @{ Name = "NuGet"; MinimumVersion = "2.8.5.201"; Force = $true; Scope = "CurrentUser"; ErrorAction = [System.Management.Automation.ActionPreference]::Stop }
        }
    }
    Context "Connect-ZeroTrustServices Function" {
        BeforeEach {
            Remove-ModuleMock -ModuleName Microsoft.Graph.Authentication -CommandName Connect-MgGraph -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Az.Accounts -CommandName Connect-AzAccount -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Microsoft.Graph.Authentication -CommandName Get-MgContext -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Az.Accounts -CommandName Get-AzContext -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Microsoft.PowerShell.Core -CommandName Write-Host -ErrorAction SilentlyContinue # For Test-ServiceConnections.ps1 check
            Mock Connect-MgGraph -ModuleName Microsoft.Graph.Authentication { Write-Host "Mocked Connect-MgGraph" } -Verifiable
            Mock Connect-AzAccount -ModuleName Az.Accounts { Write-Host "Mocked Connect-AzAccount" } -Verifiable
            Mock Get-MgContext -ModuleName Microsoft.Graph.Authentication { return $null }
            Mock Get-AzContext -ModuleName Az.Accounts { return $null }
            # Mock the specific Write-Host call from Test-ServiceConnections.ps1 to verify it was dot-sourced
            Mock Write-Host -ModuleName Microsoft.PowerShell.Core {
                param($Message)
                if ($Message -eq "Executing REAL Test-ServiceConnections.ps1...") {
                    Write-Host "Test-ServiceConnections.ps1 was dot-sourced" # This will be our verifiable call
                } elseif ($Message -like "Microsoft Graph connection confirmed by global status*") {
                     Write-Host $Message # Allow this through
                } elseif ($Message -like "Azure connection not established or status unknown*") {
                     Write-Host $Message # Allow this through
                }
                # Add other conditions if other Write-Host calls from Test-ServiceConnections are expected
            } -Verifiable
            $global:GraphConnectionStatus = "NotConnected"
            $global:AzureConnectionStatus = "NotConnected"
        }
        AfterEach {
            Remove-ModuleMock -ModuleName Microsoft.Graph.Authentication -CommandName Connect-MgGraph -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Az.Accounts -CommandName Connect-AzAccount -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Microsoft.Graph.Authentication -CommandName Get-MgContext -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Az.Accounts -CommandName Get-AzContext -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Microsoft.PowerShell.Core -CommandName Write-Host -ErrorAction SilentlyContinue
        }
        It "attempts to connect to Graph and Azure, and calls Test-ServiceConnections" {
            $config = @{ TenantId = "test-tenant"; RequiredScopes = @("User.Read") }
            Connect-ZeroTrustServices -config $config
            Should -Invoke Verifiable -CommandName Connect-MgGraph -Times 1
            Should -Invoke Verifiable -CommandName Connect-AzAccount -Times 1
            Should -Invoke Verifiable -CommandName Write-Host -ParametersList "Test-ServiceConnections.ps1 was dot-sourced" -Times 1
        }
        It "sets global status to Connected if Get-MgContext returns context" {
            Mock Get-MgContext -ModuleName Microsoft.Graph.Authentication { return @{ TenantId = "graph-tenant"; Account = "user@graph" } } -लेल्याRemovePrevious
            Connect-ZeroTrustServices -config @{}
            $global:GraphConnectionStatus | Should -Be "Connected: graph-tenant"
        }
        It "sets global status to Connected if Get-AzContext returns context" {
            Mock Get-AzContext -ModuleName Az.Accounts { return @{ Tenant = @{Id = "az-tenant"}; Account = @{Id="user@az"} } } -लेल्याRemovePrevious
            Connect-ZeroTrustServices -config @{}
            $global:AzureConnectionStatus | Should -Be "Connected: az-tenant"
        }
    }
    Context "Helper Script: Test-ServiceConnections.ps1" {
        BeforeEach {
            Remove-ModuleMock -CommandName Write-Host -ErrorAction SilentlyContinue
            Remove-ModuleMock -CommandName Write-Warning -ErrorAction SilentlyContinue
            Mock Write-Host {} -Verifiable
            Mock Write-Warning {} -Verifiable
        }
        AfterEach {
            Remove-ModuleMock -CommandName Write-Host -ErrorAction SilentlyContinue
            Remove-ModuleMock -CommandName Write-Warning -ErrorAction SilentlyContinue
        }
        It "reports Graph connected if global var indicates so" {
            $global:GraphConnectionStatus = "Connected: test-graph-tenant"
            $global:AzureConnectionStatus = "NotConnected" # Set specific state for this test
            . ./scripts/setup/Test-ServiceConnections.ps1
            Should -Invoke Verifiable -CommandName Write-Host -Times 1 -ParametersList @("Microsoft Graph connection confirmed by global status: Connected: test-graph-tenant")
            Should -Invoke Verifiable -CommandName Write-Warning -Times 1 -ParametersList @("Azure connection not established or status unknown. Global status: NotConnected")
        }
    }
    Context "Helper Script: Test-Prerequisites.ps1" {
        It "runs without throwing a terminating error on Linux" {
            # Mock $IsWindows, $IsLinux, $IsMacOS if necessary for consistent testing across environments
            # Assuming it runs in a Linux-like environment for this test based on sandbox
            { . ./scripts/setup/Test-Prerequisites.ps1 } | Should -Not -Throw
        }
    }
    Context "Helper Script: Initialize-SecurityBaselines.ps1" {
        BeforeEach {
            Remove-ModuleMock -ModuleName Microsoft.PowerShell.Management -CommandName Test-Path -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Microsoft.PowerShell.Management -CommandName Set-Content -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Microsoft.PowerShell.Utility -CommandName ConvertTo-Json -ErrorAction SilentlyContinue
            Mock Test-Path { param($PathValue) return $false } -ModuleName Microsoft.PowerShell.Management -Verifiable
            Mock Set-Content {} -ModuleName Microsoft.PowerShell.Management -Verifiable
            Mock ConvertTo-Json { param($InputObject) return "{""mock"":""json""}" } -ModuleName Microsoft.PowerShell.Utility -Verifiable
        }
        AfterEach {
            Remove-ModuleMock -ModuleName Microsoft.PowerShell.Management -CommandName Test-Path -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Microsoft.PowerShell.Management -CommandName Set-Content -ErrorAction SilentlyContinue
            Remove-ModuleMock -ModuleName Microsoft.PowerShell.Utility -CommandName ConvertTo-Json -ErrorAction SilentlyContinue
        }
        It "creates baselines file if it does not exist" {
            . ./scripts/setup/Initialize-SecurityBaselines.ps1 -BaselineConfigPath "./config/security_baselines.json" # Pass param
            Should -Invoke Verifiable -CommandName Test-Path -Times 1
            Should -Invoke Verifiable -CommandName Set-Content -Times 1
            Should -Invoke Verifiable -CommandName ConvertTo-Json -Times 1
        }
    }
}