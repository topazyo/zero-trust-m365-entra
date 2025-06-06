# Part 1: Create PlaybookManager
New-Item -ItemType Directory -Path "src/playbook" -Force
Write-Host "Created directory src/playbook"

# Using single-quoted here-string for Set-Content to avoid needing to escape $ within PlaybookManager.ps1 content
Set-Content -Path "src/playbook/PlaybookManager.ps1" -Value @'
class PlaybookManager {
    [hashtable]$LoadedPlaybooks

    PlaybookManager() {
        $this.LoadedPlaybooks = @{}
        Write-Host "PlaybookManager instantiated."
    }

    [void] LoadPlaybooks([string]$directoryPath) {
        Write-Host "PlaybookManager.LoadPlaybooks called for directory: $directoryPath (stubbed - will be enhanced)"
        # Stub implementation, to be replaced in Part 4
        $this.LoadedPlaybooks = @{
            "DefaultPlaybook" = @{
                "name" = "Default Incident Response Playbook";
                "description" = "Placeholder playbook from PlaybookManager stub.";
                "version" = "1.0";
                "defaultClassification" = @("Unclassified");
                "steps" = @(
                    @{ "id" = "step1"; "name" = "Log Default Incident"; "actionType" = "LogMessage"; "parameters" = @{ "message" = "Incident logged by default playbook (via PlaybookManager)." }; "level" = "Info" }
                )
            }
            "MalwarePlaybook" = @{ # For _ClassifyIncident to potentially pick
                "name" = "Basic Malware Response Playbook";
                "description" = "Handles basic malware alerts.";
                "version" = "1.0";
                "defaultClassification" = @("MalwareDetection");
                 "steps" = @(
                    @{ "id" = "mstep1"; "name" = "Log Malware Detection"; "actionType" = "LogMessage"; "parameters" = @{ "message" = "Malware detected. Incident escalated by playbook." }; "level" = "Warning" },
                    @{ "id" = "mstep2"; "name" = "Tag Malware Incident"; "actionType" = "TagIncident"; "parameters" = @{ "tagName" = "MalwareAlert" } }
                )
            }
        }
    }

    [object] GetPlaybook([string]$playbookName) {
        Write-Host "PlaybookManager.GetPlaybook called for: $playbookName"
        if ($this.LoadedPlaybooks.ContainsKey($playbookName)) {
            return $this.LoadedPlaybooks[$playbookName]
        }
        Write-Warning "Playbook '$playbookName' not found by PlaybookManager."
        return $null
    }
}
'@
Write-Host "Created src/playbook/PlaybookManager.ps1"

# Part 2: Modify SecurityIncidentResponder.ps1
$sirPath = "src/automation/Security_Incident_Responder.ps1" # No backtick here
$sirContent = Get-Content $sirPath -Raw # No backtick here

# 2.1 Add engine properties
# Using single-quoted here-string
$engineProperties = @'
    hidden [ThreatHunter]$ForensicEngine
    hidden [ResponseOrchestrator]$AutomationEngine # Using ResponseOrchestrator as AutomationEngine for now
    hidden [PlaybookManager]$PlaybookManager
    hidden [ThreatIntelligenceManager]$ThreatIntelClient
'@
# More robust insertion after 'class SecurityIncidentResponder {'
if ($sirContent -match '(?m)(class SecurityIncidentResponder\s*\{)') {
    $classOpeningMatch = $Matches[0]
    $indentedEngineProperties = $engineProperties.Split([Environment]::NewLine) | ForEach-Object { "    $_" } # Ensure $_ is correctly interpreted
    $sirContent = $sirContent -replace ([regex]::Escape($classOpeningMatch)), ("$classOpeningMatch`n" + ($indentedEngineProperties -join [Environment]::NewLine))
    Write-Host "Added engine properties to SIR content."
} else {
    Write-Warning "Could not find 'class SecurityIncidentResponder {' opening to add engine properties."
}

# 2.2 Update _InitializeEngines
# Using single-quoted here-string
$newInitializeEngines = @'
    hidden [void] _InitializeEngines() {
        Write-Host "SecurityIncidentResponder._InitializeEngines() (enhanced) called."
        $this.ForensicEngine = New-Object ThreatHunter -ArgumentList $this.TenantId
        $this.AutomationEngine = New-Object ResponseOrchestrator -ArgumentList $this.TenantId
        $this.PlaybookManager = New-Object PlaybookManager
        $this.ThreatIntelClient = New-Object ThreatIntelligenceManager -ArgumentList $this.TenantId
        Write-Host "Engines (ThreatHunter, ResponseOrchestrator, PlaybookManager, ThreatIntelClient) instantiated."
    }
