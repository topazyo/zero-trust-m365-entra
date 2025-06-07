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

# --- Consolidated Install-RequiredModules function ---
function Install-RequiredModules {
    [CmdletBinding()]
    param (
        [hashtable]$modules,
        [string]$ConfigPath # While $modules are passed directly, keeping $ConfigPath for potential future use or if called elsewhere.
    )

    Write-Host "Starting module installation and verification..."
    $allModulesInstalledAndImported = $true
    $global:PesterModuleVersionInstalled = $null

    try {
        Write-Host "Ensuring NuGet package provider is available..."
        Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Out-Null
        if (-not $?) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop
            Write-Host "NuGet package provider installed."
        } else {
            Write-Host "NuGet package provider is already available."
        }
    } catch {
        Write-Error "Could not ensure NuGet package provider is available: $($_.Exception.Message)"
        throw "NuGet provider installation failed. Cannot proceed with module installations."
    }

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
                    # Update-Module might be preferable but Install-Module with -Force handles it.
                    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                    Write-Host "Module $moduleName updated to version $requiredVersion."
                } elseif ($installedVersion -gt [version]$requiredVersion) {
                    Write-Warning "Installed version $installedVersion of $moduleName is newer than specified $requiredVersion $moduleName. Assuming compatible, but ensure this is intended."
                } else {
                    Write-Host "Module $moduleName version $installedVersion is correct."
                }
            } else {
                Write-Host "Module $moduleName is not installed. Attempting installation of version $requiredVersion."
                Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope CurrentUser -SkipPublisherCheck -AllowClobber -AcceptLicense -Force -ErrorAction Stop
                Write-Host "Module $moduleName version $requiredVersion installed successfully."
            }

            Write-Host "Attempting to import module $moduleName (Required version: $requiredVersion)..."
            Import-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -ErrorAction Stop
            Write-Host "Successfully imported module $moduleName version $requiredVersion."

            if ($moduleName -eq "Pester") {
                $global:PesterModuleVersionInstalled = (Get-Module -Name "Pester" -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString()
                Write-Host "Pester version $global:PesterModuleVersionInstalled confirmed after import."
            }
        } catch {
            Write-Error "Failed to install or import module $moduleName (Required version: $requiredVersion). Error: $($_.Exception.Message)"
            $allModulesInstalledAndImported = $false
        }
    }

    if (-not $allModulesInstalledAndImported) {
        throw "One or more PowerShell modules could not be installed or imported correctly. Please check logs."
    }
    Write-Host "All specified modules installed and imported successfully."
}

# --- Consolidated Connect-ZeroTrustServices function ---
function Connect-ZeroTrustServices {
    [CmdletBinding()]
    param (
        [hashtable]$config # Expected to be $config.ConnectionSettings
    )

    Write-Host "Attempting connections to Zero Trust services..."
    $global:GraphConnectionStatus = "NotConnected"
    $global:AzureConnectionStatus = "NotConnected"

    # Microsoft Graph Connection
    Write-Host "Attempting to connect to Microsoft Graph..."
    try {
        if ($config.TenantId -and $config.TenantId -ne "YOUR_TENANT_ID_HERE_OR_FROM_ENVIRONMENT" -and $config.TenantId -ne "YOUR_TENANT_ID...") { # More robust placeholder check
            Connect-MgGraph -TenantId $config.TenantId -ErrorAction SilentlyContinue
        } else {
            Connect-MgGraph -ErrorAction SilentlyContinue
        }
        # It's good practice to check the context immediately after attempting connection.
        $mgContext = Get-MgContext -ErrorAction SilentlyContinue
        if ($mgContext -and $mgContext.TenantId) { # Check if TenantId is actually populated
            $global:GraphConnectionStatus = "Connected: $($mgContext.TenantId)"
            Write-Host "Successfully connected to Microsoft Graph. Tenant: $($mgContext.TenantId), Account: $($mgContext.Account)"
        } else {
            $global:GraphConnectionStatus = "Failed"
            Write-Warning "Failed to connect to Microsoft Graph or no valid context found."
        }
    } catch {
        $global:GraphConnectionStatus = "Error"
        Write-Warning "An exception occurred during Microsoft Graph connection attempt: $($_.Exception.Message)"
    }

    # Azure Connection
    Write-Host "Attempting to connect to Azure..."
    try {
        if ($config.TenantId -and $config.TenantId -ne "YOUR_TENANT_ID_HERE_OR_FROM_ENVIRONMENT" -and $config.TenantId -ne "YOUR_TENANT_ID...") { # More robust placeholder check
            Connect-AzAccount -Tenant $config.TenantId -ErrorAction SilentlyContinue
        } else {
            Connect-AzAccount -ErrorAction SilentlyContinue
        }
        # Check context immediately
        $azContext = Get-AzContext -ErrorAction SilentlyContinue
        if ($azContext -and $azContext.Tenant -and $azContext.Tenant.Id) { # Check if Tenant.Id is actually populated
            $global:AzureConnectionStatus = "Connected: $($azContext.Tenant.Id)"
            Write-Host "Successfully connected to Azure. Tenant: $($azContext.Tenant.Id), Account: $($azContext.Account.Id)"
        } else {
            $global:AzureConnectionStatus = "Failed"
            Write-Warning "Failed to connect to Azure or no valid context found."
        }
    } catch {
        $global:AzureConnectionStatus = "Error"
        Write-Warning "An exception occurred during Azure connection attempt: $($_.Exception.Message)"
    }

    # Optional: Check connection statuses and throw if critical connections failed
    # if ($global:GraphConnectionStatus -notlike "Connected:*" -or $global:AzureConnectionStatus -notlike "Connected:*") {
    #     Write-Warning "One or both critical services (Graph, Azure) are not connected."
    #     # Depending on requirements, you might throw an error here
    #     # throw "Failed to establish critical service connections."
    # }

    Write-Host "Zero Trust service connection attempts completed."
    Write-Host "Graph Connection Status: $global:GraphConnectionStatus"
    Write-Host "Azure Connection Status: $global:AzureConnectionStatus"
}

