[CmdletBinding()]
param (
    [string]$TenantId = $env:AZURE_TENANT_ID,
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$PrivilegedUsersConfigPath = "./config/privileged_users.json",
    [string]$MainConfigPath = "./config/installation.json" # Corrected path depth
)

Write-Host "Executing Initialize-Environment.ps1..."
Write-Host "Purpose: To set up environment-specific configurations and ensure essential config files exist."

# Ensure config directory exists
$configDir = Split-Path -Path $MainConfigPath -Parent
if (-not (Test-Path $configDir -PathType Container)) {
    Write-Host "Configuration directory '$configDir' does not exist. Creating it..."
    try {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        Write-Host "Configuration directory '$configDir' created."
    } catch {
        Write-Error "Failed to create configuration directory '$configDir'. Error: $($_.Exception.Message)"
        throw "Failed to create configuration directory."
    }
}

# Handle TenantId in installation.json
Write-Host "Checking TenantId in '$MainConfigPath'..."
if (Test-Path $MainConfigPath) {
    try {
        $installConfig = Get-Content $MainConfigPath -Raw | ConvertFrom-Json -ErrorAction Stop
        if ($installConfig.ConnectionSettings.TenantId -eq "YOUR_TENANT_ID" -or [string]::IsNullOrEmpty($installConfig.ConnectionSettings.TenantId)) {
            if (-not [string]::IsNullOrEmpty($TenantId) -and $TenantId -ne "YOUR_TENANT_ID") {
                Write-Host "Updating TenantId in '$MainConfigPath' with provided value: $TenantId"
                $installConfig.ConnectionSettings.TenantId = $TenantId
                $installConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $MainConfigPath -Force
            } else {
                Write-Warning "TenantId in '$MainConfigPath' is a placeholder or empty, and no valid TenantId was provided to this script. Please configure it manually or via environment variable AZURE_TENANT_ID."
            }
        } else {
            Write-Host "TenantId in '$MainConfigPath' is already set to: $($installConfig.ConnectionSettings.TenantId)."
        }
    } catch {
        Write-Error "Error processing '$MainConfigPath': $($_.Exception.Message)"
    }
} else {
    Write-Warning "'$MainConfigPath' not found. TenantId configuration will be skipped. This file is usually created by other setup steps or should exist."
}

# Create config/privileged_users.json if it doesn't exist
Write-Host "Checking for '$PrivilegedUsersConfigPath'..."
$privilegedUsersDir = Split-Path -Path $PrivilegedUsersConfigPath -Parent
 if (-not (Test-Path $privilegedUsersDir -PathType Container)) {
    Write-Host "Configuration directory '$privilegedUsersDir' for privileged users does not exist. Creating it..."
    try {
        New-Item -Path $privilegedUsersDir -ItemType Directory -Force | Out-Null
        Write-Host "Configuration directory '$privilegedUsersDir' created."
    } catch {
        Write-Error "Failed to create configuration directory '$privilegedUsersDir'. Error: $($_.Exception.Message)"
        # Continue, as privileged_users.json might be optional or created by another process
    }
}

if (-not (Test-Path $PrivilegedUsersConfigPath)) {
    Write-Host "'$PrivilegedUsersConfigPath' not found. Creating with default content..."
    $defaultPrivilegedUsers = @{
        privilegedUsers = @()
        lastUpdated = (Get-Date -Format 'u').ToString()
        description = "List of users considered privileged. Managed by Initialize-Environment.ps1 if created by it."
    }
    try {
        $defaultPrivilegedUsers | ConvertTo-Json -Depth 3 | Set-Content -Path $PrivilegedUsersConfigPath -Force
        Write-Host "'$PrivilegedUsersConfigPath' created successfully."
    } catch {
        Write-Error "Failed to create '$PrivilegedUsersConfigPath'. Error: $($_.Exception.Message)"
    }
} else {
    Write-Host "'$PrivilegedUsersConfigPath' already exists."
}

if (-not [string]::IsNullOrEmpty($SubscriptionId)) {
   Write-Host "SubscriptionId provided: $SubscriptionId. This script currently doesn't write it to a file, but it could be used by other scripts."
}


Write-Host "Initialize-Environment.ps1 finished."
