Import-Module Pester -ErrorAction Stop
. $PSScriptRoot/PlaybookManager.ps1 # Assuming tests are in the same dir as the script, or adjust path

Describe "PlaybookManager Tests" {
    $pm = $null
    $testDir = Join-Path $PSScriptRoot "temp_playbooks_test_dir"

    BeforeEach {
        $pm = [PlaybookManager]::new()
        if (Test-Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
        New-Item -Path $testDir -ItemType Directory | Out-Null
    }

    AfterEach {
        if (Test-Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }

    It "should instantiate correctly with an empty LoadedPlaybooks hashtable" {
        $pm.LoadedPlaybooks | Should -Not -BeNull
        $pm.LoadedPlaybooks | Should -BeOfType ([hashtable])
        $pm.LoadedPlaybooks.Count | Should -Be 0
    }

    Context "LoadPlaybooks Method" {
        It "should load valid JSON playbook files from a directory" {
            Set-Content -Path (Join-Path $testDir "valid_pb1.json") -Value '{ "name": "TestPB1", "description": "Valid PB", "steps": [] }'
            Set-Content -Path (Join-Path $testDir "valid_pb2.json") -Value '{ "name": "TestPB2", "description": "Another Valid PB", "defaultClassification": ["TestClass"], "steps": [{"id": "s1", "name": "step1", "actionType": "Log"}] }'

            $pm.LoadPlaybooks($testDir)

            $pm.LoadedPlaybooks.Count | Should -Be 2
            $pm.LoadedPlaybooks["TestPB1"] | Should -Not -BeNull
            $pm.LoadedPlaybooks["TestPB2"] | Should -Not -BeNull
            $pm.LoadedPlaybooks["TestPB1"].name | Should -Be "TestPB1"
        }

        It "should correctly parse properties of loaded playbooks" {
            Set-Content -Path (Join-Path $testDir "valid_pb2.json") -Value '{ "name": "TestPB2", "description": "Another Valid PB", "defaultClassification": ["TestClass"], "steps": [{"id": "s1", "name": "step1", "actionType": "Log"}] }'
            $pm.LoadPlaybooks($testDir)
            $pm.LoadedPlaybooks["TestPB2"].description | Should -Be "Another Valid PB"
            $pm.LoadedPlaybooks["TestPB2"].defaultClassification | Should -BeOfType ([array])
            $pm.LoadedPlaybooks["TestPB2"].defaultClassification[0] | Should -Be "TestClass"
            $pm.LoadedPlaybooks["TestPB2"].steps[0].actionType | Should -Be "Log"
        }

        It "should handle non-existent directory gracefully with a Write-Error" {
            Mock Write-Error {} -Verifiable
            $nonExistentDir = Join-Path $testDir "non_existent_subdir"
            $pm.LoadPlaybooks($nonExistentDir)
            $pm.LoadedPlaybooks.Count | Should -Be 0
            Should -Invoke Verifiable -CommandName Write-Error -Times 1 -Exactly
        }

        It "should handle directory with no JSON files" {
            $pm.LoadPlaybooks($testDir) # Empty directory
            $pm.LoadedPlaybooks.Count | Should -Be 0
        }

        It "should skip and warn for invalid JSON files" {
            Set-Content -Path (Join-Path $testDir "valid_pb1.json") -Value '{ "name": "TestPB1", "description": "Valid PB", "steps": [] }'
            Set-Content -Path (Join-Path $testDir "invalid_json.json") -Value '{ "name": "BrokenPB", "description": "Broken JSON,' # Missing closing brace

            Mock Write-Error {} -Verifiable
            $pm.LoadPlaybooks($testDir)

            $pm.LoadedPlaybooks.Count | Should -Be 1
            $pm.LoadedPlaybooks["TestPB1"] | Should -Not -BeNull
            Should -Invoke Verifiable -CommandName Write-Error -Times 1 -Exactly
        }

        It "should skip and warn for JSON files missing 'name' property" {
            Set-Content -Path (Join-Path $testDir "valid_pb1.json") -Value '{ "name": "TestPB1", "description": "Valid PB", "steps": [] }'
            Set-Content -Path (Join-Path $testDir "no_name_pb.json") -Value '{ "description": "No name here", "steps": [] }'

            Mock Write-Warning {} -Verifiable
            $pm.LoadPlaybooks($testDir)

            $pm.LoadedPlaybooks.Count | Should -Be 1
            $pm.LoadedPlaybooks["TestPB1"] | Should -Not -BeNull
            Should -Invoke Verifiable -CommandName Write-Warning -Times 1 -Exactly
        }

        It "should ignore non-JSON files" {
             Set-Content -Path (Join-Path $testDir "valid_pb1.json") -Value '{ "name": "TestPB1", "description": "Valid PB", "steps": [] }'
             Set-Content -Path (Join-Path $testDir "not_a_playbook.txt") -Value 'Hello world'
             $pm.LoadPlaybooks($testDir)
             $pm.LoadedPlaybooks.Count | Should -Be 1
             $pm.LoadedPlaybooks["TestPB1"] | Should -Not -BeNull
        }
    }

    Context "GetPlaybook Method" {
        BeforeEach { # Changed from BeforeAll for better isolation if more tests are added
            $pm.LoadedPlaybooks = @{ "MyPlaybook" = @{ name="MyPlaybook"; steps=@(); description="My Test Playbook" } }
        }

        It "should return a playbook if it exists" {
            $playbook = $pm.GetPlaybook("MyPlaybook")
            $playbook | Should -Not -BeNull
            $playbook.name | Should -Be "MyPlaybook"
            $playbook.description | Should -Be "My Test Playbook"
        }

        It "should return $null and warn if playbook does not exist" {
            Mock Write-Warning {} -Verifiable
            $playbook = $pm.GetPlaybook("NonExistentPlaybook")
            $playbook | Should -BeNull
            Should -Invoke Verifiable -CommandName Write-Warning -Times 1 -Exactly
        }
    }
}