'@
$sirContent = $sirContent -replace '(?s)hidden \[void\] _InitializeEngines\(\) \{.*?`n    \}', $newInitializeEngines
Write-Host "Updated _InitializeEngines in SIR content."

# 2.3 Update _LoadSecurityPlaybooks
$newLoadSecurityPlaybooks = @'
    hidden [void] _LoadSecurityPlaybooks() {
        Write-Host "SecurityIncidentResponder._LoadSecurityPlaybooks() (enhanced) called."
        if ($null -eq $this.PlaybookManager) {
            Write-Warning "_LoadSecurityPlaybooks: PlaybookManager not initialized!"
            return
        }
        $this.PlaybookManager.LoadPlaybooks("./playbooks")
        $this.SecurityPlaybooks = $this.PlaybookManager.LoadedPlaybooks
        Write-Host "Playbooks loaded via PlaybookManager. Total playbooks: $($this.SecurityPlaybooks.Count)"
    }
'@
$sirContent = $sirContent -replace '(?s)hidden \[void\] _LoadSecurityPlaybooks\(\) \{.*?`n    \}', $newLoadSecurityPlaybooks
Write-Host "Updated _LoadSecurityPlaybooks in SIR content."

# 2.4 Update _SelectPlaybook
$newSelectPlaybook = @'
    hidden [object] _SelectPlaybook([string]$classification) {
        Write-Host "SecurityIncidentResponder._SelectPlaybook() (enhanced) called for classification: $classification"
        if ($null -eq $this.PlaybookManager) {
            Write-Warning "_SelectPlaybook: PlaybookManager not initialized!"
            if ($this.SecurityPlaybooks -and $this.SecurityPlaybooks.ContainsKey("DefaultPlaybook")) {
                 return $this.SecurityPlaybooks["DefaultPlaybook"]
            }
            return $null
        }
        if ($this.SecurityPlaybooks) {
            foreach($pbName in $this.SecurityPlaybooks.Keys) {
                $pb = $this.SecurityPlaybooks[$pbName]
                if ($pb.defaultClassification -contains $classification) {
                    Write-Host "Selected playbook '$pbName' for classification '$classification' based on defaultClassification."
                    return $pb
                }
            }
        }
        $selectedPlaybook = $this.PlaybookManager.GetPlaybook($classification)
        if ($selectedPlaybook) {
            return $selectedPlaybook
        }
        Write-Warning "Playbook for classification '$classification' not found, defaulting to 'DefaultPlaybook'."
        return $this.PlaybookManager.GetPlaybook("DefaultPlaybook")
    }
'@
$sirContent = $sirContent -replace '(?s)hidden \[object\] _SelectPlaybook\(\[string\]\$classification\) \{.*?`n    \}', $newSelectPlaybook
Write-Host "Updated _SelectPlaybook in SIR content."

# 2.5 Update calls to use engine properties (replacing implementations)
$collectForensicDataImpl = @'
    hidden [object] _CollectForensicData([string]$incidentId) {
        Write-Host "SIR._CollectForensicData() now calling $this.ForensicEngine.CollectForensicData"
        if ($null -eq $this.ForensicEngine) { Write-Error "ForensicEngine not initialized!"; return $null }
        return $this.ForensicEngine.CollectForensicData($incidentId)
    }
'@
$sirContent = $sirContent -replace '(?s)hidden \[object\] _CollectForensicData\(\[string\]\$incidentId\) \{.*?`n    \}', $collectForensicDataImpl

$updateThreatIntelImpl = @'
    hidden [void] _UpdateThreatIntelligence([array]$iocs) {
        Write-Host "SIR._UpdateThreatIntelligence() now calling $this.ThreatIntelClient.UpdateThreatIntelligence"
        if ($null -eq $this.ThreatIntelClient) { Write-Error "ThreatIntelClient not initialized!"; return }
        $this.ThreatIntelClient.UpdateThreatIntelligence($iocs)
    }
'@
$sirContent = $sirContent -replace '(?s)hidden \[void\] _UpdateThreatIntelligence\(\[array\]\$iocs\) \{.*?`n    \}', $updateThreatIntelImpl

$getRelatedThreatIntelImpl = @'
    hidden [object] _GetRelatedThreatIntel([string]$incidentId) {
        Write-Host "SIR._GetRelatedThreatIntel() now calling $this.ThreatIntelClient.GetRelatedThreatIntel"
        if ($null -eq $this.ThreatIntelClient) { Write-Error "ThreatIntelClient not initialized!"; return $null }
        return $this.ThreatIntelClient.GetRelatedThreatIntel($incidentId)
    }
