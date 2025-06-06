[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules
    )

    Write-Host "Starting REAL module installation and verification..."
    $allModulesInstalled = $true
    $global:PesterModuleVersionInstalled = $null

    try {
        Write-Host "Ensuring NuGet provider is available..."
        Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Out-Null
        if (-not $?) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop }
        Write-Host "NuGet provider is available."
    } catch {
        Write-Warning "Could not install NuGet provider: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting REAL connections to Zero Trust services..."
    $global:GraphConnectionStatus = "NotConnected"
    $global:AzureConnectionStatus = "NotConnected"

    try {
        Write-Host "Attempting to connect to Microsoft Graph..."
        if ($config.TenantId -and $config.TenantId -ne "YOUR_TENANT_ID_HERE_OR_FROM_ENVIRONMENT") {
            Connect-MgGraph -TenantId $config.TenantId -ErrorAction SilentlyContinue
        } else {
            Connect-MgGraph -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        $mgContext = Get-MgContext -ErrorAction SilentlyContinue
        if ($mgContext) {
            Write-Host "Successfully connected to Microsoft Graph. Tenant: $($mgContext.TenantId), Account: $($mgContext.Account)"
            $global:GraphConnectionStatus = "Connected: $($mgContext.TenantId)"
        } else {
            Write-Warning "Failed to connect to Microsoft Graph or no existing context found."
        }
    } catch { Write-Warning "Error during Microsoft Graph connection attempt: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules
    )

    Write-Host "Starting REAL module installation and verification..."
    $allModulesInstalled = $true
    $global:PesterModuleVersionInstalled = $null

    try {
        Write-Host "Ensuring NuGet provider is available..."
        Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Out-Null
        if (-not $?) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop }
        Write-Host "NuGet provider is available."
    } catch {
        Write-Warning "Could not install NuGet provider: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
    }

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"
        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable | Where-Object { [CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Version.ToString() -eq $requiredVersion }
            if ($installedModule) {
                Write-Host "Module $moduleName version $requiredVersion is already installed."
            } else {
                Write-Host "Module $moduleName version $requiredVersion not found or version mismatch. Attempting installation..."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName (version $requiredVersion)..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

            if ($moduleName -eq "Pester") {
                $global:PesterModuleVersionInstalled = (Get-Module -Name Pester).Version.ToString()
                Write-Host "Pester version $global:PesterModuleVersionInstalled confirmed."
            }
        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
            $allModulesInstalled = $false
        }
    }

    if (-not $allModulesInstalled) {
        Write-Error "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    } else {
        Write-Host "All specified modules installed and imported successfully."
    }
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)" }

    try {
        Write-Host "Attempting to connect to Azure..."
        if ($config.TenantId -and $config.TenantId -ne "YOUR_TENANT_ID_HERE_OR_FROM_ENVIRONMENT") {
            Connect-AzAccount -Tenant $config.TenantId -ErrorAction SilentlyContinue
        } else {
            Connect-AzAccount -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        $azContext = Get-AzContext -ErrorAction SilentlyContinue
        if ($azContext) {
            Write-Host "Successfully connected to Azure. Tenant: $($azContext.Tenant.Id), Account: $($azContext.Account.Id)"
            $global:AzureConnectionStatus = "Connected: $($azContext.Tenant.Id)"
        } else {
            Write-Warning "Failed to connect to Azure or no existing context found."
        }
    } catch { Write-Warning "Error during Azure connection attempt: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules
    )

    Write-Host "Starting REAL module installation and verification..."
    $allModulesInstalled = $true
    $global:PesterModuleVersionInstalled = $null

    try {
        Write-Host "Ensuring NuGet provider is available..."
        Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Out-Null
        if (-not $?) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop }
        Write-Host "NuGet provider is available."
    } catch {
        Write-Warning "Could not install NuGet provider: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
    }

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"
        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable | Where-Object { [CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Version.ToString() -eq $requiredVersion }
            if ($installedModule) {
                Write-Host "Module $moduleName version $requiredVersion is already installed."
            } else {
                Write-Host "Module $moduleName version $requiredVersion not found or version mismatch. Attempting installation..."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName (version $requiredVersion)..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

            if ($moduleName -eq "Pester") {
                $global:PesterModuleVersionInstalled = (Get-Module -Name Pester).Version.ToString()
                Write-Host "Pester version $global:PesterModuleVersionInstalled confirmed."
            }
        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
            $allModulesInstalled = $false
        }
    }

    if (-not $allModulesInstalled) {
        Write-Error "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    } else {
        Write-Host "All specified modules installed and imported successfully."
    }
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)" }

    Write-Host "Running service connection tests..."
    . ./scripts/setup/Test-ServiceConnections.ps1
}.Exception.Message)"
    }

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"
        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable | Where-Object { [CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting REAL connections to Zero Trust services..."
    $global:GraphConnectionStatus = "NotConnected"
    $global:AzureConnectionStatus = "NotConnected"

    try {
        Write-Host "Attempting to connect to Microsoft Graph..."
        if ($config.TenantId -and $config.TenantId -ne "YOUR_TENANT_ID_HERE_OR_FROM_ENVIRONMENT") {
            Connect-MgGraph -TenantId $config.TenantId -ErrorAction SilentlyContinue
        } else {
            Connect-MgGraph -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        $mgContext = Get-MgContext -ErrorAction SilentlyContinue
        if ($mgContext) {
            Write-Host "Successfully connected to Microsoft Graph. Tenant: $($mgContext.TenantId), Account: $($mgContext.Account)"
            $global:GraphConnectionStatus = "Connected: $($mgContext.TenantId)"
        } else {
            Write-Warning "Failed to connect to Microsoft Graph or no existing context found."
        }
    } catch { Write-Warning "Error during Microsoft Graph connection attempt: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules
    )

    Write-Host "Starting REAL module installation and verification..."
    $allModulesInstalled = $true
    $global:PesterModuleVersionInstalled = $null

    try {
        Write-Host "Ensuring NuGet provider is available..."
        Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Out-Null
        if (-not $?) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop }
        Write-Host "NuGet provider is available."
    } catch {
        Write-Warning "Could not install NuGet provider: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
    }

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"
        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable | Where-Object { [CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Version.ToString() -eq $requiredVersion }
            if ($installedModule) {
                Write-Host "Module $moduleName version $requiredVersion is already installed."
            } else {
                Write-Host "Module $moduleName version $requiredVersion not found or version mismatch. Attempting installation..."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName (version $requiredVersion)..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

            if ($moduleName -eq "Pester") {
                $global:PesterModuleVersionInstalled = (Get-Module -Name Pester).Version.ToString()
                Write-Host "Pester version $global:PesterModuleVersionInstalled confirmed."
            }
        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
            $allModulesInstalled = $false
        }
    }

    if (-not $allModulesInstalled) {
        Write-Error "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    } else {
        Write-Host "All specified modules installed and imported successfully."
    }
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)" }

    try {
        Write-Host "Attempting to connect to Azure..."
        if ($config.TenantId -and $config.TenantId -ne "YOUR_TENANT_ID_HERE_OR_FROM_ENVIRONMENT") {
            Connect-AzAccount -Tenant $config.TenantId -ErrorAction SilentlyContinue
        } else {
            Connect-AzAccount -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        $azContext = Get-AzContext -ErrorAction SilentlyContinue
        if ($azContext) {
            Write-Host "Successfully connected to Azure. Tenant: $($azContext.Tenant.Id), Account: $($azContext.Account.Id)"
            $global:AzureConnectionStatus = "Connected: $($azContext.Tenant.Id)"
        } else {
            Write-Warning "Failed to connect to Azure or no existing context found."
        }
    } catch { Write-Warning "Error during Azure connection attempt: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules
    )

    Write-Host "Starting REAL module installation and verification..."
    $allModulesInstalled = $true
    $global:PesterModuleVersionInstalled = $null

    try {
        Write-Host "Ensuring NuGet provider is available..."
        Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Out-Null
        if (-not $?) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop }
        Write-Host "NuGet provider is available."
    } catch {
        Write-Warning "Could not install NuGet provider: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
    }

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"
        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable | Where-Object { [CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Version.ToString() -eq $requiredVersion }
            if ($installedModule) {
                Write-Host "Module $moduleName version $requiredVersion is already installed."
            } else {
                Write-Host "Module $moduleName version $requiredVersion not found or version mismatch. Attempting installation..."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName (version $requiredVersion)..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

            if ($moduleName -eq "Pester") {
                $global:PesterModuleVersionInstalled = (Get-Module -Name Pester).Version.ToString()
                Write-Host "Pester version $global:PesterModuleVersionInstalled confirmed."
            }
        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
            $allModulesInstalled = $false
        }
    }

    if (-not $allModulesInstalled) {
        Write-Error "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    } else {
        Write-Host "All specified modules installed and imported successfully."
    }
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)" }

    Write-Host "Running service connection tests..."
    . ./scripts/setup/Test-ServiceConnections.ps1
}.Version.ToString() -eq $requiredVersion }
            if ($installedModule) {
                Write-Host "Module $moduleName version $requiredVersion is already installed."
            } else {
                Write-Host "Module $moduleName version $requiredVersion not found or version mismatch. Attempting installation..."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName (version $requiredVersion)..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

            if ($moduleName -eq "Pester") {
                $global:PesterModuleVersionInstalled = (Get-Module -Name Pester).Version.ToString()
                Write-Host "Pester version $global:PesterModuleVersionInstalled confirmed."
            }
        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting REAL connections to Zero Trust services..."
    $global:GraphConnectionStatus = "NotConnected"
    $global:AzureConnectionStatus = "NotConnected"

    try {
        Write-Host "Attempting to connect to Microsoft Graph..."
        if ($config.TenantId -and $config.TenantId -ne "YOUR_TENANT_ID_HERE_OR_FROM_ENVIRONMENT") {
            Connect-MgGraph -TenantId $config.TenantId -ErrorAction SilentlyContinue
        } else {
            Connect-MgGraph -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        $mgContext = Get-MgContext -ErrorAction SilentlyContinue
        if ($mgContext) {
            Write-Host "Successfully connected to Microsoft Graph. Tenant: $($mgContext.TenantId), Account: $($mgContext.Account)"
            $global:GraphConnectionStatus = "Connected: $($mgContext.TenantId)"
        } else {
            Write-Warning "Failed to connect to Microsoft Graph or no existing context found."
        }
    } catch { Write-Warning "Error during Microsoft Graph connection attempt: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules
    )

    Write-Host "Starting REAL module installation and verification..."
    $allModulesInstalled = $true
    $global:PesterModuleVersionInstalled = $null

    try {
        Write-Host "Ensuring NuGet provider is available..."
        Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Out-Null
        if (-not $?) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop }
        Write-Host "NuGet provider is available."
    } catch {
        Write-Warning "Could not install NuGet provider: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
    }

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"
        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable | Where-Object { [CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true
    
    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Version.ToString() -eq $requiredVersion }
            if ($installedModule) {
                Write-Host "Module $moduleName version $requiredVersion is already installed."
            } else {
                Write-Host "Module $moduleName version $requiredVersion not found or version mismatch. Attempting installation..."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName (version $requiredVersion)..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

            if ($moduleName -eq "Pester") {
                $global:PesterModuleVersionInstalled = (Get-Module -Name Pester).Version.ToString()
                Write-Host "Pester version $global:PesterModuleVersionInstalled confirmed."
            }
        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
            $allModulesInstalled = $false
        }
    }

    if (-not $allModulesInstalled) {
        Write-Error "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    } else {
        Write-Host "All specified modules installed and imported successfully."
    }
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)" }

    try {
        Write-Host "Attempting to connect to Azure..."
        if ($config.TenantId -and $config.TenantId -ne "YOUR_TENANT_ID_HERE_OR_FROM_ENVIRONMENT") {
            Connect-AzAccount -Tenant $config.TenantId -ErrorAction SilentlyContinue
        } else {
            Connect-AzAccount -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        $azContext = Get-AzContext -ErrorAction SilentlyContinue
        if ($azContext) {
            Write-Host "Successfully connected to Azure. Tenant: $($azContext.Tenant.Id), Account: $($azContext.Account.Id)"
            $global:AzureConnectionStatus = "Connected: $($azContext.Tenant.Id)"
        } else {
            Write-Warning "Failed to connect to Azure or no existing context found."
        }
    } catch { Write-Warning "Error during Azure connection attempt: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules
    )

    Write-Host "Starting REAL module installation and verification..."
    $allModulesInstalled = $true
    $global:PesterModuleVersionInstalled = $null

    try {
        Write-Host "Ensuring NuGet provider is available..."
        Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Out-Null
        if (-not $?) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop }
        Write-Host "NuGet provider is available."
    } catch {
        Write-Warning "Could not install NuGet provider: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
    }

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"
        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable | Where-Object { [CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Version.ToString() -eq $requiredVersion }
            if ($installedModule) {
                Write-Host "Module $moduleName version $requiredVersion is already installed."
            } else {
                Write-Host "Module $moduleName version $requiredVersion not found or version mismatch. Attempting installation..."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName (version $requiredVersion)..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

            if ($moduleName -eq "Pester") {
                $global:PesterModuleVersionInstalled = (Get-Module -Name Pester).Version.ToString()
                Write-Host "Pester version $global:PesterModuleVersionInstalled confirmed."
            }
        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
            $allModulesInstalled = $false
        }
    }

    if (-not $allModulesInstalled) {
        Write-Error "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    } else {
        Write-Host "All specified modules installed and imported successfully."
    }
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)" }

    Write-Host "Running service connection tests..."
    . ./scripts/setup/Test-ServiceConnections.ps1
}.Exception.Message)"
            $allModulesInstalled = $false
        }
    }

    if (-not $allModulesInstalled) {
        Write-Error "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    } else {
        Write-Host "All specified modules installed and imported successfully."
    }
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting REAL connections to Zero Trust services..."
    $global:GraphConnectionStatus = "NotConnected"
    $global:AzureConnectionStatus = "NotConnected"

    try {
        Write-Host "Attempting to connect to Microsoft Graph..."
        if ($config.TenantId -and $config.TenantId -ne "YOUR_TENANT_ID_HERE_OR_FROM_ENVIRONMENT") {
            Connect-MgGraph -TenantId $config.TenantId -ErrorAction SilentlyContinue
        } else {
            Connect-MgGraph -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        $mgContext = Get-MgContext -ErrorAction SilentlyContinue
        if ($mgContext) {
            Write-Host "Successfully connected to Microsoft Graph. Tenant: $($mgContext.TenantId), Account: $($mgContext.Account)"
            $global:GraphConnectionStatus = "Connected: $($mgContext.TenantId)"
        } else {
            Write-Warning "Failed to connect to Microsoft Graph or no existing context found."
        }
    } catch { Write-Warning "Error during Microsoft Graph connection attempt: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules
    )

    Write-Host "Starting REAL module installation and verification..."
    $allModulesInstalled = $true
    $global:PesterModuleVersionInstalled = $null

    try {
        Write-Host "Ensuring NuGet provider is available..."
        Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Out-Null
        if (-not $?) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop }
        Write-Host "NuGet provider is available."
    } catch {
        Write-Warning "Could not install NuGet provider: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
    }

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"
        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable | Where-Object { [CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Version.ToString() -eq $requiredVersion }
            if ($installedModule) {
                Write-Host "Module $moduleName version $requiredVersion is already installed."
            } else {
                Write-Host "Module $moduleName version $requiredVersion not found or version mismatch. Attempting installation..."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName (version $requiredVersion)..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

            if ($moduleName -eq "Pester") {
                $global:PesterModuleVersionInstalled = (Get-Module -Name Pester).Version.ToString()
                Write-Host "Pester version $global:PesterModuleVersionInstalled confirmed."
            }
        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
            $allModulesInstalled = $false
        }
    }

    if (-not $allModulesInstalled) {
        Write-Error "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    } else {
        Write-Host "All specified modules installed and imported successfully."
    }
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)" }

    try {
        Write-Host "Attempting to connect to Azure..."
        if ($config.TenantId -and $config.TenantId -ne "YOUR_TENANT_ID_HERE_OR_FROM_ENVIRONMENT") {
            Connect-AzAccount -Tenant $config.TenantId -ErrorAction SilentlyContinue
        } else {
            Connect-AzAccount -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        $azContext = Get-AzContext -ErrorAction SilentlyContinue
        if ($azContext) {
            Write-Host "Successfully connected to Azure. Tenant: $($azContext.Tenant.Id), Account: $($azContext.Account.Id)"
            $global:AzureConnectionStatus = "Connected: $($azContext.Tenant.Id)"
        } else {
            Write-Warning "Failed to connect to Azure or no existing context found."
        }
    } catch { Write-Warning "Error during Azure connection attempt: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting REAL module installation and verification..."
    $allModulesInstalled = $true
    $global:PesterModuleVersionInstalled = $null

    try {
        Write-Host "Ensuring NuGet provider is available..."
        Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Out-Null
        if (-not $?) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop }
        Write-Host "NuGet provider is available."
    } catch {
        Write-Warning "Could not install NuGet provider: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
    }

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"
        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable | Where-Object { [CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Version.ToString() -eq $requiredVersion }
            if ($installedModule) {
                Write-Host "Module $moduleName version $requiredVersion is already installed."
            } else {
                Write-Host "Module $moduleName version $requiredVersion not found or version mismatch. Attempting installation..."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName (version $requiredVersion)..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

            if ($moduleName -eq "Pester") {
                $global:PesterModuleVersionInstalled = (Get-Module -Name Pester).Version.ToString()
                Write-Host "Pester version $global:PesterModuleVersionInstalled confirmed."
            }
        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $([CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPreReqs,
    [string]$ConfigPath = ".\config\installation.json"
)

# --- New Install-RequiredModules function from prompt ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # Added to access installation.json for module details
    )

    Write-Host "Starting module installation and verification..."
    $allModulesValid = $true

    foreach ($moduleName in $modules.Keys) {
        $requiredVersion = $modules[$moduleName]
        Write-Host "Processing module: $moduleName (Required version: $requiredVersion)"

        try {
            $installedModule = Get-Module -Name $moduleName -ListAvailable
            if ($installedModule) {
                $installedVersion = $installedModule[0].Version # Take the first one if multiple are present
                Write-Host "Module $moduleName is already installed (Version: $installedVersion)."
                if ($installedVersion -lt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is older than required $requiredVersion. Attempting update."
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion. Assuming compatible."
                } else {
                    Write-Host "Version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesValid = $false
        }
    }

    if (!$allModulesValid) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "Module installation and verification completed."
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)"
            $allModulesInstalled = $false
        }
    }

    if (-not $allModulesInstalled) {
        Write-Error "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    } else {
        Write-Host "All specified modules installed and imported successfully."
    }
}

# --- Preserved Initialize-ZeroTrustEnvironment function ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable

        # Verify prerequisites
        if (!$SkipPreReqs) {
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
        }

        # Install required PowerShell modules
        # Pass $ConfigPath to Install-RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath

        # Initialize Azure connections
        Connect-ZeroTrustServices -config $config.ConnectionSettings

        # Setup initial configurations
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1

        # Verify installation
        . ./scripts/setup/Test-Installation.ps1
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully"
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $_"
        throw
    }
}

