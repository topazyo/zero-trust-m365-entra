Import-Module Pester -ErrorAction Stop
. $PSScriptRoot/ThreatIntelligenceManager.ps1 # Assumes test file is in the same dir

Describe "ThreatIntelligenceManager Tests" {
    $mockTenantId = "test-tim-tenant"
    $tim = $null

    BeforeEach {
        # Instantiate the class. Constructor calls _InitializeIntelligenceEngine and _LoadThreatFeeds.
        $tim = [ThreatIntelligenceManager]::new($mockTenantId)
    }

    It "should instantiate correctly and load initial mock data" {
        $tim | Should -Not -BeNull
        $tim.TenantId | Should -Be $mockTenantId
        $tim.IntelligenceEngine | Should -Not -BeNull
        $tim.IntelligenceEngine.Status | Should -Be "Initialized_Mock"
        $tim.ThreatFeeds | Should -Not -BeNull
        $tim.ThreatFeeds.Count | Should -BeGreaterThan 0
        $tim.ThreatFeeds["OSINT_Feed_Example"] | Should -Not -BeNull
    }

    Context "ProcessThreatIntelligence Method" {
        It "should call all relevant private methods in sequence" {
            Mock -CommandName "_CollectIntelligence" -MockWith { Write-Host "Mocked _CollectIntelligence"; return @(@{}) } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_EnrichIntelligence" -MockWith { Write-Host "Mocked _EnrichIntelligence"; return @(@{}) } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_CorrelateThreats" -MockWith { Write-Host "Mocked _CorrelateThreats"; return @(@{}) } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_UpdateThreatDatabase" -MockWith { Write-Host "Mocked _UpdateThreatDatabase" } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_GenerateIntelligenceAlerts" -MockWith { Write-Host "Mocked _GenerateIntelligenceAlerts"; return @() } -ParameterFilter { $Instance -eq $tim }

            $tim.ProcessThreatIntelligence()

            Should -Invoke "_CollectIntelligence" -Times 1 -Exactly -Scope It
            Should -Invoke "_EnrichIntelligence" -Times 1 -Exactly -Scope It
            Should -Invoke "_CorrelateThreats" -Times 1 -Exactly -Scope It
            Should -Invoke "_UpdateThreatDatabase" -Times 1 -Exactly -Scope It # Called with correlatedThreats
            Should -Invoke "_GenerateIntelligenceAlerts" -Times 1 -Exactly -Scope It
        }
    }

    Context "AnalyzeThreatIndicators Method" {
        It "should call matching, risk assessment, and recommendation methods" {
            $testIndicators = @("good_indicator_test", "malicious_indicator_test")

            # Mock _MatchThreatIndicator to return different confidence levels
            $matchCallCount = 0
            Mock -CommandName "_MatchThreatIndicator" -MockWith {
                param($indicator)
                $matchCallCount++
                Write-Host "Mocked _MatchThreatIndicator for $indicator"
                if ($indicator -like "*malicious*") { return @{ Matched = $true; Confidence = 90; ThreatName_Mock = "TestMalware"; Indicator = $indicator } }
                else { return @{ Matched = $false; Confidence = 40; Indicator = $indicator } }
            } -ParameterFilter { $Instance -eq $tim }

            Mock -CommandName "_TriggerThreatResponse" -MockWith { Write-Host "Mocked _TriggerThreatResponse" } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_AssessThreatRisk" -MockWith { Write-Host "Mocked _AssessThreatRisk"; return @{ OverallRisk_Mock = "Medium"; TopThreat_Mock = "TestMalware" } } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_GenerateActionRecommendations" -MockWith { Write-Host "Mocked _GenerateActionRecommendations"; return @("Rec1") } -ParameterFilter { $Instance -eq $tim }

            $analysisResult = $tim.AnalyzeThreatIndicators($testIndicators)

            $analysisResult | Should -Not -BeNull
            $analysisResult.MatchedThreats.Count | Should -Be 1 # Only the malicious one
            $analysisResult.RiskAssessment.OverallRisk_Mock | Should -Be "Medium"
            $analysisResult.RecommendedActions[0] | Should -Be "Rec1"

            $matchCallCount | Should -Be $testIndicators.Count # Ensure it's called for each indicator
            Should -Invoke "_TriggerThreatResponse" -Times 1 -Exactly -Scope It # Called for the high confidence match
            Should -Invoke "_AssessThreatRisk" -Times 1 -Exactly -Scope It
            Should -Invoke "_GenerateActionRecommendations" -Times 1 -Exactly -Scope It
        }
    }

    Context "HandleIntelligenceAlert Method" {
        It "calls Critical response methods for Critical severity" {
            Mock -CommandName "_InitiateEmergencyResponse" -MockWith { } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_BlockThreatenedAssets" -MockWith { } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_NotifySecurityTeam" -MockWith { } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_UpdateDefenses" -MockWith { } -ParameterFilter { $Instance -eq $tim }

            $criticalAlert = @{ AlertID_Mock = "TIM-CRIT-002"; ThreatDetails_Mock = @{ Severity_Mock = "Critical" } }
            $tim.HandleIntelligenceAlert($criticalAlert)

            Should -Invoke "_InitiateEmergencyResponse" -Times 1 -Exactly -Scope It
            Should -Invoke "_BlockThreatenedAssets" -Times 1 -Exactly -Scope It
            Should -Invoke "_NotifySecurityTeam" -Times 1 -Exactly -Scope It
            Should -Invoke "_UpdateDefenses" -Times 1 -Exactly -Scope It
        }

        It "calls High response methods for High severity" {
            Mock -CommandName "_EnhanceMonitoring" -MockWith { } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_UpdateSecurityControls" -MockWith { } -ParameterFilter { $Instance -eq $tim }
            Mock -CommandName "_CreateIncidentTicket" -MockWith { } -ParameterFilter { $Instance -eq $tim }

            $highAlert = @{ AlertID_Mock = "TIM-HIGH-001"; ThreatDetails_Mock = @{ Severity_Mock = "High" } }
            $tim.HandleIntelligenceAlert($highAlert)

            Should -Invoke "_EnhanceMonitoring" -Times 1 -Exactly -Scope It
            Should -Invoke "_UpdateSecurityControls" -Times 1 -Exactly -Scope It
            Should -Invoke "_CreateIncidentTicket" -Times 1 -Exactly -Scope It
        }

        It "calls Default response methods for Low severity" {
            Mock -CommandName "_LogIntelligenceAlert" -MockWith { } -ParameterFilter { $Instance -eq $tim }
            # _UpdateThreatDatabase is called by ProcessThreatIntelligence, also by default handler here
            Mock -CommandName "_UpdateThreatDatabase" -MockWith { } -ParameterFilter { $Instance -eq $tim }


            $lowAlert = @{ AlertID_Mock = "TIM-LOW-001"; ThreatDetails_Mock = @{ Severity_Mock = "Low" } }
            $tim.HandleIntelligenceAlert($lowAlert)

            Should -Invoke "_LogIntelligenceAlert" -Times 1 -Exactly -Scope It
            Should -Invoke "_UpdateThreatDatabase" -Times 1 -Exactly -Scope It
        }
    }

    It "_CollectIntelligence should return mock intel items as per de-stub" {
        $intelItems = $tim._CollectIntelligence()
        $intelItems | Should -BeOfType ([array])
        $intelItems.Count | Should -BeGreaterOrEqualTo 1
        $intelItems[0].SourceFeed | Should -Be "OSINT_Feed_Example"
    }
}
