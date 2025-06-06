Write-Host "Starting Test Harness..."

# Import the main setup script to make its functions available
. ./scripts/setup/install_dependencies.ps1

# Import classes from src (adjust paths as necessary if classes are nested deeper)
Get-ChildItem -Path "./src/**/*.ps1" -Recurse | ForEach-Object {
    Write-Host "Importing module: $_"
    . $_.FullName # Corrected to use FullName property
}

Write-Host "`n--- Testing Initialize-ZeroTrustEnvironment ---"
try {
    Initialize-ZeroTrustEnvironment -ErrorAction Stop
    Write-Host "Initialize-ZeroTrustEnvironment completed."
} catch {
    Write-Error "Initialize-ZeroTrustEnvironment failed: $_"
}

Write-Host "`n--- Testing SecurityIncidentResponder ---"
try {
    $sir = New-Object SecurityIncidentResponder -ArgumentList "TestTenant"
    Write-Host "SecurityIncidentResponder instantiated."

    $mockIncident = @{ Id = "INC001"; Title = "Test Malware Incident"; Severity = "High" }
    $sir.HandleSecurityIncident($mockIncident)
    Write-Host "SIR.HandleSecurityIncident called."

    $sir.GenerateIncidentReport("INC001")
    Write-Host "SIR.GenerateIncidentReport called."
} catch {
    Write-Error "SecurityIncidentResponder test failed: $_"
}

Write-Host "`n--- Testing ThreatIntelligenceManager ---"
try {
    $tim = New-Object ThreatIntelligenceManager -ArgumentList "TestTenant"
    Write-Host "ThreatIntelligenceManager instantiated."
    $tim.ProcessThreatIntelligence()
    Write-Host "TIM.ProcessThreatIntelligence called."
} catch {
    Write-Error "ThreatIntelligenceManager test failed: $_"
}

Write-Host "`n--- Testing ResponseOrchestrator ---"
try {
    $ro = New-Object ResponseOrchestrator -ArgumentList "TestTenant"
    Write-Host "ResponseOrchestrator instantiated."
    $ro.ExecuteAutomatedResponse(@{ TriggerType = "TestTrigger" })
    Write-Host "RO.ExecuteAutomatedResponse called."
} catch {
    Write-Error "ResponseOrchestrator test failed: $_"
}

Write-Host "`n--- Testing ThreatHunter ---"
try {
    $th = New-Object ThreatHunter -ArgumentList "TestTenant"
    Write-Host "ThreatHunter instantiated."
    $th.ExecuteHunt("Hunt001")
    Write-Host "TH.ExecuteHunt called."
} catch {
    Write-Error "ThreatHunter test failed: $_"
}

Write-Host "`n--- Testing AdvancedReportGenerator ---"
try {
    $arg = New-Object AdvancedReportGenerator -ArgumentList "TestTenant"
    Write-Host "AdvancedReportGenerator instantiated."
    $arg.GenerateSecurityReport("DailySummary", (Get-Date).AddDays(-1), (Get-Date))
    Write-Host "ARG.GenerateSecurityReport called."
} catch {
    Write-Error "AdvancedReportGenerator test failed: $_"
}

Write-Host "`nTest Harness finished."
