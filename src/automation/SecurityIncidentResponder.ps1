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
                # Pass the step, context, and the exception details to _HandleActionFailure
                $this._HandleActionFailure($step, $context, $_.Exception)

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
        # Assuming $context.RawIncident exists and might contain specific mock properties
        switch ($triggerType) {
            "AccountCompromise" {
                $this._IsolateCompromisedAccount($context)
                $this._InitiateForensicCollection($context)
                $this._NotifySecurityTeam($context)
            }
            "DataExfiltration" {
                $this._BlockDataTransfer($context)
                $this._RevokeSessions($context)
                $this._InitiateDLP($context)
            }
            "MalwareDetection" {
                $this._IsolateInfectedSystems($context)
                $this._InitiateAntimalwareScan($context)
                $this._CollectMalwareSamples($context)
            }
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
        $this.PlaybookManager.LoadPlaybooks("../../playbooks"); $this.SecurityPlaybooks = $this.PlaybookManager.LoadedPlaybooks
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

    hidden [pscustomobject] _CreateIncidentContext([object]$incident) {
        Write-Host "SecurityIncidentResponder._CreateIncidentContext() called for incident: $($incident.Id)"
        $context = [PSCustomObject]@{
            IncidentId          = $incident.Id
            TenantId            = $this.TenantId # Assuming $this.TenantId is set in constructor
            ReceivedTime        = Get-Date
            LastUpdateTime      = Get-Date
            Status              = "New" # e.g., New, Active, Contained, Eradicated, Recovered, Closed
            Classification      = "Pending" # e.g., MalwareDetection, AccountCompromise, PhishingAttempt, etc.
            InitialSeverity     = if ($null -ne $incident.Severity) { $incident.Severity } else { "Unknown" } # Handle null severity
            CurrentSeverity     = if ($null -ne $incident.Severity) { $incident.Severity } else { "Unknown" } # Handle null severity
            AssociatedEntities  = [System.Collections.Generic.List[string]]::new()
            Tags                = [System.Collections.Generic.List[string]]::new()
            Actions             = [System.Collections.Generic.List[object]]::new() # To store action results
            PlaybookExecution   = @{
                CurrentPlaybookName = $null
                CurrentStepName     = $null
                Status              = "NotStarted" # e.g., NotStarted, InProgress, Completed, Failed
            }
            ForensicData        = $null
            ThreatIntel         = $null
            Notes               = [System.Collections.Generic.List[string]]::new()
            RawIncident         = $incident # The original incident object
        }

        # Potentially add some initial entities if available in $incident (example properties)
        if ($incident.PSObject.Properties.Name -contains 'AffectedUser' -and $null -ne $incident.AffectedUser) {
            $context.AssociatedEntities.Add("User:$($incident.AffectedUser)")
        }
        if ($incident.PSObject.Properties.Name -contains 'AffectedDevice' -and $null -ne $incident.AffectedDevice) {
            $context.AssociatedEntities.Add("Device:$($incident.AffectedDevice)")
        }

        return $context
    }
    hidden [object] _DocumentIncidentResponse([object]$incident, [object]$context) { # Return type changed to object
        Write-Host "SIR:_DocumentIncidentResponse - Documenting for incident $($incident.Id). Final Status_Mock: $($context.Status)" # Assumes $context.Status
        return @{ Status = "MockResponseDocumented"; IncidentID = $incident.Id; ReportLocation_Mock = "/cases/incident-$($incident.Id)-final_report.log"; Timestamp = (Get-Date -Format 'u') }
    }
    hidden [object] _EscalateIncident([object]$incident) { # Return type changed to object
        Write-Host "SIR:_EscalateIncident - Escalating incident $($incident.Id). Current Severity_Mock: $($incident.Severity)" # Assumes $incident.Severity
        return @{ Status = "MockIncidentEscalated"; IncidentID = $incident.Id; EscalationTarget_Mock = "Tier2Support_EmailDL"; Timestamp = (Get-Date -Format 'u') }
    }
    hidden [void] _ValidateActionResult([object]$actionResult) {
        Write-Host "SecurityIncidentResponder._ValidateActionResult called for action result (Status: $($actionResult.Status))"
        if ($null -eq $actionResult) {
            Write-Warning "_ValidateActionResult: Action result is null."
            # Consider throwing an error if actionResult being null is unacceptable
            # throw "Action result cannot be null in _ValidateActionResult"
            return
        }
        if (-not $actionResult.PSObject.Properties.Name -contains 'Status') {
            Write-Warning "_ValidateActionResult: Action result is missing 'Status' property."
            # Consider throwing an error if Status is mandatory
            # throw "Action result must have a 'Status' property in _ValidateActionResult"
        }
        # Example: Log the full result for debugging if it's complex
        # if ($actionResult.PSObject.Properties.Count -gt 3) { # Arbitrary condition
        #    Write-Verbose "_ValidateActionResult: Detailed action result: $($actionResult | ConvertTo-Json -Depth 2 -Compress)"
        # }
    }
    hidden [void] _UpdateIncidentContext([object]$context, [object]$actionResult) {
        Write-Host "SecurityIncidentResponder._UpdateIncidentContext called. Action Status: $($actionResult.Status), Action Name: $($actionResult.Name)"
        $context.LastActionStatus = $actionResult.Status
        $context.LastUpdateTime = Get-Date

        # Add a note about the action taken
        $actionNote = "Action '$($actionResult.Name)' (Type: $($actionResult.Type)) completed with status: $($actionResult.Status)."
        if ($actionResult.PSObject.Properties.Name -contains 'Output' -and $null -ne $actionResult.Output) {
            $actionNote += " Output: $($actionResult.Output | Out-String)"
        }
        $context.Notes.Add((Get-Date).ToString("u") + " - " + $actionNote)


        if ($actionResult.Status -ne "Success" -and $actionResult.Status -ne "SucceededWithInfo") { # Or other considered success states
            $context.PlaybookExecution.Status = "FailedAtStep" # More specific status for playbook
            $context.Status = "NeedsAttention" # Overall incident status
        }
        # If action was successful, and it was the last step of a playbook, update playbook status
        # This requires knowing if it's the last step - logic for this would be in ExecutePlaybook
    }
    hidden [void] _HandleActionFailure([object]$action, [object]$context, [object]$exceptionDetails) {
        $errorMessage = "ERROR during action '$($action.name)' (Type: $($action.actionType)): $($exceptionDetails.Message)"
        Write-Error $errorMessage

        if ($null -ne $context) {
            $noteTimestamp = (Get-Date).ToString("u")
            $context.Notes.Add("$noteTimestamp - FAILURE: $errorMessage")
            $context.Status = "ErrorInPlaybook" # Overall incident status
            if ($null -ne $context.PlaybookExecution) {
                $context.PlaybookExecution.Status = "Failed"
                 if ($null -ne $action -and $action.PSObject.Properties.Name -contains 'name') {
                     $context.PlaybookExecution.CurrentStepName = $action.name
                 }
            }
            $context.LastUpdateTime = Get-Date
        }
        # Future enhancement: Trigger an escalation or specific alert
        # Example: $this._EscalateIncident($context.RawIncident, "PlaybookActionFailure: $($action.name)")
    }
    hidden [object] _IsolateCompromisedAccount([object]$context) { # Return type changed
        Write-Host "SIR:_IsolateCompromisedAccount - For incident $($context.IncidentId). User: $($context.RawIncident.AffectedUser_Mock)"
        return @{ Status = "MockIsolationTriggered"; User = $context.RawIncident.AffectedUser_Mock; Actions_Mock = @("PasswordReset", "SessionRevoke"); Timestamp = (Get-Date -Format 'u') }
    }
    hidden [object] _InitiateForensicCollection([object]$context) { # Return type changed
        Write-Host "SIR:_InitiateForensicCollection - For incident $($context.IncidentId). Target: $($context.RawIncident.AffectedDevice_Mock)"
        return @{ Status = "MockForensicCollectionQueued"; Target = $context.RawIncident.AffectedDevice_Mock; Tool_Mock = "RemoteScriptExecution"; Timestamp = (Get-Date -Format 'u') }
    }
    hidden [object] _NotifySecurityTeam([object]$context) { # Return type changed
        Write-Host "SIR:_NotifySecurityTeam - For incident $($context.IncidentId). Severity: $($context.CurrentSeverity)"
        return @{ Status = "MockNotificationSent"; Team_Mock = "SecurityOperationsCenter_DL"; IncidentID = $context.IncidentId; Timestamp = (Get-Date -Format 'u') }
    }
    hidden [object] _BlockDataTransfer([object]$context) { # Return type changed
        Write-Host "SIR:_BlockDataTransfer - For incident $($context.IncidentId). DataPattern_Mock: $($context.RawIncident.DataPattern_Mock)"
        return @{ Status = "MockDataTransferBlockApplied"; Policy_Mock = "DLP_Rule_SensitiveData_XYZ"; Target_Mock = $context.RawIncident.DataSource_Mock; Timestamp = (Get-Date -Format 'u') }
    }
    hidden [object] _RevokeSessions([object]$context) { # Return type changed
        Write-Host "SIR:_RevokeSessions - For incident $($context.IncidentId). User: $($context.RawIncident.AffectedUser_Mock)"
        return @{ Status = "MockSessionsRevoked"; User = $context.RawIncident.AffectedUser_Mock; SessionCount_Mock = (Get-Random -Min 1 -Max 5); Timestamp = (Get-Date -Format 'u') }
    }
    hidden [object] _InitiateDLP([object]$context) { # Return type changed
        Write-Host "SIR:_InitiateDLP - For incident $($context.IncidentId). Details: $($context.RawIncident.DLPDetails_Mock)"
        return @{ Status = "MockDLPScanInitiated"; Profile_Mock = "FullSensitiveDataScan_Profile"; Target_Mock = "AllUserEndpoints_Global"; Timestamp = (Get-Date -Format 'u') }
    }
    hidden [object] _IsolateInfectedSystems([object]$context) { # Return type changed
        Write-Host "SIR:_IsolateInfectedSystems - For incident $($context.IncidentId). System_Mock: $($context.RawIncident.AffectedDevice_Mock)"
        return @{ Status = "MockSystemIsolationApplied"; System_Mock = $context.RawIncident.AffectedDevice_Mock; Method_Mock = "NetworkACL_FirewallRule"; Timestamp = (Get-Date -Format 'u') }
    }
    hidden [object] _InitiateAntimalwareScan([object]$context) { # Return type changed
        Write-Host "SIR:_InitiateAntimalwareScan - For incident $($context.IncidentId). System_Mock: $($context.RawIncident.AffectedDevice_Mock)"
        return @{ Status = "MockAntimalwareScanStarted"; System_Mock = $context.RawIncident.AffectedDevice_Mock; ScanType_Mock = "Deep_FullSystem"; Timestamp = (Get-Date -Format 'u') }
    }
    hidden [object] _CollectMalwareSamples([object]$context) { # Return type changed
        Write-Host "SIR:_CollectMalwareSamples - For incident $($context.IncidentId). Hash_Mock: $($context.RawIncident.MalwareHash_Mock)"
        return @{ Status = "MockSampleCollectionAttempted"; Hash_Mock = $context.RawIncident.MalwareHash_Mock; Storage_Mock = "SecureMalwareVault_SFTP"; Timestamp = (Get-Date -Format 'u') }
    }
    hidden [object] _ExecuteDefaultResponse([object]$context) { # Return type changed
        Write-Host "SIR:_ExecuteDefaultResponse - For Unclassified/Default incident $($context.IncidentId). Assigning for manual review."
        return @{ Status = "MockDefaultResponseExecuted"; Actions_Mock = @("LogForManualReview", "AssignToTier1Queue_ServiceNow"); Timestamp = (Get-Date -Format 'u') }
    }
    hidden [array] _CreateIncidentTimeline([object]$incidentContext) { # Return type specified as array
        Write-Host "SIR:_CreateIncidentTimeline - For incident $($incidentContext.IncidentId)"
        return @(
            @{ Timestamp = $incidentContext.ReceivedTime.ToString('u'); Event = "Incident Received"; Details = $incidentContext.RawIncident.Title },
            @{ Timestamp = $incidentContext.ReceivedTime.AddMinutes(2).ToString('u'); Event = "Context Created"; IncidentID = $incidentContext.IncidentId},
            @{ Timestamp = $incidentContext.ReceivedTime.AddMinutes(5).ToString('u'); Event = "Playbook Started"; Details = $incidentContext.PlaybookExecution.CurrentPlaybookName },
            @{ Timestamp = (Get-Date -Format 'u'); Event = "Report Generated" }
        )
    }
    hidden [hashtable] _AssessIncidentImpact([object]$incidentContext) { # Return type specified as hashtable
        Write-Host "SIR:_AssessIncidentImpact - For incident $($incidentContext.IncidentId)"
        return @{ Severity = $incidentContext.CurrentSeverity; Scope_Mock = "MultipleUsers_FinanceDept_Mock"; BusinessImpact_Mock = "Medium_PotentialServiceDisruption_Payroll"; DataImpact_Mock = "Low_NoPIIConfirmed_Mock"; SystemsAffected_Mock = @($incidentContext.RawIncident.AffectedDevice_Mock) }
    }
    hidden [string] _GetContainmentStatus([object]$incidentContext) {
        Write-Host "SIR:_GetContainmentStatus - For incident $($incidentContext.IncidentId)"
        return "Contained_Full_Mock"
    }
    hidden [string] _GetRemediationStatus([object]$incidentContext) {
        Write-Host "SIR:_GetRemediationStatus - For incident $($incidentContext.IncidentId)"
        return "Remediated_Verified_Mock"
    }
    hidden [hashtable] _GetForensicFindings([string]$incidentId) { # Return type specified as hashtable
        Write-Host "SIR:_GetForensicFindings (Report) - For incident $incidentId"
        if ($this.ActiveIncidents.ContainsKey($incidentId) -and $null -ne $this.ActiveIncidents[$incidentId].ForensicFindings) {
            return @{ FindingsSummary_Mock = "Retrieved from ActiveIncidents. ThreatHunter analysis complete."; IOCs_Mock = $this.ActiveIncidents[$incidentId].IdentifiedIOCs; AnalysisDetails_Mock = $this.ActiveIncidents[$incidentId].ForensicFindings }
        } else {
            return @{ FindingsSummary_Mock = "No detailed forensic findings in ActiveIncidents for $incidentId or analysis pending/failed."; IOCs_Mock = @() }
        }
    }
    hidden [object] _AnalyzeForensicData([object]$forensicData) {
        Write-Host "SecurityIncidentResponder._AnalyzeForensicData called."
        if ($null -eq $forensicData) {
            Write-Warning "_AnalyzeForensicData: Input forensicData is null."
            return @{ AnalysisSummary = "No data provided for analysis."; IOCsFound = @() }
        }

        $summary = "Forensic data analysis (simulated). "
        $iocs = [System.Collections.Generic.List[string]]::new()

        if ($forensicData.PSObject.Properties.Name -contains 'Processes') {
            $summary += " $($forensicData.Processes.Count) processes reviewed."
            foreach ($process in $forensicData.Processes) {
                if ($null -ne $process.Name -and ($process.Name -like "evil.exe*" -or $process.Name -like "ransom.exe*")) {
                    $iocs.Add("ProcessName:$($process.Name)")
                    if ($null -ne $process.CommandLine) { $iocs.Add("ProcessCommandLine:$($process.CommandLine)") }
                }
            }
        }
        if ($forensicData.PSObject.Properties.Name -contains 'NetworkConnections') {
            $summary += " $($forensicData.NetworkConnections.Count) network connections reviewed."
             foreach ($conn in $forensicData.NetworkConnections) {
                if ($null -ne $conn.DestinationIP -and $conn.DestinationIP -eq "3.3.3.3") { # Example from mock
                    $iocs.Add("NetworkDestinationIP:$($conn.DestinationIP)")
                }
            }
        }
        if ($forensicData.PSObject.Properties.Name -contains 'Files') {
            $summary += " $($forensicData.Files.Count) files reviewed."
             foreach ($file in $forensicData.Files) {
                if ($null -ne $file.Path -and $file.Path -like "*evil.exe") {
                    $iocs.Add("FilePath:$($file.Path)")
                    if ($null -ne $file.Hash) { $iocs.Add("FileHash:$($file.Hash)") }
                }
            }
        }
        $summary += " Identified $($iocs.Count) potential IOCs."
        Write-Host $summary
        return @{ AnalysisSummary = $summary; IOCsFound = $iocs }
    }
    hidden [array] _IdentifyIOCs([object]$analysis) {
        Write-Host "SecurityIncidentResponder._IdentifyIOCs called."
        if ($null -ne $analysis -and $analysis.PSObject.Properties.Name -contains 'IOCsFound') {
            # Ensure it's an array, even if it's a List from _AnalyzeForensicData
            return @($analysis.IOCsFound)
        }
        Write-Warning "_IdentifyIOCs: Analysis object did not contain 'IOCsFound' or was null."
        return @()
    }
    hidden [void] _GenerateForensicReport([string]$incidentId, [object]$analysis) {
        Write-Host "SecurityIncidentResponder._GenerateForensicReport for incident: $incidentId."
        if ($null -eq $analysis) {
            Write-Warning "_GenerateForensicReport: Analysis data is null. Cannot generate report."
            return
        }

        $iocsString = if ($null -ne $analysis.IOCsFound) { $analysis.IOCsFound -join ', ' } else { "None" }

        $reportText = @"
Incident ID: $incidentId
Analysis Summary: $($analysis.AnalysisSummary)
Identified IOCs: $iocsString
Report Generated: $(Get-Date)
"@
        Write-Host "--- Forensic Report Start ---"
        Write-Host $reportText
        Write-Host "--- Forensic Report End ---"
        # Example: Add report to incident context notes
        # if ($this.ActiveIncidents.ContainsKey($incidentId)) {
        #    $this.ActiveIncidents[$incidentId].Notes.Add("Forensic Report Generated: $reportText")
        # }
    }
    hidden [hashtable] _CompileLessonsLearned([object]$incidentContext) { # Return type specified as hashtable
        Write-Host "SIR:_CompileLessonsLearned - For incident $($incidentContext.IncidentId)"
        return @{ Observation_Mock = "Initial alert triage for $($incidentContext.Classification) was delayed by 15 minutes due to high queue volume."; Recommendation_Mock = "Review alert pipeline performance and consider dynamic prioritization for high-severity classifications."; IncidentID = $incidentContext.IncidentId }
    }
    hidden [hashtable] _CalculateResponseMetrics([object]$incidentContext) { # Return type specified as hashtable
        Write-Host "SIR:_CalculateResponseMetrics - For incident $($incidentContext.IncidentId)"
        return @{ TimeToDetection_Mock = "00:10:00"; TimeToAcknowledge_Mock = "00:05:30"; TimeToResponseAction_Mock = "00:25:15"; TimeToContainment_Mock = "02:15:00"; FullResolutionTime_Mock = "05:30:45"; IncidentID = $incidentContext.IncidentId }
    }
}
