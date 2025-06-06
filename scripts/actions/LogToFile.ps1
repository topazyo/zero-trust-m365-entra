[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,

    [Parameter(Mandatory=$true)]
    [string]$Message,

    [string]$IncidentId = "N/A",
    [string]$LogLevel = "Info"
)

try {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$LogLevel] Incident: $IncidentId | Message: $Message"

    $directory = Split-Path -Path $FilePath -Resolve
    if ($directory -and (-not (Test-Path -Path $directory -PathType Container))) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    Add-Content -Path $FilePath -Value $logEntry
    Write-Host "LogToFile.ps1: Successfully wrote to $FilePath"
}
catch {
    Write-Error "LogToFile.ps1: Failed to write to $FilePath. Error: $($_.Exception.Message)"
    throw
}
