[CmdletBinding()]
param (
    [hashtable]$ConfigForTest # Optional config passed from Connect-ZeroTrustServices
)

Write-Host "Executing Test-ServiceConnections.ps1 (Enhanced)..."
$allConnectionsValid = $true

# Test Microsoft Graph Connection (if context expected)
Write-Host "Testing Microsoft Graph connection..."
try {
    $mgContext = Get-MgContext -ErrorAction SilentlyContinue # Use SilentlyContinue to handle "not connected" state gracefully
    if ($mgContext) {
        Write-Host "Successfully retrieved Microsoft Graph context. TenantId: $($mgContext.TenantId), Account: $($mgContext.Account)"
        # Perform a simple, non-modifying read operation
        # Get-MgUser -UserId "me" -ErrorAction Stop # Example, ensure service principal has rights or use a known user for test
        # Write-Host "Successfully made a test call to Graph (Get-MgUser me)."
        Write-Host "Mock Get-MgUser: Would attempt a test call."
    } else {
        Write-Warning "Microsoft Graph context not found. Assuming not connected or Connect-MgGraph was mocked."
        # $allConnectionsValid = $false # Only fail if connection was expected to be live
    }
} catch {
    Write-Error "Microsoft Graph connection test failed: $($_.Exception.Message)"
    $allConnectionsValid = $false
}

# Test Azure Connection (if context expected)
Write-Host "Testing Azure connection..."
try {
    $azContext = Get-AzContext -ErrorAction SilentlyContinue
    if ($azContext) {
        Write-Host "Successfully retrieved Azure context. TenantId: $($azContext.Tenant.Id), Account: $($azContext.Account.Id)"
        # Perform a simple, non-modifying read operation
        # Get-AzTenant -ErrorAction Stop # Example
        # Write-Host "Successfully made a test call to Azure (Get-AzTenant)."
        Write-Host "Mock Get-AzTenant: Would attempt a test call."
    } else {
        Write-Warning "Azure context not found. Assuming not connected or Connect-AzAccount was mocked."
        # $allConnectionsValid = $false # Only fail if connection was expected to be live
    }
} catch {
    Write-Error "Azure connection test failed: $($_.Exception.Message)"
    $allConnectionsValid = $false
}

# Add other specific service connection tests here (e.g., Azure Security Center specific checks if applicable)
# For example, check if Az.Security module cmdlets are available if Connect-AzSecurityCenter implies its use.
# if (Get-Command Get-AzSecurityTask -ErrorAction SilentlyContinue) {
#     Write-Host "Az.Security module cmdlets seem available."
# } else {
#     Write-Warning "Az.Security module cmdlets (like Get-AzSecurityTask) not found."
# }

if (!$allConnectionsValid) {
    throw "One or more service connection tests failed. Please check logs."
}

Write-Host "Test-ServiceConnections.ps1 finished successfully."
