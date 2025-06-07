# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2024-05-20

This marks a significant refactoring and de-stubbing phase of the project.

### Added
-   New setup script `scripts/setup/Initialize-Environment.ps1`:
    -   Assists with initial environment configuration (e.g., TenantId).
    -   Creates a default `config/privileged_users.json` if not present.
    -   Attempts to update `TenantId` in `config/installation.json`.
-   New Pester unit test files with initial test suites:
    -   `src/playbook/PlaybookManager.tests.ps1`
    -   `src/response/ResponseOrchestrator.tests.ps1`
    -   `src/intelligence/ThreatIntelligenceManager.tests.ps1`
-   `README.md`: Added a "Current Status (Post-Refactoring)" section.
-   `CHANGELOG.md`: This file, to track changes moving forward.

### Changed
-   **`scripts/setup/install_dependencies.ps1`**:
    -   Consolidated previously duplicated functions: `Install-RequiredModules`, `Connect-ZeroTrustServices`, and `Initialize-ZeroTrustEnvironment`.
    -   `Install-RequiredModules` now has more robust module checking, installation, and update logic.
    -   `Connect-ZeroTrustServices` now attempts actual connections to Azure and Microsoft Graph, removing mock logic and setting global status variables.
-   **Core Engine De-stubbing**: Replaced placeholder stubs in the following PowerShell classes with functional mock implementations. These mocks log their execution and parameters, and return appropriate data structures, enabling testing of workflows:
    -   `src/hunting/threat_hunter.ps1` (numerous private methods)
    -   `src/response/response_orchestrator.ps1` (numerous private methods)
    -   `src/intelligence/threat_intelligence_manager.ps1` (numerous private methods)
-   **`src/automation/SecurityIncidentResponder.ps1`**:
    -   De-stubbed numerous private methods related to response actions, incident documentation, and reporting helpers with functional mock implementations.
    -   File renamed from `Security_Incident_Responder.ps1` to `SecurityIncidentResponder.ps1` for naming consistency.
-   **`src/automation/SecurityIncidentResponder.tests.ps1`**:
    -   Refactored `BeforeEach` setup to use direct injection of mock dependencies instead of mocking `New-Object`.
    -   Improved the test for the `InvokeBasicRestMethod` action to mock `Invoke-RestMethod` itself and verify parameters.
    -   Added new test contexts and `It` blocks for `TriggerAutomatedResponse` and `GenerateIncidentReport` to cover interactions with newly de-stubbed methods.
-   **`config/installation.json`**:
    -   Removed the general placeholder comment.
    -   Added a `TenantId_HelpText` property to guide users on configuring the `TenantId`.
-   **`README.md`**:
    -   Significantly updated the "Installation" section to reflect new scripts and a clearer setup flow.

### Fixed
-   Resolved issue of `scripts/setup/Initialize-Environment.ps1` being documented but not existing.
-   Setup scripts `Initialize-SecurityBaselines.ps1` and `Initialize-SecurityMonitoring.ps1` now create their respective JSON configuration files (`security_baselines.json`, `monitoring_settings.json`) if they are missing, preventing errors in `Test-Installation.ps1`.
-   `Initialize-Environment.ps1` now creates `config/privileged_users.json` if missing.
-   Corrected path for `SecurityIncidentResponder.ps1` in `SecurityIncidentResponder.tests.ps1` after rename.

### Removed
-   Redundant function definitions from `scripts/setup/install_dependencies.ps1`.
-   Original placeholder comment from `config/installation.json`.
