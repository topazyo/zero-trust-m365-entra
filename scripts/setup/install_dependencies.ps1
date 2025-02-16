[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

function Install-RequiredModules {
    param (
        [hashtable]$modules
    )
    
    foreach ($module in $modules.Keys) {
        try {
            Write-Verbose "Installing module: $module version $($modules[$module])"
            if (!(Get-Module -ListAvailable -Name $module)) {
                Install-Module -Name $module -RequiredVersion $modules[$module] -Force
            }
            Import-Module -Name $module -RequiredVersion $modules[$module] -Force
        }
        catch {
            Write-Error "Failed to install module $module : $_"
            throw
        }
    }
}

function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            $prerequisites = Test-Prerequisites
            if (!$prerequisites.Success -and !$Force) {
                throw "Prerequisites check failed: $($prerequisites.Message)"
            }
        }

        # Install required PowerShell modules
        Install-RequiredModules -modules $config.RequiredModules

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        Initialize-SecurityBaselines -config $config.SecurityBaselines

        # Setup monitoring
        Initialize-SecurityMonitoring -config $config.MonitoringSettings

        # Verify installation
        $verification = Test-Installation
        if (!$verification.Success) {
            throw "Installation verification failed: $($verification.Message)"
        }

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

function Connect-ZeroTrustServices {
    param (
        [hashtable]$config
    )

    try {
        # Connect to Azure
        Connect-AzAccount -TenantId $config.TenantId

        # Connect to Microsoft Graph
        Connect-MgGraph -Scopes $config.RequiredScopes

        # Connect to Security Center
        Connect-AzSecurityCenter

        # Verify connections
        Test-ServiceConnections
    }
    catch {
        Write-Error "Failed to connect to required services: $_"
        throw
    }
}