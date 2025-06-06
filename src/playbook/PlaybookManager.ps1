class PlaybookManager {
    [hashtable]$LoadedPlaybooks

    PlaybookManager() {
        $this.LoadedPlaybooks = @{}
        Write-Host "PlaybookManager instantiated."
    }

    [void] LoadPlaybooks([string]$directoryPath) {
        Write-Host "PlaybookManager.LoadPlaybooks (JSON File Loader) called for directory: $directoryPath"
        $this.LoadedPlaybooks = @{} # Clear any existing
        if (-not (Test-Path $directoryPath -PathType Container)) {
            Write-Error "Playbook directory '$directoryPath' not found."
            return
        }
        Get-ChildItem -Path $directoryPath -Filter "*.json" | ForEach-Object {
            Write-Host "Loading playbook from file: $($_.FullName)"
            try {
                $playbookContent = Get-Content -Path $_.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
                if ($null -ne $playbookContent.name) {
                    $this.LoadedPlaybooks[$playbookContent.name] = $playbookContent
                    Write-Host "Successfully loaded playbook: $($playbookContent.name)"
                } else {
                    Write-Warning "Playbook file $($_.Name) does not have a 'name' property."
                }
            } catch {
                Write-Error "Failed to load or parse playbook file $($_.Name): $($_.Exception.Message)"
            }
        }
        Write-Host "PlaybookManager finished loading. Total playbooks: $($this.LoadedPlaybooks.Count)"
    }

    [object] GetPlaybook([string]$playbookName) {
        Write-Host "PlaybookManager.GetPlaybook called for: $playbookName"
        if ($this.LoadedPlaybooks.ContainsKey($playbookName)) {
            return $this.LoadedPlaybooks[$playbookName]
        }
        Write-Warning "Playbook '$playbookName' not found by PlaybookManager."
        return $null # Or return a default playbook if that's desired
    }
}
