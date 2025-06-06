Import-Module Pester -ErrorAction Stop
Import-Module ../../src/playbook/PlaybookManager.ps1 -ErrorAction Stop
Import-Module ../../src/hunting/threat_hunter.ps1 -ErrorAction Stop
Import-Module ../../src/response/response_orchestrator.ps1 -ErrorAction Stop
Import-Module ../../src/intelligence/threat_intelligence_manager.ps1 -ErrorAction Stop
Import-Module ../../src/automation/Security_Incident_Responder.ps1 -ErrorAction Stop
Describe "SecurityIncidentResponder Tests" {
    $mockTenantId = "test-tenant-id"
    $sir = $null
    $mockPlaybookManager = $null
    $mockThreatHunter = $null
    $mockResponseOrchestrator = $null
    $mockThreatIntelClient = $null
    $resolvedNewObjectCmd = $null
    BeforeEach {
        # Placeholder will be replaced by the subtask script
        $resolvedNewObjectCmd = Get-Command "Microsoft.PowerShell.Utility\New-Object"
        $mockPlaybookManager = Mock -ModuleName (Get-Module ../../src/playbook/PlaybookManager.ps1).Name PlaybookManager { New-Object PlaybookManager } {
            LoadPlaybooks = { param($path) $this.LoadedPlaybooks = @{ "MockedPlaybook" = @{ name="MockedPlaybook"; steps=@() }} }
            GetPlaybook = { param($name) if ($this.LoadedPlaybooks.ContainsKey($name)) { return $this.LoadedPlaybooks[$name] } else { return $null } }
        } -AsInstance
        $mockThreatHunter = Mock -ModuleName (Get-Module ../../src/hunting/threat_hunter.ps1).Name ThreatHunter { New-Object ThreatHunter -ArgumentList $mockTenantId } {
            CollectForensicData = { param($incidentId) return @{ ForensicData = ("Collected for " + $incidentId) } }
        } -AsInstance
        $mockResponseOrchestrator = Mock -ModuleName (Get-Module ../../src/response/response_orchestrator.ps1).Name ResponseOrchestrator { New-Object ResponseOrchestrator -ArgumentList $mockTenantId } {} -AsInstance
        $mockThreatIntelClient = Mock -ModuleName (Get-Module ../../src/intelligence/threat_intelligence_manager.ps1).Name ThreatIntelligenceManager { New-Object ThreatIntelligenceManager -ArgumentList $mockTenantId } {
            GetRelatedThreatIntel = { param($id) return @{ Intel = ("Intel for " + $id) } }
            UpdateThreatIntelligence = { param($iocs) Write-Host ("Mocked UpdateThreatIntelligence with " + $iocs.Count + " IOCs") }
        } -AsInstance
        Mock New-Object {
            param([string]$TypeName, [object[]]$ArgumentList)
            if ($TypeName -eq ([PlaybookManager].FullName)) { return $mockPlaybookManager }
            if ($TypeName -eq ([ThreatHunter].FullName)) { return $mockThreatHunter }
            if ($TypeName -eq ([ResponseOrchestrator].FullName)) { return $mockResponseOrchestrator }
            if ($TypeName -eq ([ThreatIntelligenceManager].FullName)) { return $mockThreatIntelClient }
            & $resolvedNewObjectCmd -TypeName $TypeName -ArgumentList $ArgumentList
        } -ModuleName (Get-Module ../../src/automation/Security_Incident_Responder.ps1).Name -Verifiable
        $sir = New-Object SecurityIncidentResponder -ArgumentList $mockTenantId
    }
    AfterEach {
        Remove-ModuleMock -ModuleName (Get-Module ../../src/automation/Security_Incident_Responder.ps1).Name -CommandName New-Object
    }
    Context "InitializeEngines Method" {
        It "populates engine properties" {
            $sir.ForensicEngine | Should -Be $mockThreatHunter
            $sir.AutomationEngine | Should -Be $mockResponseOrchestrator
            $sir.PlaybookManager | Should -Be $mockPlaybookManager
            $sir.ThreatIntelClient | Should -Be $mockThreatIntelClient
            Should -Invoke Verifiable -CommandName New-Object -ModuleName (Get-Module ../../src/automation/Security_Incident_Responder.ps1).Name -Times 4
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
            Mock Write-Host {} -ModuleName (Get-Module ../../src/automation/Security_Incident_Responder.ps1).Name -Verifiable
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
            Mock Write-Host {} -ModuleName (Get-Module ../../src/automation/Security_Incident_Responder.ps1).Name -Verifiable
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
            Mock Write-Host { throw "IntentionalErrorInAction" } -ModuleName (Get-Module ../../src/automation/Security_Incident_Responder.ps1).Name
            $action = @{ actionType = "LogMessage"; parameters = @{ message = "Error test message" } }
            $result = $sir._ExecuteAction($action, $mockContext)
            $result.Status | Should -Be "Error"
            $result.Output | Should -Contain "IntentionalErrorInAction"
        }
    }
    Context "EngineCallDelegation Tests" {
         It "calls ForensicEngine CollectForensicData" {
            Mock ($mockThreatHunter) CollectForensicData -ModuleName (Get-Module ../../src/hunting/threat_hunter.ps1).Name { param($incidentId) return @{ ForensicData = ("Collected for " + $incidentId) } } -Verifiable
            $sir._CollectForensicData("INC-001")
            Should -Invoke Verifiable -CommandName CollectForensicData -ModuleName (Get-Module ../../src/hunting/threat_hunter.ps1).Name -Times 1
        }
        It "calls ThreatIntelClient UpdateThreatIntelligence" {
            Mock ($mockThreatIntelClient) UpdateThreatIntelligence -ModuleName (Get-Module ../../src/intelligence/threat_intelligence_manager.ps1).Name { param($iocs) Write-Host "Test Mocked Update" } -Verifiable
            $sir._UpdateThreatIntelligence(@("ioc1"))
            Should -Invoke Verifiable -CommandName UpdateThreatIntelligence -ModuleName (Get-Module ../../src/intelligence/threat_intelligence_manager.ps1).Name -Times 1
        }
        It "calls ThreatIntelClient GetRelatedThreatIntel" {
            Mock ($mockThreatIntelClient) GetRelatedThreatIntel -ModuleName (Get-Module ../../src/intelligence/threat_intelligence_manager.ps1).Name { param($id) return @{ Intel = ("Intel for " + $id) } } -Verifiable
            $sir._GetRelatedThreatIntel("INC-001")
            Should -Invoke Verifiable -CommandName GetRelatedThreatIntel -ModuleName (Get-Module ../../src/intelligence/threat_intelligence_manager.ps1).Name -Times 1
        }
    }
}
