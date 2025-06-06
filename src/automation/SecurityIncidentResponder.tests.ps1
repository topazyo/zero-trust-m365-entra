Import-Module Pester -ErrorAction Stop # Pester itself is a module
. ../../src/playbook/PlaybookManager.ps1 # Dot-source
. ../../src/hunting/threat_hunter.ps1 # Dot-source
. ../../src/response/response_orchestrator.ps1 # Dot-source
. ../../src/intelligence/threat_intelligence_manager.ps1 # Dot-source
. ../../src/automation/Security_Incident_Responder.ps1 # Dot-source
Describe "SecurityIncidentResponder Tests" {
    $mockTenantId = "test-tenant-id"
    $sir = $null
    $mockPlaybookManager = $null
    $mockThreatHunter = $null
    $mockResponseOrchestrator = $null
    $mockThreatIntelClient = $null
    $resolvedNewObjectCmd = $null
    BeforeEach {
        # Ensure $mockTenantId is available (already defined in outer Describe scope, but good to be mindful)
        # $mockTenantId = "test-tenant-id"

        # Instantiate SUT ($sir) directly, *before* Mock New-Object is set up for its internal dependencies
        . ../../src/automation/Security_Incident_Responder.ps1 # Re-dot-source SUT script
        $sir = [SecurityIncidentResponder]::new($mockTenantId)

        # Placeholder will be replaced by the subtask script
        $resolvedNewObjectCmd = Get-Command "Microsoft.PowerShell.Utility\New-Object"

        $mockPlaybookManager = New-MockObject -Type PlaybookManager -Methods @{
            LoadPlaybooks = { param($path) $this.LoadedPlaybooks = @{ "MockedPlaybook" = @{ name="MockedPlaybook"; steps=@() }} }
            GetPlaybook = { param($name) if ($this.LoadedPlaybooks.ContainsKey($name)) { return $this.LoadedPlaybooks[$name] } else { return $null } }
        }
        $mockThreatHunter = New-MockObject -Type ThreatHunter -Methods @{ # Removed -ArgumentList
            CollectForensicData = { param($incidentId) return @{ ForensicData = ("Collected for " + $incidentId) } }
        }
        $mockResponseOrchestrator = New-MockObject -Type ResponseOrchestrator # Removed -ArgumentList
        $mockThreatIntelClient = New-MockObject -Type ThreatIntelligenceManager -Methods @{ # Removed -ArgumentList
            GetRelatedThreatIntel = { param($id) return @{ Intel = ("Intel for " + $id) } }
            UpdateThreatIntelligence = { param($iocs) Write-Host ("Mocked UpdateThreatIntelligence with " + $iocs.Count + " IOCs") }
        }

        Mock New-Object {
            param([string]$TypeName, [object[]]$ArgumentList)
            # Debug output for all calls to New-Object intercepted by the mock
            Write-Host "Mock New-Object Intercepted: TypeName = '$TypeName', ArgumentList Count = $($ArgumentList.Count)"
            if ($ArgumentList -ne $null -and $ArgumentList.Count -gt 0) {
                for ($i = 0; $i -lt $ArgumentList.Count; $i++) {
                    Write-Host "  ArgumentList[$i] = '$($ArgumentList[$i])', Type = '$($ArgumentList[$i].GetType().FullName)'"
                }
            }

            if ($TypeName -eq ([PlaybookManager].FullName)) { return $mockPlaybookManager }
            if ($TypeName -eq ([ThreatHunter].FullName)) { return $mockThreatHunter }
            if ($TypeName -eq ([ResponseOrchestrator].FullName)) { return $mockResponseOrchestrator }
            if ($TypeName -eq ([ThreatIntelligenceManager].FullName)) { return $mockThreatIntelClient }
            # No special handling for SecurityIncidentResponder here, as it's already instantiated.
            # This Mock New-Object is for dependencies *called by* SecurityIncidentResponder.

            # Fallback for any other types not explicitly handled by the mock.
            Write-Host "SUT Fallback to original New-Object for TypeName = '$TypeName'"
            & $resolvedNewObjectCmd -TypeName $TypeName -ArgumentList $ArgumentList
        } -Verifiable

        # $sir is already instantiated directly above. No need for this line:
        # $sir = New-Object SecurityIncidentResponder -ArgumentList $mockTenantId
    }
    AfterEach {
        # Remove-ModuleMock is not needed in Pester v5 for mocks defined in BeforeEach/It
        # Pester v5 automatically cleans them up.
    }
    Context "InitializeEngines Method" {
        It "populates engine properties" {
            $sir.ForensicEngine | Should -Be $mockThreatHunter
            $sir.AutomationEngine | Should -Be $mockResponseOrchestrator
            $sir.PlaybookManager | Should -Be $mockPlaybookManager
            $sir.ThreatIntelClient | Should -Be $mockThreatIntelClient
            Should -Invoke Verifiable -CommandName New-Object -Times 4 # Removed -ModuleName
        }
    }
    Context "LoadSecurityPlaybooks Method" {
        It "populates SecurityPlaybooks from PlaybookManager" {
            $sir.SecurityPlaybooks.Count | Should -BeGreaterThan 0
            $sir.SecurityPlaybooks["MockedPlaybook"] | Should -Not -BeNull
        }
    }
    Context "ClassifyIncident Method" {
        It "classifies Malware" { $sir._ClassifyIncident(@{ Title = "Malware Found"; Description = ""}) | Should -Be "MalwareDetection" }
        It "classifies Compromise" { $sir._ClassifyIncident(@{ Title = "Account Compromise"; Description = ""}) | Should -Be "AccountCompromise" }
        It "defaults to Unclassified" { $sir._ClassifyIncident(@{ Title = "Unknown Issue"; Description = "Misc problem"}) | Should -Be "Unclassified" }
    }
    Context "SelectPlaybook Method" {
        BeforeEach {
            # Ensure PlaybookManager mock is used and its LoadedPlaybooks can be set
            $sir.PlaybookManager.LoadedPlaybooks = @{
                "MalwarePlaybook" = @{ name="MalwarePlaybook"; defaultClassification = @("MalwareDetection"); steps=@() };
                "DefaultPlaybook" = @{ name="DefaultPlaybook"; defaultClassification = @("Unclassified", "Default"); steps=@() };
            }
            # Reflect this change in SIR's SecurityPlaybooks property as _LoadSecurityPlaybooks would do
            $sir.SecurityPlaybooks = $sir.PlaybookManager.LoadedPlaybooks
        }
        It "selects by defaultClassification" {
            $sir._SelectPlaybook("MalwareDetection").name | Should -Be "MalwarePlaybook"
        }
        It "falls back to DefaultPlaybook" {
            $sir._SelectPlaybook("ObscureRandomText").name | Should -Be "DefaultPlaybook"
        }
    }
    Context "ExecuteAction Method" {
        $mockContext = @{ IncidentId = "TEST001"; Tags = [System.Collections.Generic.List[string]]::new() }
        It "executes LogMessage" {
            Mock Write-Host {} -Verifiable # Removed -ModuleName
            $action = @{ actionType = "LogMessage"; parameters = @{ message = "Test log message"; level = "Info" } }
            $result = $sir._ExecuteAction($action, $mockContext)
            $result.Status | Should -Be "Success"
            $expectedLog = "[Info] Playbook Action Log: Test log message (Incident: " + $mockContext.IncidentId + ")"
            Should -Invoke Verifiable -CommandName Write-Host -ParametersList @($expectedLog) -Times 1
        }
        It "executes TagIncident" {
            $action = @{ actionType = "TagIncident"; parameters = @{ tagName = "TestTagValue" } }
            $result = $sir._ExecuteAction($action, $mockContext)
            $result.Status | Should -Be "Success"
            $mockContext.Tags | Should -Contain "TestTagValue"
        }
        It "executes mock InvokeBasicRestMethod" {
            Mock Write-Host {} -Verifiable # Removed -ModuleName
            $action = @{ actionType = "InvokeBasicRestMethod"; parameters = @{ uri = "http://example.com/api"; method = "POST" } }
            $result = $sir._ExecuteAction($action, $mockContext)
            $result.Status | Should -Be "Success"
            $result.Output | Should -Be ("Mocked REST call to http://example.com/api performed.")
            $expectedRestLog = "Mock REST Call: Would invoke POST to http://example.com/api"
            Should -Invoke Verifiable -CommandName Write-Host -ParametersList @($expectedRestLog) -Times 1
        }
        It "handles unknown action type" {
            $action = @{ actionType = "UnknownActionType" }
            $result = $sir._ExecuteAction($action, $mockContext)
            $result.Status | Should -Be "Failed"
            $result.Output | Should -Be "Unknown action type: UnknownActionType"
        }
        It "handles action throwing an error" {
            # Make one of the mocked Write-Host calls (from LogMessage action type) throw an error
            Mock Write-Host { throw "IntentionalErrorInAction" } # Removed -ModuleName
            $action = @{ actionType = "LogMessage"; parameters = @{ message = "Error test message" } }
            $result = $sir._ExecuteAction($action, $mockContext)
            $result.Status | Should -Be "Error"
            $result.Output | Should -Contain "IntentionalErrorInAction"
        }
    }
    Context "EngineCallDelegation Tests" {
         It "calls ForensicEngine CollectForensicData" {
            # Re-mock here if we want to verify this specific call with -Verifiable, or ensure the BeforeEach mock is Verifiable.
            # For simplicity, let's assume BeforeEach mocks are sufficient for behavior, and we verify the call.
            # If BeforeEach mocks are not -Verifiable, then we need to re-declare them here with -Verifiable.
            # Let's make the original mocks in BeforeEach verifiable.
            $sir._CollectForensicData("INC-001")
            Should -Invoke Verifiable -CommandName "CollectForensicData" -Instance $mockThreatHunter -Times 1
        }
        It "calls ThreatIntelClient UpdateThreatIntelligence" {
            $sir._UpdateThreatIntelligence(@("ioc1"))
            Should -Invoke Verifiable -CommandName "UpdateThreatIntelligence" -Instance $mockThreatIntelClient -Times 1
        }
        It "calls ThreatIntelClient GetRelatedThreatIntel" {
            $sir._GetRelatedThreatIntel("INC-001")
            Should -Invoke Verifiable -CommandName "GetRelatedThreatIntel" -Instance $mockThreatIntelClient -Times 1
        }
    }
}
