[CmdletBinding()]
param (
    [string]$BaselinePath = ".\config\security_baselines.json",
    [switch]$ForceUpdate
)

function Update-SecurityBaselines {
    [CmdletBinding()]
    param()

    try {
        $currentBaselinesFromFile = $null
        if (Test-Path -Path $BaselinePath -PathType Leaf) {
            try {
                $currentBaselinesFromFile = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json -ErrorAction Stop
            } catch {
                Write-Warning "Could not parse existing baseline file at '$BaselinePath'. Error: $($_.Exception.Message). Treating as empty."
                $currentBaselinesFromFile = @{}
            }
        } else {
            Write-Warning "Baseline file '$BaselinePath' not found. Will create a new one if updates are applied."
            $currentBaselinesFromFile = @{}
        }

        $latestBaselines = Get-LatestSecurityBaselines
        if ($null -eq $latestBaselines) {
            Write-Warning "No latest baselines available (template might be missing or empty). Skipping update process."
            return @{ UpdatesApplied = 0; Timestamp = [datetime]::UtcNow; Status = "NoActionTaken"; Message = "Latest baselines could not be retrieved or were empty."}
        }

        $updatesToApply = Compare-SecurityBaselines -current $currentBaselinesFromFile -latest $latestBaselines

        if ($updatesToApply.Count -gt 0 -or $ForceUpdate) {
            if ($updatesToApply.Count -eq 0 -and $ForceUpdate) {
                Write-Host "ForceUpdate specified: All settings from the 'latest baselines' source will be applied/re-applied."
                # For ForceUpdate with no differences, we'll treat all latest settings as the ones to apply.
                # This ensures the file is written with the content of latestBaselines.
                $updatesToApply = [System.Collections.Generic.List[object]]::new()
                foreach ($key in $latestBaselines.PSObject.Properties.Name) {
                    $updatesToApply.Add(@{ Setting = $key; NewValue = $latestBaselines.$key; OldValue = if($currentBaselinesFromFile.PSObject.Properties.Name -contains $key) { $currentBaselinesFromFile.$key } else { "NotSet" } })
                }
                if ($updatesToApply.Count -eq 0) { # If latestBaselines was also empty
                     Write-Host "ForceUpdate specified, but latest baselines source is also empty. No action to take."
                     return @{ UpdatesApplied = 0; Timestamp = [datetime]::UtcNow; Status = "NoActionTaken"; Message = "ForceUpdate, but latest baselines source was empty." }
                }
            }

            Backup-SecurityBaselines -path $BaselinePath

            $updatedBaselines = $currentBaselinesFromFile.PSObject.Copy()

            foreach ($update in $updatesToApply) {
                Apply-BaselineUpdate -update $update # Logs the intent
                $updatedBaselines[$update.Setting] = $update.NewValue # Actual update
            }

            try {
                $updatedBaselines | ConvertTo-Json -Depth 5 | Set-Content -Path $BaselinePath -ErrorAction Stop
                Write-Host "Successfully updated and saved baselines to '$BaselinePath'."
            } catch {
                Write-Error "Failed to save updated baselines to '$BaselinePath'. Error: $($_.Exception.Message)"
                throw # Re-throw to be caught by outer catch
            }

            Test-BaselineConfiguration

            Document-BaselineUpdates -updates $updatesToApply
        } else {
            Write-Host "No baseline updates required."
             return @{ UpdatesApplied = 0; Timestamp = [datetime]::UtcNow; Status = "NoActionTaken"; Message = "No updates identified." }
        }

        return @{
            UpdatesApplied = $updatesToApply.Count
            Timestamp = [datetime]::UtcNow
            Status = "Success"
        }
    }
    catch {
        Write-Error "Failed to update security baselines: $($_.Exception.Message)"
        return @{ UpdatesApplied = 0; Timestamp = [datetime]::UtcNow; Status = "Failed"; ErrorMessage = $_.Exception.Message }
    }
}