'@
$sirContent = $sirContent -replace '(?s)hidden \[object\] _GetRelatedThreatIntel\(\[string\]\$incidentId\) \{.*?`n    \}', $getRelatedThreatIntelImpl
Write-Host "Updated SIR methods to delegate to engines."

Set-Content -Path $sirPath -Value $sirContent
Write-Host "Modified $sirPath successfully."

# Part 3: Create Sample Playbook Files
New-Item -ItemType Directory -Path "playbooks" -Force
Write-Host "Created directory playbooks/"

Set-Content -Path "playbooks/default_playbook.json" -Value @'
{
  "name": "DefaultPlaybookFromFile",
  "description": "Default playbook loaded from file for unclassified incidents.",
  "version": "1.0.1",
  "defaultClassification": ["Unclassified", "Default"],
  "steps": [
    {
      "id": "default_step1",
      "name": "Log Unclassified Incident",
      "actionType": "LogMessage",
      "parameters": { "message": "Unclassified incident handled by DefaultPlaybookFromFile.", "level": "Info" },
      "onSuccess": "default_step2"
    },
    {
      "id": "default_step2",
      "name": "Tag Unclassified Incident",
      "actionType": "TagIncident",
      "parameters": { "tagName": "NeedsManualReview" }
    }
  ]
}
'@
Write-Host "Created playbooks/default_playbook.json"

Set-Content -Path "playbooks/malware_playbook.json" -Value @'
{
  "name": "MalwareResponsePlaybookFromFile",
  "description": "Basic response playbook for malware alerts, loaded from file.",
  "version": "1.0.1",
  "defaultClassification": ["MalwareDetection"],
  "steps": [
    {
      "id": "malware_step1",
      "name": "Log Malware Alert",
      "actionType": "LogMessage",
      "parameters": { "message": "High Severity: Malware detected. Executing MalwareResponsePlaybookFromFile.", "level": "Critical" },
      "onSuccess": "malware_step2"
    },
    {
      "id": "malware_step2",
      "name": "Tag For Isolation",
      "actionType": "TagIncident",
      "parameters": { "tagName": "PendingIsolation_Malware" },
      "onSuccess": "malware_step3"
    },
    {
      "id": "malware_step3",
      "name": "Mock Invoke External System",
      "actionType": "InvokeBasicRestMethod",
      "parameters": {
        "uri": "https://api.example.com/quarantine",
        "method": "POST",
        "body": { "deviceId": "%%incident.deviceId%%", "reason": "Malware" }
      }
    }
  ]
}
'@
Write-Host "Created playbooks/malware_playbook.json"

# Part 4: Enhance PlaybookManager.LoadPlaybooks
$pmPath = "src/playbook/PlaybookManager.ps1"
$pmContent = Get-Content $pmPath -Raw
$newPMLoadPlaybooks = @'
    [void] LoadPlaybooks([string]$directoryPath) {
        Write-Host "PlaybookManager.LoadPlaybooks (Enhanced) called for directory: $directoryPath"
        $this.LoadedPlaybooks = @{}
        if (-not (Test-Path $directoryPath -PathType Container)) {
            Write-Error "Playbook directory '$directoryPath' not found."
            return
        }
        Get-ChildItem -Path $directoryPath -Filter "*.json" | ForEach-Object {
            Write-Host "Loading playbook from file: $($_.FullName)"
            try {
                $playbookContent = Get-Content -Path $_.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
                if ($null -ne $playbookContent.name) {
                    $this.LoadedPlaybooks[$playbookContent.name] = $playbookContent
                    Write-Host "Successfully loaded playbook: $($playbookContent.name)"
                } else {
                    Write-Warning "Playbook file $($_.Name) does not have a 'name' property."
                }
            } catch {
                Write-Error "Failed to load or parse playbook file $($_.Name): $($_.Exception.Message)"
            }
        }
        Write-Host "PlaybookManager finished loading. Total playbooks: $($this.LoadedPlaybooks.Count)"
    }
'@
$pmContent = $pmContent -replace '(?s)\[void\] LoadPlaybooks\(\[string\]\$directoryPath\) \{.*?`n    \}', $newPMLoadPlaybooks
Set-Content -Path $pmPath -Value $pmContent
Write-Host "Enhanced PlaybookManager.LoadPlaybooks in $pmPath"

