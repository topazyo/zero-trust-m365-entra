Import-Module Pester -ErrorAction Stop
Import-Module ../../src/playbook/PlaybookManager.ps1 -ErrorAction Stop

Describe "PlaybookManager Tests" {
    Context "LoadPlaybooks Method" {
        $mockPlaybookDir = "./temp_playbooks_test_pm"
        BeforeEach {
            # Ensure directory is clean and exists
            if (Test-Path $mockPlaybookDir) {
                Remove-Item -Path $mockPlaybookDir -Recurse -Force | Out-Null
            }
            New-Item -ItemType Directory -Path $mockPlaybookDir -Force | Out-Null
        }
        AfterEach {
            if (Test-Path $mockPlaybookDir) {
                Remove-Item -Path $mockPlaybookDir -Recurse -Force | Out-Null
            }
        }

        It "loads valid playbook JSON files" {
            Set-Content -Path ($mockPlaybookDir + "/pb1.json") -Value '{ "name": "Playbook1", "steps": [] }'
            Set-Content -Path ($mockPlaybookDir + "/pb2.json") -Value '{ "name": "Playbook2", "description": "Test Description" }'

            $pm = New-Object PlaybookManager
            $pm.LoadPlaybooks($mockPlaybookDir)

            $pm.LoadedPlaybooks.Count | Should -Be 2
            $pm.LoadedPlaybooks["Playbook1"] | Should -Not -BeNull
            $pm.LoadedPlaybooks["Playbook1"].name | Should -Be "Playbook1"
            $pm.LoadedPlaybooks["Playbook2"].description | Should -Be "Test Description"
        }

        It "handles missing directory" {
            Remove-Item -Path $mockPlaybookDir -Recurse -Force # Ensure it's gone
            $pm = New-Object PlaybookManager
            # LoadPlaybooks should write an error but not throw terminating exception
            $pm.LoadPlaybooks($mockPlaybookDir)
            $pm.LoadedPlaybooks.Count | Should -Be 0
        }

        It "handles invalid JSON" {
            Set-Content -Path ($mockPlaybookDir + "/invalid.json") -Value '{ name: "InvalidJSON", desc: "Test }' # Malformed
            $pm = New-Object PlaybookManager
            $pm.LoadPlaybooks($mockPlaybookDir)
            $pm.LoadedPlaybooks.Count | Should -Be 0 # Should not load the invalid one
        }

        It "skips JSON missing name property" {
            Set-Content -Path ($mockPlaybookDir + "/noname.json") -Value '{ "description": "No name property" }'
            $pm = New-Object PlaybookManager
            $pm.LoadPlaybooks($mockPlaybookDir)
            $pm.LoadedPlaybooks.Count | Should -Be 0
        }

        It "loads multiple playbooks correctly" {
            Set-Content -Path ($mockPlaybookDir + "/pb1.json") -Value '{ "name": "FirstPlaybook", "steps": [] }'
            Set-Content -Path ($mockPlaybookDir + "/pb2.json") -Value '{ "name": "SecondPlaybook", "steps": [] }'
            Set-Content -Path ($mockPlaybookDir + "/pb3.json") -Value '{ "name": "ThirdPlaybook", "steps": [] }'
            $pm = New-Object PlaybookManager
            $pm.LoadPlaybooks($mockPlaybookDir)
            $pm.LoadedPlaybooks.Count | Should -Be 3
            $pm.LoadedPlaybooks["ThirdPlaybook"] | Should -Not -BeNull
        }
    }

    Context "GetPlaybook Method" {
        $pm = New-Object PlaybookManager
        # Pre-populate LoadedPlaybooks for these tests
        $pm.LoadedPlaybooks = @{
            "MyTestPlaybook" = @{ "name" = "MyTestPlaybook"; "data" = "test_data_content" };
            "AnotherPlaybook" = @{ "name" = "AnotherPlaybook"; "data" = "more_data" }
        }

        It "returns loaded playbook by name" {
            $playbook = $pm.GetPlaybook("MyTestPlaybook")
            $playbook | Should -Not -BeNull
            $playbook.data | Should -Be "test_data_content"
        }

        It "returns null if name not found" {
            $playbook = $pm.GetPlaybook("NonExistentPlaybookName")
            $playbook | Should -BeNull
        }
    }
}