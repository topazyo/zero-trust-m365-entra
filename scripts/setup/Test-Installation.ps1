[CmdletBinding()]
param()

Write-Host "Executing Test-Installation.ps1..."
$allChecksPassed = $true

$filesToCheck = @(
    "./config/installation.json",
    "./config/security_baselines.json",
    "./config/monitoring_settings.json",
    "./config/privileged_users.json"
)

foreach ($file in $filesToCheck) {
    Write-Host "Checking for file: $file..."
    if (Test-Path -Path $file) {
        Write-Host "File '$file' found."
    } else {
        Write-Error "File '$file' NOT found."
        $allChecksPassed = $false
    }
}

if ($allChecksPassed) {
    Write-Host "Test-Installation.ps1 completed successfully. All key files found."
} else {
    Write-Error "Test-Installation.ps1 completed with errors: One or more key files are missing."
}
exit (if ($allChecksPassed) {0} else {1})
