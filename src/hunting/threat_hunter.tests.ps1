Import-Module Pester -ErrorAction Stop
# Dot-source the class script. $PSScriptRoot refers to the dir of the .tests.ps1 file.
. $PSScriptRoot/threat_hunter.ps1

Describe "ThreatHunter Tests" {
    $mockTenantId = "test-th-tenant"
    $mockWorkspaceId = "MOCK_WORKSPACE_ID_FROM_TEST"
    $mockEngineConfig = @{ LogAnalyticsWorkspaceId = $mockWorkspaceId }
    $th = $null
    $testRulesDir = Join-Path $PSScriptRoot "temp_th_rules_dir"

    BeforeEach {
        # Mock global Azure connection status, assuming it's connected for most tests
        $global:AzureConnectionStatus = "Connected: $mockTenantId"

        # Mock cmdlets that _ExecuteHuntingQuery and _LoadHuntingRules might call
        # These prevent actual module installs or query executions during unit tests.
        Mock Invoke-AzOperationalInsightsQuery -ModuleName Az.OperationalInsights -MockWith {
            param($WorkspaceId, $Query)
            Write-Host "Mocked Invoke-AzOperationalInsightsQuery for WS: $WorkspaceId, Query: $Query"
            # Return a PSCustomObject with a 'Results' property which is an array
            return [PSCustomObject]@{
                Results = @(
                    [PSCustomObject]@{ Timestamp = Get-Date; EventID = 4625; TargetUserName = "UserA"; IpAddress = "1.2.3.4" },
                    [PSCustomObject]@{ Timestamp = Get-Date; EventID = 4688; ProcessName = "evil.exe"; CommandLine = "evil.exe -run" }
                )
            }
        }

        Mock ConvertFrom-Yaml -ModuleName powershell-yaml -MockWith {
            param($Yaml)
            Write-Host "Mocked ConvertFrom-Yaml"
            # Simulate parsing based on content, or return predefined structure
            if ($Yaml -like "*MinimalRule*") {
                return @(
                    @{ ruleName="MinimalRule"; query="SecurityEvent | take 1"; severity="Low"; enabled=$true }
                )
            }
            if ($Yaml -like "*DisabledRule*") {
                 return @(
                    @{ ruleName="DisabledRule"; query="SecurityEvent | take 1"; severity="Low"; enabled=$false }
                )
            }
            return @() # Default empty
        }

        # Allow Import-Module for powershell-yaml to succeed in tests by default
        # Tests for fallback can specifically mock Import-Module to throw for powershell-yaml
        Mock Import-Module -ModuleName PowerShellGet -MockWith { param($Name) Write-Host "Mocked Import-Module for $Name" }


        $th = [ThreatHunter]::new($mockTenantId, $mockEngineConfig) # Constructor calls _InitializeHuntingEngine, _LoadHuntingRules

        # Setup for _LoadHuntingRules tests
        if (Test-Path $testRulesDir) {
            Remove-Item -Path $testRulesDir -Recurse -Force
        }
        New-Item -Path $testRulesDir -ItemType Directory | Out-Null
        # Override rules file path for tests if ThreatHunter's path is hardcoded internally
        # For this test, we assume _LoadHuntingRules can be made to point to $testRulesDir or we mock Get-Content
    }

    AfterEach {
        if (Test-Path $testRulesDir) {
            Remove-Item -Path $testRulesDir -Recurse -Force
        }
        Clear-Variable -Name global:AzureConnectionStatus -ErrorAction SilentlyContinue
    }

    Context "Constructor and Initialization" {
        It "should instantiate and initialize HuntingEngine correctly with config" {
            $th | Should -Not -BeNull
            $th.TenantId | Should -Be $mockTenantId
            $th.EngineConfig.LogAnalyticsWorkspaceId | Should -Be $mockWorkspaceId
            $th.HuntingEngine | Should -Not -BeNull
            $th.HuntingEngine.Status | Should -Be "Initialized_LogAnalytics_Ready"
            $th.HuntingEngine.WorkspaceId | Should -Be $mockWorkspaceId
        }

        It "_InitializeHuntingEngine handles missing WorkspaceID in config" {
            $badConfig = @{ LogAnalyticsWorkspaceId = "YOUR_LOG_ANALYTICS_WORKSPACE_ID" }
            $tempTh = [ThreatHunter]::new($mockTenantId, $badConfig)
            $tempTh.HuntingEngine.Status | Should -Be "Error_WorkspaceId_Not_Configured" # As per current logic
        }

        It "_InitializeHuntingEngine handles missing Azure Connection" {
            $global:AzureConnectionStatus = "NotConnected"
            $tempTh = [ThreatHunter]::new($mockTenantId, $mockEngineConfig)
            $tempTh.HuntingEngine.Status | Should -Be "Warning_Azure_Not_Connected" # or Initialized_LogAnalytics_Ready but with warning status
            $tempTh.HuntingEngine.AzureConnectionGlobalStatus | Should -Be "NotConnected"
        }
    }

    Context "_LoadHuntingRules Method" {
        # To properly test _LoadHuntingRules, we need to control its access to the YAML file
        # Easiest is to mock Get-Content and Test-Path for the specific rules file path used internally by _LoadHuntingRules
        $internalRulesPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "../..")) "config/hunting_rules.yaml"

        It "loads enabled rules from a valid YAML file via mocked Get-Content" {
            $yamlContent = @"
            - ruleName: "TestRule1"
              query: "SecurityEvent | where EventID == 4625"
              severity: "High"
              enabled: true
            - ruleName: "TestRule2_Disabled"
              query: "SecurityEvent | where EventID == 4688"
              severity: "Medium"
              enabled: false
"@
            Mock Test-Path -ModuleName Microsoft.PowerShell.Management -MockWith { param($Path) if($Path -eq $internalRulesPath) { return $true } else { return $false } }
            Mock Get-Content -ModuleName Microsoft.PowerShell.Management -MockWith { param($Path) if($Path -eq $internalRulesPath) { return $yamlContent } else { return "" } }
            Mock ConvertFrom-Yaml -ModuleName powershell-yaml -MockWith { return @(@{ ruleName="TestRule1"; query="SecurityEvent | where EventID == 4625"; severity="High"; enabled=$true }, @{ ruleName="TestRule2_Disabled"; query="SecurityEvent | where EventID == 4688"; severity="Medium"; enabled=$false }) }

            $th._LoadHuntingRules() # Call directly to test
            $th.HuntingRules.Count | Should -Be 1
            $th.HuntingRules["TestRule1"] | Should -Not -BeNull
            $th.HuntingRules["TestRule1"].severity | Should -Be "High"
        }

        It "falls back to mock rules if YAML module (ConvertFrom-Yaml) is not available" {
            Mock Test-Path -ModuleName Microsoft.PowerShell.Management -MockWith { param($Path) if($Path -eq $internalRulesPath) { return $true } else { return $false } }
            Mock Get-Content -ModuleName Microsoft.PowerShell.Management -MockWith { param($Path) if($Path -eq $internalRulesPath) { return "some yaml content" } else { return "" } }
            Mock Import-Module -ModuleName PowerShellGet -MockWith { param($Name) if ($Name -eq "powershell-yaml") { throw "Module not found" } } # Simulate module import failure

            $th._LoadHuntingRules()
            $th.HuntingRules.Count | Should -BeGreaterOrEqualTo 1 # Check for fallback rules
            $th.HuntingRules.ContainsKey("Fallback_HighSeverityLogonFailures") | Should -Be $true
        }
    }

    Context "_ExecuteHuntingQuery Method" {
        It "calls Invoke-AzOperationalInsightsQuery with correct parameters" {
            $testRule = @{ ruleName="TestQueryRule"; query="Heartbeat | take 1"; severity="Low"; enabled=$true }
            $results = $th._ExecuteHuntingQuery($testRule)
            Should -Invoke "Invoke-AzOperationalInsightsQuery" -Times 1 -Exactly -Scope It -ParameterFilter {
                $WorkspaceId -eq $mockWorkspaceId -and $Query -eq $testRule.query
            }
            $results | Should -Not -BeNull
            $results.Count | Should -Be 2 # From the default mock of Invoke-AzOperationalInsightsQuery
        }

        It "returns $null if engine is not ready" {
            $th.HuntingEngine.Status = "Error_Whatever"
            $testRule = @{ ruleName="TestQueryRule"; query="Heartbeat | take 1" }
            $th._ExecuteHuntingQuery($testRule) | Should -BeNull
        }
    }

    Context "_AnalyzeHuntingResults Method" {
        It "extracts IOCs from typical query results" {
            $sampleResults = @(
                [PSCustomObject]@{ EventID = 4625; TargetUserName = "UserA"; IpAddress = "10.0.0.5"; Computer = "Host1" },
                [PSCustomObject]@{ EventID = 4688; ProcessName = "cmd.exe"; CommandLine = "cmd /c whoami"; ParentProcessName = "explorer.exe"; Computer = "Host2" },
                [PSCustomObject]@{ FileHash = "HASH123"; FileName = "evil.dll" },
                [PSCustomObject]@{ Url = "http://malicious.com/payload"; DestinationIPAddress = "20.30.40.50"}
            )
            $analysis = $th._AnalyzeHuntingResults($sampleResults)
            $analysis.Indicators | Should -Not -BeNull
            $analysis.Indicators | Should -Contain "User:UserA"
            $analysis.Indicators | Should -Contain "IP:10.0.0.5"
            $analysis.Indicators | Should -Contain "Host:Host1"
            $analysis.Indicators | Should -Contain "Process:cmd.exe"
            $analysis.Indicators | Should -Contain "CommandLine:cmd /c whoami"
            $analysis.Indicators | Should -Contain "ParentProcess:explorer.exe"
            $analysis.Indicators | Should -Contain "Host:Host2"
            $analysis.Indicators | Should -Contain "FileHash:HASH123"
            $analysis.Indicators | Should -Contain "URL:http://malicious.com/payload"
            $analysis.Indicators | Should -Contain "DestinationIP:20.30.40.50"
            $analysis.AnalyzedResultsCount | Should -Be $sampleResults.Count
            $analysis.Summary | Should -StartWith "Analyzed $($sampleResults.Count) result(s). Found $($analysis.Indicators.Count) unique potential IOC(s)."
        }

        It "returns empty Indicators for empty results" {
            $analysis = $th._AnalyzeHuntingResults(@())
            $analysis.Indicators | Should -BeEmpty
            $analysis.AnalyzedResultsCount | Should -Be 0
        }
    }

    Context "ExecuteHunt Method" {
        It "executes a specific enabled rule if its name is passed" {
            # Setup a specific rule in HuntingRules
            $th.HuntingRules = @{
                "MySpecificRule" = @{ ruleName="MySpecificRule"; query="Heartbeat | take 1"; severity="Medium"; enabled=$true }
                "OtherRule" = @{ ruleName="OtherRule"; query="SecurityEvent | take 1"; severity="Low"; enabled=$true }
            }
            Mock -CommandName "_ExecuteHuntingQuery" -MockWith { param($rule) return @( @{Data="Result for $($rule.ruleName)"} ) } -ParameterFilter { $Instance -eq $th }
            Mock -CommandName "_AnalyzeHuntingResults" -MockWith { @{Indicators=@("IOC:Test"); Summary="Analyzed"} } -ParameterFilter { $Instance -eq $th }
            Mock -CommandName "_ProcessThreatIndicator" -ParameterFilter { $Instance -eq $th }
            Mock -CommandName "_DocumentHuntingResults" -ParameterFilter { $Instance -eq $th }

            $th.ExecuteHunt("MySpecificRule")

            Should -Invoke "_ExecuteHuntingQuery" -Times 1 -Exactly -Scope It -ParameterFilter { $rule.ruleName -eq "MySpecificRule" }
            Should -Invoke "_AnalyzeHuntingResults" -Times 1 -Exactly -Scope It
            Should -Invoke "_DocumentHuntingResults" -Times 1 -Exactly -Scope It
        }

        It "executes all enabled rules if no specific huntIdToMatch is provided or found" {
             $th.HuntingRules = @{
                "RuleA_Enabled" = @{ ruleName="RuleA_Enabled"; query="QueryA"; severity="Medium"; enabled=$true };
                "RuleB_Disabled" = @{ ruleName="RuleB_Disabled"; query="QueryB"; severity="Low"; enabled=$false };
                "RuleC_Enabled" = @{ ruleName="RuleC_Enabled"; query="QueryC"; severity="High"; enabled=$true }
            }
            Mock -CommandName "_ExecuteHuntingQuery" -MockWith { param($rule) return @( @{Data="Result for $($rule.ruleName)"} ) } -ParameterFilter { $Instance -eq $th }
            Mock -CommandName "_AnalyzeHuntingResults" -ParameterFilter { $Instance -eq $th } # Assume it's called if results
            Mock -CommandName "_DocumentHuntingResults" -ParameterFilter { $Instance -eq $th }

            $th.ExecuteHunt("") # Empty string, or a non-matching rule name

            Should -Invoke "_ExecuteHuntingQuery" -Times 2 -Exactly -Scope It # For RuleA and RuleC
            # We can also check parameters if needed:
            Should -Invoke "_ExecuteHuntingQuery" -ParameterFilter { $rule.ruleName -eq "RuleA_Enabled" } -Scope It
            Should -Invoke "_ExecuteHuntingQuery" -ParameterFilter { $rule.ruleName -eq "RuleC_Enabled" } -Scope It
        }
    }

    # Existing CollectForensicData tests from original file
    Context "CollectForensicData Method" {
        It "returns a structured hashtable with forensic artifacts" {
            $identifier = "machine-01"
            $artifacts = $th.CollectForensicData($identifier)

            $artifacts | Should -Not -BeNull
            $artifacts | Should -BeOfType ([hashtable])
            $artifacts.PSObject.Properties.Name | Should -Contain @("CollectedFrom", "CollectionTimeUTC", "Processes", "NetworkConnections", "Files", "LogSources")
            $artifacts.CollectedFrom | Should -Be $identifier
            $artifacts.Processes | Should -BeOfType ([array])
            $artifacts.Processes.Count | Should -BeGreaterThanOrEqual 2 # Based on its current mock impl
        }

        It "includes additional artifacts for critical identifiers" {
            $identifier = "server-critical-007"
            $artifacts = $th.CollectForensicData($identifier)

            $artifacts | Should -Not -BeNull
            $artifacts.CustomAlert | Should -Not -BeNullOrEmpty
            $artifacts.Processes.Name | Should -Contain "ransom.exe"
        }
    }
}
