Import-Module Pester -ErrorAction Stop
Import-Module ../../src/intelligence/threat_intelligence_manager.ps1 -ErrorAction Stop

Describe "ThreatIntelligenceManager Tests" {
    $mockTenantId = "test-tim-tenant"
    $tim = $null

    BeforeEach {
        $tim = New-Object ThreatIntelligenceManager -ArgumentList $mockTenantId
        # Mock any internal methods if they were complex and called by these public ones
        # For now, GetRelatedThreatIntel and UpdateThreatIntelligence are self-contained mocks
    }

    Context "GetRelatedThreatIntel Method" {
        It "returns specific mock data for INC-001" {
            $intel = $tim.GetRelatedThreatIntel("INC-001")
            $intel | Should -Not -BeNull
            $intel.ThreatType | Should -Be "Malware"
            $intel.Severity | Should -Be "High"
            $intel.IOCs | Should -Contain "filehash123"
        }

        It "returns specific mock data for INC-002" {
            $intel = $tim.GetRelatedThreatIntel("INC-002")
            $intel | Should -Not -BeNull
            $intel.ThreatType | Should -Be "Phishing"
            $intel.IOCs | Should -Contain "phish@example.com"
        }

        It "returns default mock data for other incident IDs" {
            $intel = $tim.GetRelatedThreatIntel("INC-UNKNOWN")
            $intel | Should -Not -BeNull
            $intel.ThreatType | Should -Be "Unknown"
            $intel.IOCs.Count | Should -Be 0
        }
    }

    Context "UpdateThreatIntelligence Method" {
        It "logs received IOCs" {
            $iocsToUpdate = @("evil.com", "1.2.3.4", @{Type="Filehash"; Value="abc"})

            # Mock Write-Host to verify its calls
            Mock Write-Host {} -ModuleName (Get-Module ../../src/intelligence/threat_intelligence_manager.ps1).Name -Verifiable

            $tim.UpdateThreatIntelligence($iocsToUpdate)

            Should -Invoke Verifiable -CommandName Write-Host -Times 1 -ParametersList @("ThreatIntelligenceManager.UpdateThreatIntelligence called with 3 IOCs. (Implemented Mock)")
            Should -Invoke Verifiable -CommandName Write-Host -Times 1 -ParametersList @("Mock Processing IOCs:")
            Should -Invoke Verifiable -CommandName Write-Host -Times 1 -ParametersList @("- IOC: evil.com (type: String)")
            Should -Invoke Verifiable -CommandName Write-Host -Times 1 -ParametersList @("- IOC: 1.2.3.4 (type: String)")
            Should -Invoke Verifiable -CommandName Write-Host -Times 1 -ParametersList @("- IOC: @{Type=Filehash; Value=abc} (type: Hashtable)")
        }

        It "handles null or empty IOC array" {
            Mock Write-Host {} -ModuleName (Get-Module ../../src/intelligence/threat_intelligence_manager.ps1).Name -Verifiable

            $tim.UpdateThreatIntelligence($null)
            Should -Invoke Verifiable -CommandName Write-Host -Times 1 -ParametersList @("ThreatIntelligenceManager.UpdateThreatIntelligence called with 0 IOCs. (Implemented Mock)")
            Should -Invoke Verifiable -CommandName Write-Host -Times 1 -ParametersList @("No IOCs provided to update.")

            $tim.UpdateThreatIntelligence(@())
            # Expecting specific call counts for these messages based on the two calls above ($null, then empty array)
            Should -Invoke Verifiable -CommandName Write-Host -ParametersList @("ThreatIntelligenceManager.UpdateThreatIntelligence called with 0 IOCs. (Implemented Mock)") -Times 2
            Should -Invoke Verifiable -CommandName Write-Host -ParametersList @("No IOCs provided to update.") -Times 2
        }
    }
}
