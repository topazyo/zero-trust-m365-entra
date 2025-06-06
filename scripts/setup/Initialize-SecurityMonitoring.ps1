[CmdletBinding()]
param(
    [string]$MonitoringConfigPath = "./config/monitoring_settings.json"
)

Write-Host "Executing Initialize-SecurityMonitoring.ps1..."

if (-not (Test-Path -Path $MonitoringConfigPath)) {
    Write-Host "File '$MonitoringConfigPath' not found. Creating with default content..."
    try {
        $defaultMonitoringSettings = @{
            "MonitoringVersion" = "1.0.0";
            "LastUpdated" = (Get-Date).ToString('u');
            "Rules" = @(
                @{
                    "RuleName" = "DefaultLogAllEvents";
                    "Enabled" = $false;
                    "Description" = "Placeholder rule to log all events. Refine before production."
                }
            );
            "Comments" = "Default monitoring settings. Review and update with specific monitoring rules."
        } | ConvertTo-Json -Depth 3

        Set-Content -Path $MonitoringConfigPath -Value $defaultMonitoringSettings
        Write-Host "'$MonitoringConfigPath' created successfully with default settings."
    } catch {
        Write-Error "Failed to create '$MonitoringConfigPath': $_"
        exit 1
    }
} else {
    Write-Host "'$MonitoringConfigPath' already exists. No action taken."
}

Write-Host "Initialize-SecurityMonitoring.ps1 finished."
exit 0
