Import-Module Pester -ErrorAction Stop
. $PSScriptRoot/ResponseOrchestrator.ps1 # Assumes test file is in the same dir as the script

Describe "ResponseOrchestrator Tests" {
    $mockTenantId = "test-ro-tenant"
    $ro = $null

    BeforeEach {
        # Instantiate the class. Its constructor calls _InitializeOrchestrationEngine and _LoadResponsePlaybooks.
        $ro = [ResponseOrchestrator]::new($mockTenantId)
    }

    It "should instantiate correctly and load initial mock data" {
        $ro | Should -Not -BeNull
        $ro.TenantId | Should -Be $mockTenantId
        $ro.OrchestrationEngine | Should -Not -BeNull
        $ro.OrchestrationEngine.Status | Should -Be "Initialized_Mock"
        $ro.ResponsePlaybooks | Should -Not -BeNull
        $ro.ResponsePlaybooks.Count | Should -BeGreaterThan 0
        $ro.ResponsePlaybooks["ContainUserAccount_Mock"] | Should -Not -BeNull
    }

    Context "ExecuteAutomatedResponse Method" {
        It "should call assessment, playbook selection, and action execution stubs" {
            # Mock the private methods of the specific $ro instance
            Mock -CommandName "_AssessSituation" -MockWith { Write-Host "Mocked _AssessSituation"; return @{ AssessedSeverity = "High_Mock"; TriggerType = $trigger.Type; TargetEntities = $trigger.Entities; Confidence = "Medium_MockAssessment"; Timestamp = (Get-Date -Format 'u') } } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_SelectResponsePlaybook" -MockWith { Write-Host "Mocked _SelectResponsePlaybook"; return @{ Name = "SelectedMockPlaybook"; Actions = @(@{ActionName="MockAction1"},@{ActionName="MockAction2"}) } } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_ExecuteResponseAction" -MockWith { Write-Host "Mocked _ExecuteResponseAction"; return @{ ActionName = $action.ActionName; Status = "Success_Mock"; Output = "Mock action executed."; Timestamp = (Get-Date -Format 'u') } } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_ValidateActionExecution" -MockWith { Write-Host "Mocked _ValidateActionExecution" } -ParameterFilter { $Instance -eq $ro } # Void or simple mock
            Mock -CommandName "_MonitorResponseEffectiveness" -MockWith { Write-Host "Mocked _MonitorResponseEffectiveness" } -ParameterFilter { $Instance -eq $ro } # Void or simple mock

            $testTrigger = @{Type="TestTriggerType"; Entities=@("EntityX")}
            $ro.ExecuteAutomatedResponse($testTrigger)

            Should -Invoke "_AssessSituation" -Times 1 -Exactly -Scope It # Check if called on $ro
            Should -Invoke "_SelectResponsePlaybook" -Times 1 -Exactly -Scope It
            Should -Invoke "_ExecuteResponseAction" -Times 2 -Exactly -Scope It # Assuming SelectedMockPlaybook has 2 actions
            Should -Invoke "_ValidateActionExecution" -Times 2 -Exactly -Scope It
            Should -Invoke "_MonitorResponseEffectiveness" -Times 1 -Exactly -Scope It
        }
    }

    Context "GenerateResponseReport Method" {
        It "should call helper methods and return a structured report" {
            $testResponseId = "RESP-TEST-001"
            # Mock private methods to return expected structures
            Mock -CommandName "_CreateResponseTimeline" -MockWith { return @( @{ Timestamp=(Get-Date).AddMinutes(-5).ToString('u'); Event="TriggerReceived_Test"; ResponseID=$responseId } ) } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_GetResponseActions" -MockWith { return @( @{ ActionName="TestAction1"; Status="Success_Test" } ) } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_AssessResponseEffectiveness" -MockWith { return @{ OverallEffectiveness = "Effective_Test"; Score = 95 } } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_CompileResponseLessons" -MockWith { return @{ Lesson = "Test lesson learned." } } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_GenerateResponseRecommendations" -MockWith { return @( "Test recommendation." ) } -ParameterFilter { $Instance -eq $ro }

            $report = $ro.GenerateResponseReport($testResponseId)

            $report | Should -Not -BeNull
            $report.ResponseId | Should -Be $testResponseId
            $report.Timeline | Should -BeOfType ([array])
            $report.Timeline.Count | Should -BeGreaterOrEqualTo 1
            $report.Actions[0].ActionName | Should -Be "TestAction1"
            $report.Effectiveness.OverallEffectiveness | Should -Be "Effective_Test"
            $report.LessonsLearned.Lesson | Should -Be "Test lesson learned."
            $report.Recommendations[0] | Should -Be "Test recommendation."

            Should -Invoke "_CreateResponseTimeline" -Times 1 -Exactly -Scope It
            Should -Invoke "_GetResponseActions" -Times 1 -Exactly -Scope It
            Should -Invoke "_AssessResponseEffectiveness" -Times 1 -Exactly -Scope It
            Should -Invoke "_CompileResponseLessons" -Times 1 -Exactly -Scope It
            Should -Invoke "_GenerateResponseRecommendations" -Times 1 -Exactly -Scope It
        }
    }

    Context "HandleResponseFailure Method" {
        It "should call logging, fallback, notification, and update stubs" {
            $testFailureContext = @{ErrorSource_Mock="TestActionFailure_Test"; Message="Failed to execute action during test"}

            Mock -CommandName "_LogResponseFailure" -MockWith { Write-Host "Mocked _LogResponseFailure" } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_GetFallbackPlan" -MockWith { Write-Host "Mocked _GetFallbackPlan"; return @{ PlanName = "TestFallbackPlan"; Steps=@("Step1")} } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_ExecuteFallbackPlan" -MockWith { Write-Host "Mocked _ExecuteFallbackPlan" } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_NotifyFailure" -MockWith { Write-Host "Mocked _NotifyFailure" } -ParameterFilter { $Instance -eq $ro }
            Mock -CommandName "_UpdateResponsePlaybooksFromFeedback" -MockWith { Write-Host "Mocked _UpdateResponsePlaybooksFromFeedback" } -ParameterFilter { $Instance -eq $ro }

            $ro.HandleResponseFailure($testFailureContext)

            Should -Invoke "_LogResponseFailure" -Times 1 -Exactly -Scope It
            Should -Invoke "_GetFallbackPlan" -Times 1 -Exactly -Scope It
            Should -Invoke "_ExecuteFallbackPlan" -Times 1 -Exactly -Scope It
            Should -Invoke "_NotifyFailure" -Times 1 -Exactly -Scope It
            Should -Invoke "_UpdateResponsePlaybooksFromFeedback" -Times 1 -Exactly -Scope It
        }
    }

    It "_AssessSituation should return a mock assessment structure" {
        $assessment = $ro._AssessSituation(@{Type="TriggerType_ForDirectTest"; Entities=@("E1","E2")})
        $assessment | Should -Not -BeNull
        $assessment.AssessedSeverity | Should -Be "High_Mock"
        $assessment.TriggerType | Should -Be "TriggerType_ForDirectTest"
        $assessment.TargetEntities -contains "E1" | Should -Be $true
    }
}
