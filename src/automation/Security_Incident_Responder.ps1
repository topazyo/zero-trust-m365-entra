class SecurityIncidentResponder {
    [string]$TenantId
    [hashtable]$SecurityPlaybooks
    [System.Collections.Generic.Dictionary[string,object]]$ActiveIncidents
    # hidden [object]$AutomationEngine # Removed old
    # hidden [object]$ForensicEngine # Removed old

    # Added Typed Engine Properties
    hidden [ThreatHunter]$ForensicEngine
    hidden [ResponseOrchestrator]$AutomationEngine
    hidden [PlaybookManager]$PlaybookManager
    hidden [ThreatIntelligenceManager]$ThreatIntelClient

    SecurityIncidentResponder([string]$tenantId) {
        $this.TenantId = $tenantId
        $this.ActiveIncidents = [System.Collections.Generic.Dictionary[string,object]]::new()
        $this._InitializeEngines() # Corrected call
        $this._LoadSecurityPlaybooks() # Corrected call
    }

    [void]HandleSecurityIncident([object]$incident) {
        try {
            # Create and store incident context
            $context = $this._CreateIncidentContext($incident) # Corrected call
            $this.ActiveIncidents[$incident.Id] = $context
            $context.Classification = $this._ClassifyIncident($incident) # Corrected call & store classification

            # Classify incident and select playbook
            # $classification = $this._ClassifyIncident($incident) # Already called and stored in context
            $playbook = $this._SelectPlaybook($context.Classification) # Corrected call, use context's classification
            
            if ($null -eq $playbook) {
                Write-Warning "No playbook selected for incident $($incident.Id) with classification '$($context.Classification)'. No further playbook actions will be executed by HandleSecurityIncident."
            } else {
                Write-Host "Executing playbook '$($playbook.name)' for incident $($incident.Id)"
                $this.ExecutePlaybook($playbook, $context) # ExecutePlaybook is public, calls _ExecuteAction internally
            }
            
            # Trigger automated response based on classification
            $this.TriggerAutomatedResponse($context.Classification, $context) # TriggerAutomatedResponse is public, calls _methods internally
            
            # Perform forensic analysis
            $this.InitiateForensicAnalysis($incident.Id) # InitiateForensicAnalysis is public, calls _methods internally
            
            # Document and report
            $this._DocumentIncidentResponse($incident, $context) # Corrected call
        }
        catch {
            Write-Error "Failed to handle security incident $($incident.Id): $($_.Exception.Message)" # Added incident ID to error
            $this._EscalateIncident($incident) # Corrected call
            # Consider re-throwing if critical: throw
        }
    }

    [hashtable]ExecutePlaybook([object]$playbook, [object]$context) {
        $context.ExecutionStart = [DateTime]::UtcNow
        $context.Actions = @()

        foreach ($action in $playbook.steps) { # Changed from $playbook.Actions to $playbook.steps
            try {
                $actionResult = $this._ExecuteAction($action, $context) # Corrected call
                $this._ValidateActionResult($actionResult) # Corrected call
                
                $context.Actions += @{
                    Type = $action.actionType # Corrected from $action.Type
                    Result = $actionResult
                    Status = $actionResult.Status # Corrected from "Completed"
                    Timestamp = [DateTime]::UtcNow
                    ValidationStatus = "Verified" # Assuming stub validation
                }
                
                $this._UpdateIncidentContext($context, $actionResult) # Corrected call to use underscore
            }
            catch {
                $this._HandleActionFailure($action, $context) # Corrected call
                $context.Actions += @{
                    Type = $action.actionType # Corrected to use actionType from playbook step
                    Error = $_.Exception.Message
                    Status = "FailedInFramework" # More specific status
                    Timestamp = [DateTime]::UtcNow
                }
            }
        }

        return $context
    }

    [void]TriggerAutomatedResponse([string]$triggerType, [object]$context) {
        switch ($triggerType) {
            "AccountCompromise" {
                $this._IsolateCompromisedAccount($context) # Corrected call
                $this._InitiateForensicCollection($context) # Corrected call
                $this._NotifySecurityTeam($context) # Corrected call
            }
            "DataExfiltration" {
                $this._BlockDataTransfer($context) # Corrected call
                $this._RevokeSessions($context) # Corrected call
                $this._InitiateDLP($context) # Corrected call
            }
            "MalwareDetection" {
                $this._IsolateInfectedSystems($context) # Corrected call
                $this._InitiateAntimalwareScan($context) # Corrected call
                $this._CollectMalwareSamples($context) # Corrected call
            }
            default {
                $this._ExecuteDefaultResponse($context) # Corrected call
            }
        }
    }

    [hashtable]GenerateIncidentReport([string]$incidentId) {
        $incident = $this.ActiveIncidents[$incidentId]
        
        return @{
            IncidentId = $incidentId
            Classification = $incident.Classification # Should be $incidentContext.Classification
            Timeline = $this._CreateIncidentTimeline($incident) # Pass $incidentContext
            Actions = $incident.Actions # Should be $incidentContext.Actions
            Impact = $this._AssessIncidentImpact($incident) # Pass $incidentContext
            Containment = $this._GetContainmentStatus($incident) # Pass $incidentContext
            Remediation = $this._GetRemediationStatus($incident) # Pass $incidentContext
            ForensicFindings = $this._GetForensicFindings($incidentId)
            ThreatIntelligence = $this._GetRelatedThreatIntel($incidentId)
            LessonsLearned = $this._CompileLessonsLearned($incident) # Pass $incidentContext
            Metrics = $this._CalculateResponseMetrics($incident) # Pass $incidentContext
        }
    }

    [void]InitiateForensicAnalysis([string]$incidentId) {
        try {
            $forensicData = $this._CollectForensicData($incidentId) # Corrected call
            $analysis = $this._AnalyzeForensicData($forensicData) # Corrected call
            $iocs = $this._IdentifyIOCs($analysis) # Corrected call
            
            # Update threat intelligence and incident context
            $this._UpdateThreatIntelligence($iocs) # Corrected call
            $this.ActiveIncidents[$incidentId].ForensicFindings = $analysis
            $this.ActiveIncidents[$incidentId].IdentifiedIOCs = $iocs
            
            # Generate forensic report
            $this._GenerateForensicReport($incidentId, $analysis) # Corrected call
        }
        catch {
            Write-Error "Forensic analysis failed: $_"
            $this.ActiveIncidents[$incidentId].ForensicStatus = "Failed"
            throw
        }
    }

    # --- Start of Hidden Method Stubs (from e2649) ---
    hidden [void] _InitializeEngines() {
        Write-Host "SecurityIncidentResponder._InitializeEngines() (enhanced) called."
        $this.ForensicEngine = New-Object ThreatHunter -ArgumentList $this.TenantId
        $this.AutomationEngine = New-Object ResponseOrchestrator -ArgumentList $this.TenantId
        $this.PlaybookManager = New-Object PlaybookManager
        $this.ThreatIntelClient = New-Object ThreatIntelligenceManager -ArgumentList $this.TenantId
        Write-Host "Engines (ThreatHunter, ResponseOrchestrator, PlaybookManager, ThreatIntelClient) instantiated."
    }
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
    hidden [object] _CreateIncidentContext([object]$incident) { Write-Host "SIR Stub: _CreateIncidentContext"; return @{} }
    hidden [string] _ClassifyIncident([object]$incident) {
        Write-Host "SecurityIncidentResponder._ClassifyIncident() (enhanced) called for incident: $($incident.Id)"
        # More sophisticated classification
        $title = $incident.Title
        $description = $incident.Description # Assuming incident object has Description

        if ($null -ne $title -and $title -match 'Malware') { return "MalwareDetection" }
        if ($null -ne $description -and $description -match 'Malware') { return "MalwareDetection" }
        if ($null -ne $title -and $title -match 'Compromise') { return "AccountCompromise" }
        if ($null -ne $description -and $description -match 'Compromised account') { return "AccountCompromise" }
        if ($null -ne $title -and $title -match 'Exfiltration') { return "DataExfiltration" }
        if ($null -ne $description -and $description -match 'Data loss') { return "DataExfiltration" }
        if ($null -ne $title -and $title -match 'Phishing') { return "PhishingAttempt" }
        if ($null -ne $description -and $description -match 'Phishing attempt') { return "PhishingAttempt" }

        Write-Host "Incident '$($incident.Id)' ('$title') could not be specifically classified, defaulting to 'Unclassified'."
        return "Unclassified"
    }
    hidden [object] _SelectPlaybook([string]$classification) {
        Write-Host "SecurityIncidentResponder._SelectPlaybook() (enhanced) called for classification: $classification"
        if ($null -eq $this.PlaybookManager -or $null -eq $this.SecurityPlaybooks) {
            Write-Warning "_SelectPlaybook: PlaybookManager or SecurityPlaybooks not initialized/populated!"
            return $null
        }

        foreach($pbName in $this.SecurityPlaybooks.Keys) {
            $pb = $this.SecurityPlaybooks[$pbName]
            if ($pb.defaultClassification -contains $classification) {
                Write-Host "Selected playbook '$pbName' for classification '$classification' based on defaultClassification."
                return $pb
            }
        }

        $selectedPlaybookByName = $this.PlaybookManager.GetPlaybook($classification)
        if ($selectedPlaybookByName) {
            Write-Host "Selected playbook '$($selectedPlaybookByName.name)' for classification '$classification' by name."
            return $selectedPlaybookByName
        }

        Write-Warning "Playbook for classification '$classification' not found by name or defaultClassification, attempting 'DefaultPlaybookFromFile'."
        $defaultPb = $this.PlaybookManager.GetPlaybook("DefaultPlaybookFromFile")
        if ($defaultPb) { return $defaultPb }

        if ($this.SecurityPlaybooks.Count -gt 0) {
            Write-Warning "Falling back to the first loaded playbook in SecurityPlaybooks."
            return $this.SecurityPlaybooks.GetEnumerator()[0].Value
        }
        Write-Error "No playbooks available to select, and DefaultPlaybookFromFile also not found."
        return $null
    }
    hidden [void] _DocumentIncidentResponse([object]$incident, [object]$context) { Write-Host "SIR Stub: _DocumentIncidentResponse" }
    hidden [void] _EscalateIncident([object]$incident) { Write-Host "SIR Stub: _EscalateIncident" }
    hidden [object] _ExecuteAction([object]$action, [object]$context) {
        Write-Host "SecurityIncidentResponder._ExecuteAction() (enhanced) called for action type: $($action.actionType)"
        $actionType = $action.actionType
        $parameters = $action.parameters
        $result = @{ Status = "Failed"; Output = "Action type '$actionType' not implemented or failed."; StartTime = (Get-Date)}

        try {
            switch ($actionType) {
                "LogMessage" {
                    $level = $this.GetOrElse($parameters.level, "Info") # Corrected call
                    $message = $this.GetOrElse($parameters.message, "No message provided for LogMessage action.") # Corrected call
                    Write-Host "[$level] Playbook Action Log: $message (Incident: $($context.IncidentId))"
                    $result.Status = "Success"; $result.Output = "Logged message: $message"
                }
                "TagIncident" {
                    if (-not $context.PSObject.Properties.Name -contains 'Tags' -or $null -eq $context.Tags) {
                        $context.Tags = [System.Collections.Generic.List[string]]::new()
                    }
                    $tagName = $this.GetOrElse($parameters.tagName, "DefaultTag") # Corrected call
                    $context.Tags.Add($tagName)
                    Write-Host "Tagged incident $($context.IncidentId) with '$tagName'."
                    $result.Status = "Success"; $result.Output = "Tagged with: $tagName. Current tags: $($context.Tags -join ', ')"
                }
                "InvokeBasicRestMethod" {
                    $uri = $parameters.uri
                    $method = $this.GetOrElse($parameters.method, "GET") # Corrected call
                    $body = $parameters.body
                    Write-Host "Mock REST Call: Would invoke $method to $uri"
                    if ($body) { Write-Host ("With body: " + ($body | ConvertTo-Json -Compress -Depth 3)) }
                    $result.Status = "Success"; $result.Output = "Mocked REST call to $uri performed."
                }
                default { Write-Warning "Unknown action type: $actionType"; $result.Output = "Unknown action type: $actionType" }
            }
        } catch {
            Write-Error "Error executing action $actionType for incident $($context.IncidentId): $($_.Exception.Message)"
            $result.Status = "Error"; $result.Output = "Exception: $($_.Exception.Message)"; $result.ErrorRecord = $_
        }
        $result.EndTime = (Get-Date); $result.Duration = $result.EndTime - $result.StartTime
        return $result
    }

    hidden [object] GetOrElse($value, $default) { # Renamed method
        if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrEmpty($value))) { return $default }
        return $value
    }
    hidden [void] _ValidateActionResult([object]$actionResult) { Write-Host "SIR Stub: _ValidateActionResult" }
    hidden [void] _UpdateIncidentContext([object]$context, [object]$actionResult) { Write-Host "SIR Stub: _UpdateIncidentContext" }
    hidden [void] _HandleActionFailure([object]$action, [object]$context) { Write-Host "SIR Stub: _HandleActionFailure" }
    hidden [void] _IsolateCompromisedAccount([object]$context) { Write-Host "SIR Stub: _IsolateCompromisedAccount" }
    hidden [void] _InitiateForensicCollection([object]$context) { Write-Host "SIR Stub: _InitiateForensicCollection" }
    hidden [void] _NotifySecurityTeam([object]$context) { Write-Host "SIR Stub: _NotifySecurityTeam" }
    hidden [void] _BlockDataTransfer([object]$context) { Write-Host "SIR Stub: _BlockDataTransfer" }
    hidden [void] _RevokeSessions([object]$context) { Write-Host "SIR Stub: _RevokeSessions" }
    hidden [void] _InitiateDLP([object]$context) { Write-Host "SIR Stub: _InitiateDLP" }
    hidden [void] _IsolateInfectedSystems([object]$context) { Write-Host "SIR Stub: _IsolateInfectedSystems" }
    hidden [void] _InitiateAntimalwareScan([object]$context) { Write-Host "SIR Stub: _InitiateAntimalwareScan" }
    hidden [void] _CollectMalwareSamples([object]$context) { Write-Host "SIR Stub: _CollectMalwareSamples" }
    hidden [void] _ExecuteDefaultResponse([object]$context) { Write-Host "SIR Stub: _ExecuteDefaultResponse" }
    hidden [object] _CreateIncidentTimeline([object]$incidentContext) { Write-Host "SIR Stub: _CreateIncidentTimeline"; return @() }
    hidden [object] _AssessIncidentImpact([object]$incidentContext) { Write-Host "SIR Stub: _AssessIncidentImpact"; return @{} }
    hidden [string] _GetContainmentStatus([object]$incidentContext) { Write-Host "SIR Stub: _GetContainmentStatus"; return "Pending" }
    hidden [string] _GetRemediationStatus([object]$incidentContext) { Write-Host "SIR Stub: _GetRemediationStatus"; return "Pending" }
    hidden [object] _GetForensicFindings([string]$incidentId) { Write-Host "SIR Stub: _GetForensicFindings"; return @{} }
    hidden [object] _GetRelatedThreatIntel([string]$incidentId) {
        Write-Host "SIR._GetRelatedThreatIntel() now calling `$this.ThreatIntelClient.GetRelatedThreatIntel for $incidentId"
        if ($null -eq $this.ThreatIntelClient) { Write-Error "ThreatIntelClient not initialized!"; return $null }
        return $this.ThreatIntelClient.GetRelatedThreatIntel($incidentId)
    }
    hidden [object] _CompileLessonsLearned([object]$incidentContext) { Write-Host "SIR Stub: _CompileLessonsLearned"; return @{} }
    hidden [object] _CalculateResponseMetrics([object]$incidentContext) { Write-Host "SIR Stub: _CalculateResponseMetrics"; return @{} }
    hidden [object] _CollectForensicData([string]$incidentId) {
        Write-Host "SIR._CollectForensicData() now calling `$this.ForensicEngine.CollectForensicData for $incidentId"
        if ($null -eq $this.ForensicEngine) { Write-Error "ForensicEngine not initialized!"; return $null }
        return $this.ForensicEngine.CollectForensicData($incidentId)
    }
    hidden [object] _AnalyzeForensicData([object]$forensicData) { Write-Host "SIR Stub: _AnalyzeForensicData"; return @{} }
    hidden [array] _IdentifyIOCs([object]$analysis) { Write-Host "SIR Stub: _IdentifyIOCs"; return @() }
    hidden [void] _UpdateThreatIntelligence([array]$iocs) {
        Write-Host "SIR._UpdateThreatIntelligence() now calling `$this.ThreatIntelClient.UpdateThreatIntelligence"
        if ($null -eq $this.ThreatIntelClient) { Write-Error "ThreatIntelClient not initialized!"; return }
        $this.ThreatIntelClient.UpdateThreatIntelligence($iocs)
    }
    hidden [void] _GenerateForensicReport([string]$incidentId, [object]$analysis) { Write-Host "SIR Stub: _GenerateForensicReport" }
    # --- End of Hidden Method Stubs ---
}