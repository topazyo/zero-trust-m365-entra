# Zero Trust Implementation for Microsoft 365 & Entra ID

## Overview
This repository contains a comprehensive implementation of Zero Trust security principles for Microsoft 365 and Entra ID environments. It provides a robust framework for implementing and managing advanced security controls, monitoring, and automated response capabilities.

## Current Status (Post-Refactoring)
This repository has recently undergone a significant refactoring and de-stubbing effort.
Key updates include:
-   **Setup Script Consolidation:** The `scripts/setup/install_dependencies.ps1` script has been streamlined, removing duplicate functions and clarifying connection logic. The new `scripts/setup/Initialize-Environment.ps1` script assists with initial environment configuration.
-   **Core Logic De-stubbed:** The core engine components (`ThreatHunter`, `ResponseOrchestrator`, `ThreatIntelligenceManager`) and the main automation script (`SecurityIncidentResponder`) have had their placeholder (stub) functions replaced with functional mock implementations. This means the primary workflows and class interactions are now functional at a framework level, with detailed logging.
-   **Next Steps:** The next major phase for these components will involve replacing the mock logic with full integrations with respective external services (SIEMs, SOAR platforms, TI Feeds, etc.).
-   **Test Coverage:** Initial Pester unit tests have been added for all major engine components and the `SecurityIncidentResponder`.

The system is now better structured for further development and integration.

## Key Features
- **Advanced Identity Protection**
  - Privileged Identity Management
  - Just-in-Time Access Control
  - Risk-based Authentication
  - Behavioral Analytics

- **Access Control Management**
  - Conditional Access Policies
  - Dynamic Access Reviews
  - Session Management
  - Advanced Role-Based Access Control

- **Security Monitoring and Response**
  - Real-time Threat Detection
  - Automated Incident Response
  - Security Analytics Engine
  - Behavioral Monitoring

- **Compliance and Reporting**
  - Automated Compliance Checks
  - Advanced Report Generation
  - Security Posture Assessment
  - Audit Trail Management

## Architecture
The solution is built on a modular architecture with the following core components:
- Identity Protection System
- Access Management System
- Security Analytics Engine
- Automated Response System
- Compliance Management System
- Reporting and Dashboard System

## Prerequisites
- PowerShell 7.0 or higher
- Microsoft 365 E5 Security or equivalent licensing
- Azure AD P2 licensing for PIM features
- Microsoft Graph PowerShell SDK
- Azure Az PowerShell module

## Installation
1.  **Clone the repository:**
    ```powershell
    git clone https://github.com/your-organization/zero-trust-m365-entra.git
    cd zero-trust-m365-entra
    ```
2.  **Review Configuration:**
    Before running installation scripts, review `config/installation.json`. While `Initialize-Environment.ps1` can help set the `TenantId`, you may need to pre-configure it or other settings manually depending on your environment.
3.  **Initialize Environment (Recommended First Step):**
    This script helps set up basic configurations, including potentially updating `config/installation.json` with your `TenantId` and creating `config/privileged_users.json`.
    ```powershell
    # Ensure you are in the repository root directory
    ./scripts/setup/Initialize-Environment.ps1 -TenantId "YOUR_ACTUAL_TENANT_ID"
    # Or rely on AZURE_TENANT_ID environment variable
    ```
4.  **Install Dependencies:**
    This script installs required PowerShell modules.
    ```powershell
    ./scripts/setup/Install-Dependencies.ps1
    ```
5.  **Run Further Setup Scripts (if applicable):**
    The framework includes other setup scripts (like `Initialize-SecurityBaselines.ps1`, `Initialize-SecurityMonitoring.ps1`) which are called by `Install-Dependencies.ps1` if you run its main `Initialize-ZeroTrustEnvironment` function, or can be run if needed. `Test-Installation.ps1` can be used to check for key files.
