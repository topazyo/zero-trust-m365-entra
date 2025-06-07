Import-Module Pester -ErrorAction Stop # Pester itself is a module
. ../../src/playbook/PlaybookManager.ps1 # Dot-source
. ../../src/hunting/threat_hunter.ps1 # Dot-source
. ../../src/response/response_orchestrator.ps1 # Dot-source
. ../../src/intelligence/threat_intelligence_manager.ps1 # Dot-source
. ../../src/automation/SecurityIncidentResponder.ps1 # Dot-source
Describe "SecurityIncidentResponder Tests" {
    $mockTenantId = "test-tenant-id"
    $sir = $null
    $mockPlaybookManager = $null
    $mockThreatHunter = $null
    $mockResponseOrchestrator = $null
    $mockThreatIntelClient = $null
    # $resolvedNewObjectCmd = $null # Removed: No longer using global New-Object mock

    BeforeEach {
        # 1. Modify BeforeEach for direct dependency injection
        # . ../../src/automation/SecurityIncidentResponder.ps1 # This is already at the top of the Describe block

        # Create mock objects for dependencies
        $mockPlaybookManager = New-MockObject -Type PlaybookManager -Methods @{
            LoadPlaybooks = { param($path) $this.LoadedPlaybooks = @{ "MockedPlaybook" = @{ name="MockedPlaybook"; steps=@() }} } # Existing mock behavior
            GetPlaybook = { param($name) if ($this.LoadedPlaybooks.ContainsKey($name)) { return $this.LoadedPlaybooks[$name] } else { return $null } } # Existing mock behavior
        }
        $mockThreatHunter = New-MockObject -Type ThreatHunter -Methods @{
            CollectForensicData = { param($incidentId) return @{ ForensicData = ("Collected for " + $incidentId) } } # Existing mock behavior
        }
        $mockResponseOrchestrator = New-MockObject -Type ResponseOrchestrator # No specific methods needed for current tests, or add as needed

        $mockThreatIntelClient = New-MockObject -Type ThreatIntelligenceManager -Methods @{
            GetRelatedThreatIntel = { param($id) return @{ Intel = ("Intel for " + $id); Source = "MockedIntelSource" } } # Existing + added Source for report test
            UpdateThreatIntelligence = { param($iocs) Write-Host ("Mocked UpdateThreatIntelligence with " + $iocs.Count + " IOCs") } # Existing mock behavior
        }

        # Instantiate SUT ($sir)
        $sir = [SecurityIncidentResponder]::new($mockTenantId)

        # Directly inject mock dependencies into the SUT instance
        $sir.PlaybookManager = $mockPlaybookManager
        $sir.ForensicEngine = $mockThreatHunter
        $sir.AutomationEngine = $mockResponseOrchestrator
        $sir.ThreatIntelClient = $mockThreatIntelClient

        # Global Mock New-Object is removed
    }

    AfterEach {
        # Pester v5 automatically cleans up instance mocks defined with Mock -CommandName if they are in scope of BeforeEach/It
    }

    # 2. Update InitializeEngines Method Test
    Context "InitializeEngines Method (now tests direct injection)" {
        It "has engine properties set to the injected mocks" {
            $sir.ForensicEngine | Should -Be $mockThreatHunter
            $sir.AutomationEngine | Should -Be $mockResponseOrchestrator
            $sir.PlaybookManager | Should -Be $mockPlaybookManager
            $sir.ThreatIntelClient | Should -Be $mockThreatIntelClient
            # Should -Invoke Verifiable -CommandName New-Object -Times 4 # Removed: New-Object is no longer globally mocked for these
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
        # 3. Refactor InvokeBasicRestMethod Test
        It "executes InvokeBasicRestMethod" {
            # Mock Write-Host {} -Verifiable # Removed
            $action = @{ actionType = "InvokeBasicRestMethod"; parameters = @{ uri = "http://test.api/data"; method = "GET"; headers = @{Auth="Test"}; contentType="application/json" } }

            # Mock Invoke-RestMethod for this specific test
            Mock Invoke-RestMethod {
                param($uriParam, $methodParam)
                return @{ MockResponse = "Data from $methodParam $uriParam" }
            } -Verifiable # Assuming Invoke-RestMethod is globally available or Pester finds it.

            $result = $sir._ExecuteAction($action, $mockContext)

            $result.Status | Should -Be "Success"
            $result.ApiResponse.MockResponse | Should -Be "Data from GET http://test.api/data"
            Should -Invoke Verifiable -CommandName Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $uri -eq "http://test.api/data" -and
                $method -eq "GET" -and
                $headers.Auth -eq "Test" -and
                $contentType -eq "application/json"
            }
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
            Should -Invoke Verifiable -CommandName "GetRelatedThreatIntel" -Instance $mockThreatIntelClient -Times 1 # This test remains valid
        }
    }

    # 4. Add Tests for TriggerAutomatedResponse
    Context "TriggerAutomatedResponse Method" {
        It "calls correct methods for AccountCompromise" {
            Mock -CommandName "_IsolateCompromisedAccount" -MockWith { Write-Host "Mocked _IsolateCompromisedAccount"; return @{Called= $true} } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_InitiateForensicCollection" -MockWith { Write-Host "Mocked _InitiateForensicCollection"; return @{Called= $true} } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_NotifySecurityTeam" -MockWith { Write-Host "Mocked _NotifySecurityTeam"; return @{Called= $true} } -ParameterFilter { $Instance -eq $sir } -Verifiable

            $sir.TriggerAutomatedResponse("AccountCompromise", @{IncidentId="AC-001"; RawIncident=@{}})

            Should -Invoke "_IsolateCompromisedAccount" -Times 1 -Exactly -Scope It
            Should -Invoke "_InitiateForensicCollection" -Times 1 -Exactly -Scope It
            Should -Invoke "_NotifySecurityTeam" -Times 1 -Exactly -Scope It
        }

        It "calls correct methods for DataExfiltration" {
            Mock -CommandName "_BlockDataTransfer" -MockWith { Write-Host "Mocked _BlockDataTransfer"; return @{Called= $true} } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_RevokeSessions" -MockWith { Write-Host "Mocked _RevokeSessions"; return @{Called= $true} } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_InitiateDLP" -MockWith { Write-Host "Mocked _InitiateDLP"; return @{Called= $true} } -ParameterFilter { $Instance -eq $sir } -Verifiable

            $sir.TriggerAutomatedResponse("DataExfiltration", @{IncidentId="DE-001"; RawIncident=@{}})

            Should -Invoke "_BlockDataTransfer" -Times 1 -Exactly -Scope It
            Should -Invoke "_RevokeSessions" -Times 1 -Exactly -Scope It
            Should -Invoke "_InitiateDLP" -Times 1 -Exactly -Scope It
        }

        It "calls correct methods for MalwareDetection" {
            Mock -CommandName "_IsolateInfectedSystems" -MockWith { Write-Host "Mocked _IsolateInfectedSystems"; return @{Called= $true} } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_InitiateAntimalwareScan" -MockWith { Write-Host "Mocked _InitiateAntimalwareScan"; return @{Called= $true} } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_CollectMalwareSamples" -MockWith { Write-Host "Mocked _CollectMalwareSamples"; return @{Called= $true} } -ParameterFilter { $Instance -eq $sir } -Verifiable

            $sir.TriggerAutomatedResponse("MalwareDetection", @{IncidentId="MD-001"; RawIncident=@{}})

            Should -Invoke "_IsolateInfectedSystems" -Times 1 -Exactly -Scope It
            Should -Invoke "_InitiateAntimalwareScan" -Times 1 -Exactly -Scope It
            Should -Invoke "_CollectMalwareSamples" -Times 1 -Exactly -Scope It
        }

        It "calls _ExecuteDefaultResponse for default case" {
            Mock -CommandName "_ExecuteDefaultResponse" -MockWith { Write-Host "Mocked _ExecuteDefaultResponse"; return @{Called= $true} } -ParameterFilter { $Instance -eq $sir } -Verifiable

            $sir.TriggerAutomatedResponse("UnknownClassification", @{IncidentId="UC-001"; RawIncident=@{}})

            Should -Invoke "_ExecuteDefaultResponse" -Times 1 -Exactly -Scope It
        }
    }

    # 5. Add Tests for GenerateIncidentReport
    Context "GenerateIncidentReport Method" {
        It "calls all helper methods and assembles their data" {
            $testIncidentId = "REPORT-001"
            $mockTimeline = @( @{ Event = "TimelineEvent1"} )
            $mockImpact = @{ Severity = "TestHigh"; Scope_Mock="TestScope" }
            $mockContainment = "TestContained"
            $mockRemediation = "TestRemediated"
            $mockForensic = @{ FindingsSummary_Mock = "TestForensicSummary" }
            # $mockThreatIntel is already handled by the $mockThreatIntelClient in BeforeEach
            $mockLessons = @{ Observation_Mock = "TestLesson" }
            $mockMetrics = @{ TimeToDetection_Mock = "01:00:00" }

            # Setup ActiveIncidents entry for _GetForensicFindings and _GetRelatedThreatIntel (via engine)
            $sir.ActiveIncidents[$testIncidentId] = @{
                Classification="TestClassReport";
                Actions=@( @{ Name="ActionTaken1" } );
                ForensicFindings= $mockForensic; # Used by _GetForensicFindings if it checks ActiveIncidents directly
                IdentifiedIOCs=@("ioc_report_1")   # Used by _GetForensicFindings
            }

            Mock -CommandName "_CreateIncidentTimeline" -MockWith { return $mockTimeline } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_AssessIncidentImpact" -MockWith { return $mockImpact } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_GetContainmentStatus" -MockWith { return $mockContainment } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_GetRemediationStatus" -MockWith { return $mockRemediation } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_GetForensicFindings" -MockWith { return $mockForensic } -ParameterFilter { $Instance -eq $sir } -Verifiable
            # _GetRelatedThreatIntel is mocked via $mockThreatIntelClient.GetRelatedThreatIntel
            Mock -CommandName "_CompileLessonsLearned" -MockWith { return $mockLessons } -ParameterFilter { $Instance -eq $sir } -Verifiable
            Mock -CommandName "_CalculateResponseMetrics" -MockWith { return $mockMetrics } -ParameterFilter { $Instance -eq $sir } -Verifiable

            $report = $sir.GenerateIncidentReport($testIncidentId)

            $report | Should -Not -BeNull
            $report.IncidentId | Should -Be $testIncidentId
            $report.Classification | Should -Be "TestClassReport"
            $report.Timeline | Should -Be $mockTimeline
            $report.Actions | Should -BeOfType ([System.Collections.Generic.List[object]]) # From ActiveIncidents setup
            $report.Actions[0].Name | Should -Be "ActionTaken1"
            $report.Impact | Should -Be $mockImpact
            $report.Containment | Should -Be $mockContainment
            $report.Remediation | Should -Be $mockRemediation
            $report.ForensicFindings | Should -Be $mockForensic
            $report.ThreatIntelligence.Source | Should -Be "MockedIntelSource" # From $mockThreatIntelClient
            $report.LessonsLearned | Should -Be $mockLessons
            $report.Metrics | Should -Be $mockMetrics

            Should -Invoke "_CreateIncidentTimeline" -Times 1 -Exactly -Scope It
            Should -Invoke "_AssessIncidentImpact" -Times 1 -Exactly -Scope It
            Should -Invoke "_GetContainmentStatus" -Times 1 -Exactly -Scope It
            Should -Invoke "_GetRemediationStatus" -Times 1 -Exactly -Scope It
            Should -Invoke "_GetForensicFindings" -Times 1 -Exactly -Scope It
            Should -Invoke Verifiable -CommandName "GetRelatedThreatIntel" -Instance $mockThreatIntelClient -Times 1 # Verify call to engine
            Should -Invoke "_CompileLessonsLearned" -Times 1 -Exactly -Scope It
            Should -Invoke "_CalculateResponseMetrics" -Times 1 -Exactly -Scope It
        }
    }
    # 6. EngineCallDelegation Tests remain largely the same, confirming delegation to now directly injected mocks
}
