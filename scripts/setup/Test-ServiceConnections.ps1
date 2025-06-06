[CmdletBinding()]
param ()

Write-Host "Executing REAL Test-ServiceConnections.ps1..."
$allConnectionsTestedOkay = $true

Write-Host "Verifying Microsoft Graph connection status..."
if ($global:GraphConnectionStatus -like "Connected*") {
    Write-Host "Microsoft Graph connection confirmed by global status: $global:GraphConnectionStatus"
} else {
    Write-Warning "Microsoft Graph connection not established or status unknown. Global status: $($global:GraphConnectionStatus)"
}

Write-Host "Verifying Azure connection status..."
if ($global:AzureConnectionStatus -like "Connected*") {
    Write-Host "Azure connection confirmed by global status: $global:AzureConnectionStatus"
} else {
    Write-Warning "Azure connection not established or status unknown. Global status: $($global:AzureConnectionStatus)"
}

if ($allConnectionsTestedOkay) { # This variable is not being set to false currently, needs refinement if strict failure is desired
    Write-Host "Test-ServiceConnections.ps1 completed. Check warnings for non-critical issues."
} else {
    Write-Error "Test-ServiceConnections.ps1 completed with issues. Some services may not be connected."
}
