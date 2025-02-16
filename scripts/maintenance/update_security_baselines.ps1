[CmdletBinding()]
param (
    [string]$BaselinePath = ".\config\security_baselines.json",
    [switch]$ForceUpdate
)

function Update-SecurityBaselines {
    [CmdletBinding()]
    param()

    try {
        # Load current baselines
        $currentBaselines = Get-Content $BaselinePath | ConvertFrom-Json

        # Get latest baseline recommendations
        $latestBaselines = Get-LatestSecurityBaselines

        # Compare and identify updates
        $updates = Compare-SecurityBaselines -current $currentBaselines -latest $latestBaselines

        if ($updates.Count -gt 0 -or $ForceUpdate) {
            # Backup current baselines
            Backup-SecurityBaselines -path $BaselinePath

            # Apply updates
            foreach ($update in $updates) {
                Apply-BaselineUpdate -update $update
            }

            # Validate updates
            Test-BaselineConfiguration

            # Document changes
            Document-BaselineUpdates -updates $updates
        }

        return @{
            UpdatesApplied = $updates.Count
            Timestamp = [datetime]::UtcNow
            Status = "Success"
        }
    }
    catch {
        Write-Error "Failed to update security baselines: $_"
        throw
    }
}