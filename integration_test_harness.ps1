Write-Host "Starting Integration Test Harness for SecurityIncidentResponder..."
Write-Host "------------------------------------------------------------------"
# Explicitly source known base classes/dependencies first
Write-Host "Sourcing critical dependencies..."
. ./src/playbook/PlaybookManager.ps1
. ./src/hunting/threat_hunter.ps1
. ./src/response/response_orchestrator.ps1
. ./src/intelligence/threat_intelligence_manager.ps1

# Then source the main class for the test
Write-Host "Sourcing SecurityIncidentResponder..."
. ./src/automation/Security_Incident_Responder.ps1

# Source any other remaining .ps1 files in src, excluding tests and already loaded files
Write-Host "Sourcing remaining modules..."
$alreadyLoaded = @(
    "./src/playbook/PlaybookManager.ps1",
    "./src/hunting/threat_hunter.ps1",
    "./src/response/response_orchestrator.ps1",
    "./src/intelligence/threat_intelligence_manager.ps1",
    "./src/automation/Security_Incident_Responder.ps1"
)
# Normalize paths for comparison: $PWD.Path might be /app, FullName might be /app/src/...
Get-ChildItem -Path "./src/**/*.ps1" -Recurse -Exclude "*.tests.ps1" | Where-Object {
    $normalizedFullName = $_.FullName.Replace($PWD.Path + '/', './')
    $alreadyLoaded -notcontains $normalizedFullName
} | ForEach-Object {
    Write-Host "Sourcing (remaining): $($_.FullName)"
    . $_.FullName
}
Write-Host "All source modules sourced."
Write-Host "------------------------------------------------------------------"
# Setup
$tenantId = "IntegrationTestTenant"
$sir = $null
$incidentId = "INTEG-001"
try {
    Write-Host "Instantiating SecurityIncidentResponder..."
    $sir = New-Object SecurityIncidentResponder -ArgumentList $tenantId
    Write-Host "SecurityIncidentResponder instantiated successfully."
    Write-Host "  PlaybookManager type: $($sir.PlaybookManager.GetType().FullName)"
    Write-Host "  ForensicEngine type: $($sir.ForensicEngine.GetType().FullName)"
    Write-Host "  ThreatIntelClient type: $($sir.ThreatIntelClient.GetType().FullName)"
    Write-Host "  AutomationEngine type: $($sir.AutomationEngine.GetType().FullName)"
    Write-Host "------------------------------------------------------------------"
    # Create a sample incident that should trigger malware_playbook.json
    $sampleIncident = @{
        Id = $incidentId
        Title = "Critical Malware Detected on Server X"
        Description = "A severe malware infection (WannaCry variant) was found on Server X (server-critical-007)."
        Severity = "Critical"
        SourceSystem = "EDR"
        # Adding a property that might be used by a playbook step (e.g. InvokeBasicRestMethod in malware_playbook.json)
        DeviceId = "server-critical-007"
    }
    Write-Host "Sample Incident created for ID: $incidentId"
    Write-Host ($sampleIncident | Format-List | Out-String)
    Write-Host "------------------------------------------------------------------"
    Write-Host "Calling HandleSecurityIncident..."
    $sir.HandleSecurityIncident($sampleIncident)
    Write-Host "HandleSecurityIncident call completed."
    Write-Host "------------------------------------------------------------------"
    Write-Host "Calling GenerateIncidentReport..."
    $report = $sir.GenerateIncidentReport($incidentId)
    Write-Host "GenerateIncidentReport call completed."
    if ($report) {
        Write-Host "--- Incident Report Summary for $incidentId ---"
        Write-Host "Classification: $($report.Classification)"
        Write-Host "Timeline Events:"
        $report.Timeline | ForEach-Object { Write-Host "  - $($_.Timestamp) : $($_.Event)" }
        Write-Host "Actions Taken Count: $($report.Actions.Count)"
        if ($report.Actions.Count -gt 0) {
            $report.Actions | ForEach-Object { Write-Host ("  - Action: $($_.Type), Status: $($_.Status), Output: " + ($_.Result.Output -replace "`r?`n"," ")) }
        }
        Write-Host "Impact Assessment: Severity: $($report.Impact.Severity), Scope: $($report.Impact.Scope)"
        # Adjust property access based on actual structure returned by mocks
        if ($report.ForensicFindings -is [hashtable]) {
            Write-Host "Forensic Findings Summary: $($report.ForensicFindings.ForensicData)"
        } else {
             Write-Host "Forensic Findings Summary: $($report.ForensicFindings)" # if it's a simple string
        }
        if ($report.ThreatIntelligence -is [hashtable]) {
            Write-Host "Threat Intel Summary: $($report.ThreatIntelligence.Intel)"
        } else {
            Write-Host "Threat Intel Summary: $($report.ThreatIntelligence)" # if it's a simple string
        }
        Write-Host "------------------------------------------------------------------"
    } else {
        Write-Warning "GenerateIncidentReport returned null or empty."
    }
} catch {
    Write-Error "An error occurred during the integration test harness:"
    Write-Error $_.Exception.Message
    Write-Error "Script StackTrace: $($_.ScriptStackTrace)"
    Write-Host "------------------------------------------------------------------"
}
Write-Host "Integration Test Harness finished."
