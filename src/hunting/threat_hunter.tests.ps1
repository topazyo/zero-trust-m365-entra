Import-Module Pester -ErrorAction Stop
Import-Module ../../src/hunting/threat_hunter.ps1 -ErrorAction Stop

Describe "ThreatHunter Tests" {
    $mockTenantId = "test-th-tenant"
    $th = $null

    BeforeEach {
        $th = New-Object ThreatHunter -ArgumentList $mockTenantId
    }

    Context "CollectForensicData Method" {
        It "returns a structured hashtable with forensic artifacts" {
            $identifier = "machine-01"
            $artifacts = $th.CollectForensicData($identifier)

            $artifacts | Should -Not -BeNull
            $artifacts | Should -BeOfType ([hashtable])
            $artifacts.PSObject.Properties.Name | Should -Contain @("CollectedFrom", "CollectionTimeUTC", "Processes", "NetworkConnections", "Files", "LogSources")
            $artifacts.CollectedFrom | Should -Be $identifier
            $artifacts.Processes | Should -BeOfType ([array])
            $artifacts.Processes.Count | Should -BeGreaterThanOrEqual 2
        }

        It "includes additional artifacts for critical identifiers" {
            $identifier = "server-critical-007"
            $artifacts = $th.CollectForensicData($identifier)

            $artifacts | Should -Not -BeNull
            $artifacts.CustomAlert | Should -Not -BeNullOrEmpty
            $artifacts.Processes.Name | Should -Contain "ransom.exe"
        }

        It "returns data with forward slashes in paths" {
            $identifier = "test-machine"
            $artifacts = $th.CollectForensicData($identifier)
            $artifacts.Files[0].Path | Should -Be "c:/temp/evil.exe" # Check for forward slash
            $artifacts.Files[1].Path | Should -Be "c:/users/victim/docs/secret.docx"
        }
    }
}
