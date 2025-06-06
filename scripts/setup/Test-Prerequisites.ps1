[CmdletBinding()]
param()

Write-Host "Executing Test-Prerequisites.ps1..."
$global:PrereqCheckCriticalFailure = $false # Default to no critical failure

# Check PowerShell Version
Write-Host "Checking PowerShell Version..."
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Warning "PowerShell 5.1 or higher is recommended. Current version: $($PSVersionTable.PSVersion)"
    # Not setting $global:PrereqCheckCriticalFailure = $true for this, as it's a warning.
} else {
    Write-Host "PowerShell Version Check Passed: $($PSVersionTable.PSVersion)"
}

# Check for Administrator Privileges (Platform Agnostic)
Write-Host "Checking for Administrator Privileges..."
$isAdmin = $false
if ($IsWindows) {
    try {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
        $isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        Write-Warning "Could not perform Windows Administrator check: $_. This may not be critical depending on tasks."
    }
} elseif ($IsLinux -or $IsMacOS) {
    try {
        $userId = (Get-Process -Id $PID).UserId
        if ($userId -eq 0) { $isAdmin = $true }
    } catch {
        Write-Warning "Could not perform Linux/MacOS root check using Get-Process. Trying 'id -u'."
        try {
            $userIdTest = (id -u).Trim() # Output of id -u is a string
            if ($userIdTest -eq "0") { $isAdmin = $true }
        } catch {
            Write-Warning "Could not perform Linux/MacOS root check using 'id -u': $_. This may not be critical."
        }
    }
} else {
    Write-Warning "Administrator check not implemented for this platform: $($PSVersionTable.OS)"
}

if ($isAdmin) {
    Write-Host "Administrator Privileges Check Passed (or running as root on *nix)."
} else {
    Write-Warning "Administrator privileges are NOT detected. Some operations may fail. If admin rights are strictly required for subsequent operations, this should be treated as a failure."
    # Example: If admin is strictly required, you might set:
    # $global:PrereqCheckCriticalFailure = $true
    # Write-Error "Administrator privileges are required for this script to function."
}

if ($global:PrereqCheckCriticalFailure) {
    Write-Error "Test-Prerequisites.ps1 completed with CRITICAL errors."
    # The script throwing an error will be caught by try/catch in the caller if ErrorAction is Stop.
    # For explicit check, the global variable is primary.
} else {
    Write-Host "Test-Prerequisites.ps1 finished execution (may have warnings)."
}
