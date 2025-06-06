[CmdletBinding()]
param(
    [string]$BaselineConfigPath = "./config/security_baselines.json"
)

Write-Host "Executing Initialize-SecurityBaselines.ps1..."

if (-not (Test-Path -Path $BaselineConfigPath)) {
    Write-Host "File '$BaselineConfigPath' not found. Creating with default content..."
    try {
        $defaultBaselines = @{
            "BaselineVersion" = "1.0.0";
            "LastUpdated" = (Get-Date).ToString('u');
            "Settings" = @{
                "MinimumPasswordLength" = 14;
                "MFAEnabledForAllUsers" = "NotChecked";
                "AuditLogRetentionDays" = 365
            };
            "Comments" = "Default security baselines. Review and update according to your organization's policies."
        } | ConvertTo-Json -Depth 3

        Set-Content -Path $BaselineConfigPath -Value $defaultBaselines
        Write-Host "'$BaselineConfigPath' created successfully with default settings."
    } catch {
        Write-Error "Failed to create '$BaselineConfigPath': $_"
        exit 1
    }
} else {
    Write-Host "'$BaselineConfigPath' already exists. No action taken."
}

Write-Host "Initialize-SecurityBaselines.ps1 finished."
exit 0