function Get-LatestSecurityBaselines() {
    Write-Host "Get-LatestSecurityBaselines: Attempting to load latest baselines from template."
    $latestBaselineTemplatePath = "./config/latest_security_baselines_template.json" # Mock source
    if (Test-Path -Path $latestBaselineTemplatePath -PathType Leaf) {
        try {
            return Get-Content -Path $latestBaselineTemplatePath -Raw | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-Warning "Get-LatestSecurityBaselines: Failed to load or parse '$latestBaselineTemplatePath'. Error: $($_.Exception.Message)"
            return $null
        }
    } else {
        Write-Warning "Get-LatestSecurityBaselines: Latest baseline template file '$latestBaselineTemplatePath' not found. Consider creating it with default baseline settings."
        # To make this function minimally useful even if the file doesn't exist,
        # return a default baseline structure or $null. For now, $null.
        return $null
    }
}

function Compare-SecurityBaselines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$current,
        [Parameter(Mandatory=$true)][hashtable]$latest
    )
    Write-Host "Compare-SecurityBaselines: Comparing current baselines with latest."
    $updates = [System.Collections.Generic.List[object]]::new()

    if ($null -eq $latest) {
        Write-Warning "Compare-SecurityBaselines: Latest baselines are null, cannot compare."
        return $updates # Return empty list
    }
    # If current is null (e.g., file didn't exist or was empty), all latest settings are considered updates.
    if ($null -eq $current) {
        Write-Warning "Compare-SecurityBaselines: Current baselines are null or empty, treating all 'latest' settings as new."
        foreach ($key in $latest.PSObject.Properties.Name) {
            $updates.Add(@{ Setting = $key; NewValue = $latest.$key; OldValue = "NotSet" })
        }
        return $updates
    }

    foreach ($key in $latest.PSObject.Properties.Name) {
        $latestValue = $latest.$key
        $currentValue = if ($current.PSObject.Properties.Name -contains $key) { $current.$key } else { $null }

        # Compare values (simple comparison, could be enhanced for complex objects)
        if (-not ($current.PSObject.Properties.Name -contains $key) -or ($currentValue -ne $latestValue)) {
            Write-Host "Found update for baseline setting: $key"
            $updates.Add(@{ Setting = $key; NewValue = $latestValue; OldValue = if($current.PSObject.Properties.Name -contains $key) { $currentValue } else { "NotSet" } })
        }
    }
    return $updates
}

function Backup-SecurityBaselines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$path
    )
    Write-Host "Backup-SecurityBaselines: Backing up '$path'."
    if (Test-Path -Path $path -PathType Leaf) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backupPath = "$path.bak.$timestamp"
        try {
            Copy-Item -Path $path -Destination $backupPath -Force -ErrorAction Stop # Add -Force
            Write-Host "Successfully backed up '$path' to '$backupPath'."
        } catch {
            Write-Error "Backup-SecurityBaselines: Failed to backup '$path'. Error: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Backup-SecurityBaselines: File '$path' not found, nothing to backup."
    }
}

function Apply-BaselineUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$update
    )
    # This function is primarily for logging the intent of an update.
    # The actual update to the baseline object happens in the main Update-SecurityBaselines function.
    Write-Host "Apply-BaselineUpdate: (Logging) Applying update for setting '$($update.Setting)' to value '$($update.NewValue)' (Old value was '$($update.OldValue)')."
    # In a more complex scenario, this function might interact with a live system
    # or perform more detailed validation before returning a success/failure.
}

function Test-BaselineConfiguration() {
    Write-Host "Test-BaselineConfiguration: Simulating baseline configuration test after updates."
    # This would involve querying actual system configurations against the desired baseline.
    # For this iteration, it's a placeholder.
    # Return a mock success status.
    return @{ TestStatus = "Success"; TestedItems = "Simulated"; IssuesFound = 0 }
}

function Document-BaselineUpdates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][array]$updates
    )
    Write-Host "Document-BaselineUpdates: Documenting $($updates.Count) baseline updates applied:"
    foreach ($updateEntry in $updates) { # Renamed variable for clarity
        Write-Host " - Setting '$($updateEntry.Setting)' changed to '$($updateEntry.NewValue)' (was '$($updateEntry.OldValue)')."
    }
    # In a real scenario, this might append to a change log file, create a report, or send notifications.
}