# Part 5: Enhance _ClassifyIncident in SecurityIncidentResponder.ps1
$sirContent = Get-Content $sirPath -Raw
$newClassifyIncident = @'
    hidden [string] _ClassifyIncident([object]$incident) {
        Write-Host "SecurityIncidentResponder._ClassifyIncident() (enhanced) called for incident: $($incident.Id)"
        $title = $incident.Title
        $description = $incident.Description

        if ($title -match 'Malware' -or $description -match 'Malware') { return "MalwareDetection" }
        if ($title -match 'Compromise' -or $description -match 'Compromised account') { return "AccountCompromise" }
        if ($title -match 'Exfiltration' -or $description -match 'Data loss') { return "DataExfiltration" }
        if ($title -match 'Phishing' -or $description -match 'Phishing attempt') { return "PhishingAttempt" }

        Write-Host "Incident '$($incident.Id)' ('$title') could not be specifically classified, defaulting to 'Unclassified'."
        return "Unclassified"
    }
'@
$sirContent = $sirContent -replace '(?s)hidden \[string\] _ClassifyIncident\(\[object\]\$incident\) \{.*?`n    \}', $newClassifyIncident
Write-Host "Enhanced _ClassifyIncident in SIR content."
Set-Content -Path $sirPath -Value $sirContent

# Part 6: Implement basic actions in _ExecuteAction in SecurityIncidentResponder.ps1
$sirContent = Get-Content $sirPath -Raw
$newExecuteAction = @'
    hidden [object] _ExecuteAction([object]$action, [object]$context) {
        Write-Host "SecurityIncidentResponder._ExecuteAction() (enhanced) called for action type: $($action.actionType)"
        $actionType = $action.actionType
        $parameters = $action.parameters
        $result = @{ Status = "Failed"; Output = "Action type '$actionType' not implemented or failed."; StartTime = (Get-Date)}

        try {
            switch ($actionType) {
                "LogMessage" {
                    $level = "Info"; if ($parameters.ContainsKey("level") -and $null -ne $parameters.level) { $level = $parameters.level }
                    $message = "No message provided for LogMessage action."; if ($parameters.ContainsKey("message") -and $null -ne $parameters.message) { $message = $parameters.message }
                    Write-Host "[$level] Playbook Action Log: $message (Incident: $($context.IncidentId))"
                    $result.Status = "Success"
                    $result.Output = "Logged message: $message"
                }
                "TagIncident" {
                    if (-not $context.PSObject.Properties.Name -contains 'Tags') {
                        $context | Add-Member -MemberType NoteProperty -Name Tags -Value ([System.Collections.Generic.List[string]]::new())
                    }
                    $tagName = "DefaultTag"; if ($parameters.ContainsKey("tagName") -and $null -ne $parameters.tagName) { $tagName = $parameters.tagName }
                    $context.Tags.Add($tagName)
                    Write-Host "Tagged incident $($context.IncidentId) with '$tagName'."
                    $result.Status = "Success"
                    $result.Output = "Tagged with: $tagName. Current tags: $($context.Tags -join ', ')"
                }
                "InvokeBasicRestMethod" {
                    $uri = $parameters.uri
                    $method = "GET"; if ($parameters.ContainsKey("method") -and $null -ne $parameters.method) { $method = $parameters.method }
                    $body = $parameters.body
                    Write-Host "Mock REST Call: Would invoke $method to $uri"
                    if ($body) { Write-Host "With body: $($body | ConvertTo-Json -Compress -Depth 3)" }

                    $result.Status = "Success" # Mocked as success
                    $result.Output = "Mocked REST call to $uri performed."
                }
                default {
                    Write-Warning "Unknown action type: $actionType"
                    $result.Output = "Unknown action type: $actionType"
                }
            }
        } catch {
            Write-Error "Error executing action $actionType for incident $($context.IncidentId): $($_.Exception.Message)"
            $result.Status = "Error"
            $result.Output = "Exception: $($_.Exception.Message)"
            $result.ErrorRecord = $_
        }
        $result.EndTime = (Get-Date)
        $result.Duration = $result.EndTime - $result.StartTime
        return $result
    }
'@
$sirContent = $sirContent -replace '(?s)hidden \[object\] _ExecuteAction\(\[object\]\$action, \[object\]\$context\) \{.*?`n    \}', $newExecuteAction
Write-Host "Enhanced _ExecuteAction in SIR content (Get-OrElse removed)."

Set-Content -Path $sirPath -Value $sirContent

Write-Host "Subtask 'Implement Core SecurityIncidentResponder Logic (Part 1)' completed (Get-OrElse helper function omitted for now)."