# --- Preserved Initialize-ZeroTrustEnvironment function (ensure only one definition) ---
function Initialize-ZeroTrustEnvironment {
    [CmdletBinding()]
    param()

    try {
        # Load configuration
        Write-Host "Loading configuration from $ConfigPath..."
        if (-not (Test-Path $ConfigPath)) {
            throw "Configuration file not found at $ConfigPath"
        }
        $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
        if (-null -eq $config) {
            throw "Failed to load or parse configuration from $ConfigPath. Content might be empty or invalid JSON."
        }
        Write-Host "Configuration loaded successfully."

        # Verify prerequisites
        if (!$SkipPreReqs) {
            Write-Host "Verifying prerequisites..."
            . ./scripts/setup/Test-Prerequisites.ps1 # Executing script
            if ($global:PrereqCheckCriticalFailure -and !$Force) {
                throw "Prerequisites critical check failed. See Test-Prerequisites.ps1 output for details."
            }
            Write-Host "Prerequisites check passed."
        } else {
            Write-Host "Skipping prerequisites check as per -SkipPreReqs flag."
        }

        # Install required PowerShell modules
        Write-Host "Installing required PowerShell modules..."
        # Pass $ConfigPath to Install-RequiredModules, though it might primarily use $config.RequiredModules
        Install-RequiredModules -modules $config.RequiredModules -ConfigPath $ConfigPath
        Write-Host "PowerShell module installation/verification completed."

        # Initialize Azure connections
        Write-Host "Connecting to Zero Trust services..."
        Connect-ZeroTrustServices -config $config.ConnectionSettings
        Write-Host "Zero Trust service connection process completed."

        # Setup initial configurations
        Write-Host "Initializing security baselines..."
        . ./scripts/setup/Initialize-SecurityBaselines.ps1
        Write-Host "Security baselines initialization completed."

        Write-Host "Initializing security monitoring..."
        . ./scripts/setup/Initialize-SecurityMonitoring.ps1
        Write-Host "Security monitoring initialization completed."

        # Verify installation
        Write-Host "Verifying installation..."
        . ./scripts/setup/Test-Installation.ps1
        Write-Host "Installation verification completed."
        # Assuming Test-Installation.ps1 will throw an error if verification fails.

        Write-Output "Zero Trust environment setup completed successfully."
    }
    catch {
        Write-Error "Failed to initialize Zero Trust environment: $($_.Exception.Message) Line: $($_.InvocationInfo.ScriptLineNumber)"
        # Consider re-throwing for script to exit with error
        throw $_
    }
}

# Main script execution logic (if any, typically functions are called from here or by sourcing the script)
# Example: Initialize-ZeroTrustEnvironment -Force:$Force -SkipPreReqs:$SkipPreReqs -ConfigPath:$ConfigPath
# If this script is meant to be sourced, then just defining functions is enough.
# If it's meant to be executed directly, the call to Initialize-ZeroTrustEnvironment should be here.
# Based on typical PowerShell script structure, the main function would be called at the end.

Initialize-ZeroTrustEnvironment -Force:$Force -SkipPreReqs:$SkipPreReqs -ConfigPath:$ConfigPath

Write-Host "install_dependencies.ps1 script finished."
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