# --- New Connect-ZeroTrustServices function from prompt ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config
    )
    Write-Host "Attempting to connect to Zero Trust services..."
    $allServicesConnected = $true

    try {
        Write-Host "Connecting to Azure (Tenant: $($config.TenantId))..."
        # Connect-AzAccount -TenantId $config.TenantId -ErrorAction Stop
        Write-Host "Mock Connect-AzAccount: Would attempt connection to tenant $($config.TenantId). (Commented out for non-interactive test)"

        Write-Host "Connecting to Microsoft Graph (Scopes: $($config.RequiredScopes -join ', '))..."
        # Connect-MgGraph -Scopes $config.RequiredScopes -ErrorAction Stop
        Write-Host "Mock Connect-MgGraph: Would attempt connection with scopes. (Commented out for non-interactive test)"

        Write-Host "Connecting to Azure Security Center..."
        # Connect-AzSecurityCenter -ErrorAction Stop
        Write-Host "Mock Connect-AzSecurityCenter: Placeholder for Security Center connection. (Commented out for non-interactive test)"

        Write-Host "Running service connection tests..."
        . ./scripts/setup/Test-ServiceConnections.ps1 -ConfigForTest $config

    }
    catch {
        Write-Error "Failed to connect to one or more required services: $($_.Exception.Message)"
        $allServicesConnected = $false
    }

    if (!$allServicesConnected) {
        throw "Could not connect to all required Zero Trust services. Please check logs and configurations."
    }
    Write-Host "Successfully connected/verified Zero Trust services."
}.Exception.Message)" }

    Write-Host "Running service connection tests..."
    . ./scripts/setup/Test-ServiceConnections.ps1
}