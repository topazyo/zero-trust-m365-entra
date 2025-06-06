class SecurityIncidentResponder {
    # Engine Properties (Typed)
    hidden [ThreatHunter]$ForensicEngine
    hidden [ResponseOrchestrator]$AutomationEngine
    hidden [PlaybookManager]$PlaybookManager
    hidden [ThreatIntelligenceManager]$ThreatIntelClient

    # Other Class Properties
    [string]$TenantId
    [hashtable]$SecurityPlaybooks
    [System.Collections.Generic.Dictionary[string,object]]$ActiveIncidents

    SecurityIncidentResponder([string]$tenantId) {
        $this.TenantId = $tenantId
        $this.ActiveIncidents = [System.Collections.Generic.Dictionary[string,object]]::new()
        $this._InitializeEngines()
        $this._LoadSecurityPlaybooks()
    }

    # --- Public Methods ---
    [void]HandleSecurityIncident([object]$incident) {
        try {
            $context = $this._CreateIncidentContext($incident)
            $this.ActiveIncidents[$incident.Id] = $context
            $context.Classification = $this._ClassifyIncident($incident)

            $playbook = $this._SelectPlaybook($context.Classification)
            
            if ($null -eq $playbook) {
                Write-Warning "No playbook selected for incident $($incident.Id) with classification '$($context.Classification)'. No further playbook actions will be executed by HandleSecurityIncident."
            } else {
                Write-Host "Executing playbook '$($playbook.name)' for incident $($incident.Id)"
                $this.ExecutePlaybook($playbook, $context)
            }
            
            $this.TriggerAutomatedResponse($context.Classification, $context)
            $this.InitiateForensicAnalysis($incident.Id)
            $this._DocumentIncidentResponse($incident, $context)
        }
        catch {
            Write-Error "Failed to handle security incident $($incident.Id): $($_.Exception.Message)"
            $this._EscalateIncident($incident)
        }
    }

    [hashtable]ExecutePlaybook([object]$playbook, [object]$context) {
        Write-Host "ExecutePlaybook: Starting playbook '$($playbook.name)' for incident '$($context.IncidentId)'"
        # Ensure Actions array is initialized in context
        if (-not $context.PSObject.Properties.Name -contains 'Actions' -or $null -eq $context.Actions) {
             $context.Actions = [System.Collections.Generic.List[object]]::new() # Changed to List for Add method
        }

        if ($null -eq $playbook.steps) {
            Write-Warning "Playbook '$($playbook.name)' has no steps."
            return $context
        }

        foreach ($step in $playbook.steps) {
            try {
                Write-Host "Executing step '$($step.name)' (ActionType: $($step.actionType))"
                $actionResult = $this._ExecuteAction($step, $context)
                $this._ValidateActionResult($actionResult)
                
                $context.Actions.Add(@{ # Use .Add() for List
                    StepId = $step.id
                    Name = $step.name
                    Type = $step.actionType
                    Result = $actionResult
                    Status = $actionResult.Status
                    Timestamp = [DateTime]::UtcNow
                    ValidationStatus = "Verified"
                })
                
                $this._UpdateIncidentContext($context, $actionResult)
                if ($actionResult.Status -ne "Success") {
                    Write-Warning "Action '$($step.name)' did not complete successfully. Status: $($actionResult.Status)"
                }
            }
            catch {
                $this._HandleActionFailure($step, $context)
                $context.Actions.Add(@{ # Use .Add() for List
                    StepId = $step.id
                    Name = $step.name
                    Type = $step.actionType
                    Error = $_.Exception.Message
                    Status = "FailedInFramework"
                    Timestamp = [DateTime]::UtcNow
                })
            }
        }
        Write-Host "ExecutePlaybook: Finished playbook '$($playbook.name)' for incident '$($context.IncidentId)'"
        return $context
    }

    [void]TriggerAutomatedResponse([string]$triggerType, [object]$context) {
        Write-Host "TriggerAutomatedResponse called for type '$triggerType' on incident '$($context.IncidentId)'"
        switch ($triggerType) {
            "AccountCompromise" { $this._IsolateCompromisedAccount($context); $this._InitiateForensicCollection($context); $this._NotifySecurityTeam($context) }
            "DataExfiltration" { $this._BlockDataTransfer($context); $this._RevokeSessions($context); $this._InitiateDLP($context) }
            "MalwareDetection" { $this._IsolateInfectedSystems($context); $this._InitiateAntimalwareScan($context); $this._CollectMalwareSamples($context) }
            default { $this._ExecuteDefaultResponse($context) }
        }
    }

    [hashtable]GenerateIncidentReport([string]$incidentId) {
        Write-Host "GenerateIncidentReport called for incident '$incidentId'"
        $incidentContext = $this.ActiveIncidents[$incidentId]
        if ($null -eq $incidentContext) {
            Write-Warning "No active incident context found for ID '$incidentId'. Cannot generate report."
            return $null
        }
        
        return @{
            IncidentId = $incidentId
            Classification = $incidentContext.Classification
            Timeline = $this._CreateIncidentTimeline($incidentContext)
            Actions = $incidentContext.Actions
            Impact = $this._AssessIncidentImpact($incidentContext)
            Containment = $this._GetContainmentStatus($incidentContext)
            Remediation = $this._GetRemediationStatus($incidentContext)
            ForensicFindings = $this._GetForensicFindings($incidentId)
            ThreatIntelligence = $this._GetRelatedThreatIntel($incidentId)
            LessonsLearned = $this._CompileLessonsLearned($incidentContext)
            Metrics = $this._CalculateResponseMetrics($incidentContext)
        }
    }

    [void]InitiateForensicAnalysis([string]$incidentId) {
        Write-Host "InitiateForensicAnalysis called for incident '$incidentId'"
        try {
            $forensicData = $this._CollectForensicData($incidentId)
            $analysis = $this._AnalyzeForensicData($forensicData)
            $iocs = $this._IdentifyIOCs($analysis)
            
            $this._UpdateThreatIntelligence($iocs)
            
            if ($this.ActiveIncidents.ContainsKey($incidentId)) {
                $this.ActiveIncidents[$incidentId].ForensicFindings = $analysis
                $this.ActiveIncidents[$incidentId].IdentifiedIOCs = $iocs
            }
            $this._GenerateForensicReport($incidentId, $analysis)
        }
        catch {
            Write-Error "Forensic analysis failed for incident '$incidentId': $($_.Exception.Message)"
            if ($this.ActiveIncidents.ContainsKey($incidentId)) {
                $this.ActiveIncidents[$incidentId].ForensicStatus = "Failed"
            }
        }
    }

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
        if ($null -eq $this.PlaybookManager) { Write-Warning "_LoadSecurityPlaybooks: PlaybookManager not initialized!"; return }
        $this.PlaybookManager.LoadPlaybooks("./playbooks"); $this.SecurityPlaybooks = $this.PlaybookManager.LoadedPlaybooks
        Write-Host "Playbooks loaded via PlaybookManager. Total playbooks: $($this.SecurityPlaybooks.Count)"
    }

    hidden [string] _ClassifyIncident([object]$incident) {
        Write-Host "SecurityIncidentResponder._ClassifyIncident() (enhanced) called for incident: $($incident.Id)"
        $title = $incident.Title; $description = $incident.Description
        if (($null -ne $title -and $title -match 'Malware') -or ($null -ne $description -and $description -match 'Malware')) { return "MalwareDetection" }
        if (($null -ne $title -and $title -match 'Compromise') -or ($null -ne $description -and $description -match 'Compromised account')) { return "AccountCompromise" }
        if (($null -ne $title -and $title -match 'Exfiltration') -or ($null -ne $description -and $description -match 'Data loss')) { return "DataExfiltration" }
        if (($null -ne $title -and $title -match 'Phishing') -or ($null -ne $description -and $description -match 'Phishing attempt')) { return "PhishingAttempt" }
        Write-Host "Incident '$($incident.Id)' ('$title') could not be specifically classified, defaulting to 'Unclassified'."
        return "Unclassified"
    }

    hidden [object] _SelectPlaybook([string]$classification) {
        Write-Host "SecurityIncidentResponder._SelectPlaybook() (enhanced) called for classification: $classification"
        if ($null -eq $this.PlaybookManager -or $null -eq $this.SecurityPlaybooks) { Write-Warning "_SelectPlaybook: PlaybookManager or SecurityPlaybooks not initialized/populated!"; return $null }
        foreach($pbName in $this.SecurityPlaybooks.Keys) {
            $pb = $this.SecurityPlaybooks[$pbName]
            if ($pb.defaultClassification -contains $classification) { Write-Host "Selected playbook '$pbName' for classification '$classification' based on defaultClassification."; return $pb }
        }
        $selectedPlaybookByName = $this.PlaybookManager.GetPlaybook($classification)
        if ($selectedPlaybookByName) { Write-Host "Selected playbook '$($selectedPlaybookByName.name)' for classification '$classification' by name."; return $selectedPlaybookByName }
        Write-Warning "Playbook for classification '$classification' not found by name or defaultClassification, attempting 'DefaultPlaybookFromFile'."
        $defaultPb = $this.PlaybookManager.GetPlaybook("DefaultPlaybookFromFile"); if ($defaultPb) { return $defaultPb }
        if ($this.SecurityPlaybooks.Count -gt 0) { Write-Warning "Falling back to the first loaded playbook in SecurityPlaybooks."; return $this.SecurityPlaybooks.GetEnumerator()[0].Value }
        Write-Error "No playbooks available to select."; return $null
    }

    hidden [object] _ExecuteAction([object]$action, [object]$context) {
        Write-Host "SecurityIncidentResponder._ExecuteAction() (Corrected for RunPSScript & Logging) called for action type: $($action.actionType)"
        Write-Host "Context received by _ExecuteAction (IncidentId: '', Keys: ' )" # More detailed log
        $actionType = $action.actionType
        $parameters = $action.parameters
        $result = @{ Status = "Failed"; Output = "Action type '$actionType' not implemented or failed."; StartTime = (Get-Date)}

        # Initialize $scriptErrors as a resizable list specifically for RunPowerShellScript
        $scriptErrors = [System.Collections.Generic.List[object]]::new()

        try {
            switch ($actionType) {
                "LogMessage" {
                    $level = $this.GetOrElse($parameters.level, "Info")
                    $message = $this.GetOrElse($parameters.message, "No message provided for LogMessage action.")
                    $logMsgIncidentId = if($context -and $context.PSObject.Properties.Name -contains 'IncidentId' -and $null -ne $context.IncidentId) { $context.IncidentId } else { "N/A" }
                    Write-Host "[$level] Playbook Action Log: $message (Incident: $logMsgIncidentId)"
                    $result.Status = "Success"; $result.Output = "Logged message: $message"
                }
                "TagIncident" {
                    if (-not $context.PSObject.Properties.Name -contains 'Tags' -or $null -eq $context.Tags) {
                        if (-not $context.PSObject.Properties.Name -contains 'Tags') { $context | Add-Member -MemberType NoteProperty -Name Tags -Value ([System.Collections.Generic.List[string]]::new()) }
                        else { $context.Tags = [System.Collections.Generic.List[string]]::new() }
                    }
                    $tagName = $this.GetOrElse($parameters.tagName, "DefaultTag")
                    $context.Tags.Add($tagName)
                    $logTagIncidentId = if($context -and $context.PSObject.Properties.Name -contains 'IncidentId' -and $null -ne $context.IncidentId) { $context.IncidentId } else { "N/A" }
                    Write-Host "Tagged incident $logTagIncidentId with '$tagName'."
                    $result.Status = "Success"; $result.Output = "Tagged with: $tagName. Current tags: $($context.Tags -join ', ')"
                }
                "RunPowerShellScript" {
                    $scriptPath = $this.GetOrElse($parameters.scriptPath, "")
                    $scriptParametersOriginal = $this.GetOrElse($parameters.scriptParameters, @{})

                    # Clone and process parameters for placeholder replacement
                    $finalScriptParameters = if ($scriptParametersOriginal -is [hashtable]) { $scriptParametersOriginal.Clone() } else { @{} }
                    if ($scriptParametersOriginal -is [hashtable]) {
                        foreach ($key in $scriptParametersOriginal.Keys) {
                            if ($scriptParametersOriginal[$key] -is [string] -and $scriptParametersOriginal[$key] -eq "%%incident.Id%%") {
                                if ($context -and $context.PSObject.Properties.Name -contains 'IncidentId' -and $null -ne $context.IncidentId) {
                                    $finalScriptParameters[$key] = $context.IncidentId
                                    Write-Host "Replaced '%%incident.Id%%' with actual IncidentId '$($context.IncidentId)' for parameter '$key'"
                                } else {
                                    Write-Warning "Could not replace '%%incident.Id%%' for parameter '$key'; IncidentId not in context or was null."
                                    $finalScriptParameters[$key] = "ID_Not_Found_In_Context"
                                }
                            }
                        }
                    }

                    $resolvedScriptPath = $scriptPath
                    if ($scriptPath -and -not [System.IO.Path]::IsPathRooted($scriptPath)) {
                        $basePath = (Get-Location -PSProvider FileSystem).Path
                        $resolvedScriptPath = Join-Path -Path $basePath -ChildPath $scriptPath
                        $resolvedScriptPath = Resolve-Path -Path $resolvedScriptPath -ErrorAction SilentlyContinue # Check if path is valid after join
                    }

                    if (-not ($resolvedScriptPath -and (Test-Path $resolvedScriptPath -PathType Leaf))) {
                        throw "Action 'RunPowerShellScript': Script path '$scriptPath' (resolved to '$resolvedScriptPath') not found or is not a file."
                    }

                    Write-Host "Executing PowerShell script: $resolvedScriptPath with parameters: $($finalScriptParameters | ConvertTo-Json -Compress -Depth 3)"
                    $scriptOutput = [System.Collections.Generic.List[object]]::new()
                    # $scriptErrors is already initialized as List[object] above the try block.

                    try {
                        $output = & $resolvedScriptPath @finalScriptParameters -ErrorVariable +scriptErrors
                        if ($output) { $scriptOutput.AddRange($output) } # Use AddRange for lists if output is a collection
                        if ($LASTEXITCODE -ne 0 -and $scriptErrors.Count -eq 0) {
                             $scriptErrors.Add("Script $resolvedScriptPath exited with code $LASTEXITCODE")
                        }
                    } catch {
                        $scriptErrors.Add($_.Exception.Message)
                    }

                    if ($scriptErrors.Count -gt 0) {
                        $errorMessages = $scriptErrors -join "; "; Write-Warning "Script $resolvedScriptPath execution failed: $errorMessages"
                        $result.Status = "Failed"; $result.Output = "Script execution failed: $errorMessages"; $result.ScriptErrors = $scriptErrors
                    } else {
                        $result.Status = "Success"; $result.Output = "Script $resolvedScriptPath executed successfully."
                        if ($scriptOutput.Count -gt 0) {
                            $outputString = $scriptOutput -join '; ';
                            $result.ScriptOutput = $scriptOutput;
                            $result.Output += " Output: $outputString"
                        }
                    }
                }
                "InvokeBasicRestMethod" {
                    $uri = $parameters.uri; $method = $this.GetOrElse($parameters.method, "GET"); $body = $parameters.body
                    $headers = $this.GetOrElse($parameters.headers, @{}); $contentType = $this.GetOrElse($parameters.contentType, "application/json")
                    Write-Host "Attempting $method to $uri"; if ($body) { Write-Host ("With body: " + ($body | ConvertTo-Json -Compress -Depth 3)) }
                    if ($headers.Keys.Count -gt 0) { Write-Host ("With headers: " + ($headers | ConvertTo-Json -Compress -Depth 3)) }
                    try {
                        $apiResponse = Invoke-RestMethod -Uri $uri -Method $method -Body $body -Headers $headers -ContentType $contentType -ErrorAction Stop
                        $result.Status = "Success"; $result.Output = "Successfully invoked $method to $uri."; $result.ApiResponse = $apiResponse; Write-Host "API call successful."
                    } catch {
                        Write-Error "InvokeBasicRestMethod: API call to $uri failed. Error: $($_.Exception.Message)"
                        $result.Status = "Failed"; $result.Output = "API call to $uri failed: $($_.Exception.Message)"; $result.ErrorRecord = $_
                    }
                }
                default { Write-Warning "Unknown action type: $actionType"; $result.Output = "Unknown action type: $actionType" }
            }
        } catch {
            $logCatchIncidentId = if($context -and $context.PSObject.Properties.Name -contains 'IncidentId' -and $null -ne $context.IncidentId) { $context.IncidentId } else { "N/A" }
            Write-Error "Error executing action $actionType for incident ${logCatchIncidentId}: $($_.Exception.Message)"
            $result.Status = "Error"; $result.Output = "Exception: $($_.Exception.Message)"; $result.ErrorRecord = $_
        }
        $result.EndTime = (Get-Date); $result.Duration = $result.EndTime - $result.StartTime
        return $result
    }

    hidden [object] GetOrElse($value, $default) {
        if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrEmpty($value))) { return $default }
        return $value
    }

    hidden [object] _CollectForensicData([string]$incidentId) {
        Write-Host "SIR._CollectForensicData() now calling $this.ForensicEngine.CollectForensicData for $incidentId"
        if ($null -eq $this.ForensicEngine) { Write-Error "ForensicEngine not initialized!"; return $null }
        return $this.ForensicEngine.CollectForensicData($incidentId)
    }
    hidden [void] _UpdateThreatIntelligence([array]$iocs) {
        Write-Host "SIR._UpdateThreatIntelligence() now calling $this.ThreatIntelClient.UpdateThreatIntelligence"
        if ($null -eq $this.ThreatIntelClient) { Write-Error "ThreatIntelClient not initialized!"; return }
        $this.ThreatIntelClient.UpdateThreatIntelligence($iocs)
    }
    hidden [object] _GetRelatedThreatIntel([string]$incidentId) {
        Write-Host "SIR._GetRelatedThreatIntel() now calling $this.ThreatIntelClient.GetRelatedThreatIntel for $incidentId"
        if ($null -eq $this.ThreatIntelClient) { Write-Error "ThreatIntelClient not initialized!"; return $null }
        return $this.ThreatIntelClient.GetRelatedThreatIntel($incidentId)
    }

    hidden [object] _CreateIncidentContext([object]$incident) {
        Write-Host "SecurityIncidentResponder._CreateIncidentContext() (stub) called for incident: $($incident.Id)"
        return @{ IncidentId = $incident.Id; ReceivedTime = Get-Date; Status = "New"; Classification = "Pending"; InitialSeverity = $incident.Severity; AssociatedEntities = @(); RawIncident = $incident; Tags = ([System.Collections.Generic.List[string]]::new()); Actions = ([System.Collections.Generic.List[object]]::new()) }
    }
    hidden [void] _DocumentIncidentResponse([object]$incident, [object]$context) { Write-Host "SecurityIncidentResponder._DocumentIncidentResponse() (stub) called for incident: $($incident.Id)" }
    hidden [void] _EscalateIncident([object]$incident) { Write-Host "SecurityIncidentResponder._EscalateIncident() (stub) called for incident: $($incident.Id)" }
    hidden [void] _ValidateActionResult([object]$actionResult) { Write-Host "SecurityIncidentResponder._ValidateActionResult() (stub) called." }
    hidden [void] _UpdateIncidentContext([object]$context, [object]$actionResult) {
        Write-Host "SecurityIncidentResponder._UpdateIncidentContext() (stub) called."
        $context.LastActionStatus = $actionResult.Status; $context.LastUpdateTime = Get-Date
    }
    hidden [void] _HandleActionFailure([object]$action, [object]$context) { Write-Host "SecurityIncidentResponder._HandleActionFailure() (stub) called for action type: $($action.actionType)" }
    hidden [void] _IsolateCompromisedAccount([object]$context) { Write-Host "SecurityIncidentResponder._IsolateCompromisedAccount() (stub) called for incident: $($context.IncidentId)" }
    hidden [void] _InitiateForensicCollection([object]$context) { Write-Host "SecurityIncidentResponder._InitiateForensicCollection() (stub) called for incident: $($context.IncidentId)" }
    hidden [void] _NotifySecurityTeam([object]$context) { Write-Host "SecurityIncidentResponder._NotifySecurityTeam() (stub) called for incident: $($context.IncidentId)" }
    hidden [void] _BlockDataTransfer([object]$context) { Write-Host "SecurityIncidentResponder._BlockDataTransfer() (stub) called for incident: $($context.IncidentId)" }
    hidden [void] _RevokeSessions([object]$context) { Write-Host "SecurityIncidentResponder._RevokeSessions() (stub) called for incident: $($context.IncidentId)" }
    hidden [void] _InitiateDLP([object]$context) { Write-Host "SecurityIncidentResponder._InitiateDLP() (stub) called for incident: $($context.IncidentId)" }
    hidden [void] _IsolateInfectedSystems([object]$context) { Write-Host "SecurityIncidentResponder._IsolateInfectedSystems() (stub) called for incident: $($context.IncidentId)" }
    hidden [void] _InitiateAntimalwareScan([object]$context) { Write-Host "SecurityIncidentResponder._InitiateAntimalwareScan() (stub) called for incident: $($context.IncidentId)" }
    hidden [void] _CollectMalwareSamples([object]$context) { Write-Host "SecurityIncidentResponder._CollectMalwareSamples() (stub) called for incident: $($context.IncidentId)" }
    hidden [void] _ExecuteDefaultResponse([object]$context) { Write-Host "SecurityIncidentResponder._ExecuteDefaultResponse() (stub) called for incident: $($context.IncidentId)" }
    hidden [object] _CreateIncidentTimeline([object]$incidentContext) {
        Write-Host "SecurityIncidentResponder._CreateIncidentTimeline() (stub) called for incident: $($incidentContext.IncidentId)"; return @( @{ Timestamp = $incidentContext.ReceivedTime; Event = "Incident Received" }, @{ Timestamp = Get-Date; Event = "Report Generated (stub)" } )
    }
    hidden [object] _AssessIncidentImpact([object]$incidentContext) { Write-Host "SecurityIncidentResponder._AssessIncidentImpact() (stub) called for incident: $($incidentContext.IncidentId)"; return @{ Severity = "Medium"; Scope = "Limited"; BusinessImpact = "Low" } }
    hidden [string] _GetContainmentStatus([object]$incidentContext) { Write-Host "SecurityIncidentResponder._GetContainmentStatus() (stub) called."; return "Pending" }
    hidden [string] _GetRemediationStatus([object]$incidentContext) { Write-Host "SecurityIncidentResponder._GetRemediationStatus() (stub) called."; return "Pending" }
    hidden [object] _GetForensicFindings([string]$incidentId) {
        Write-Host "SecurityIncidentResponder._GetForensicFindings() (stub) called for incident: $incidentId"
        return @{ Findings = "No forensic findings (stub)."; Confidence = "Low" }
    }
    hidden [object] _AnalyzeForensicData([object]$forensicData) { Write-Host "SecurityIncidentResponder._AnalyzeForensicData() (stub) called."; return @{ AnalysisSummary = "Basic analysis performed (stub)."; IOCsFound = @() } }
    hidden [array] _IdentifyIOCs([object]$analysis) { Write-Host "SecurityIncidentResponder._IdentifyIOCs() (stub) called."; return @("ioc1_stub", "ioc2_stub") }
    hidden [void] _GenerateForensicReport([string]$incidentId, [object]$analysis) { Write-Host "SecurityIncidentResponder._GenerateForensicReport() (stub) called for incident: $incidentId" }
    hidden [object] _CompileLessonsLearned([object]$incidentContext) { Write-Host "SecurityIncidentResponder._CompileLessonsLearned() (stub) called."; return @{ Observation = "Stub observation."} }
    hidden [object] _CalculateResponseMetrics([object]$incidentContext) { Write-Host "SecurityIncidentResponder._CalculateResponseMetrics() (stub) called."; return @{ TimeToDetection = "N/A"; TimeToResponse = "N/A" } }
}
