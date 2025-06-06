$sirPath = "src/automation/Security_Incident_Responder.ps1"
$sirContent = Get-Content -Path $sirPath -Raw

# --- Define the complete new _ExecuteAction method body with fixes ---
$newExecuteActionMethodBody = @'
    hidden [object] _ExecuteAction([object]$action, [object]$context) {
        Write-Host "SecurityIncidentResponder._ExecuteAction() (ApplyFixes Task Update) called for action type: $($action.actionType)"
        $actionType = $action.actionType
        $parameters = $action.parameters
        $result = @{ Status = "Failed"; Output = "Action type '$actionType' not implemented or failed."; StartTime = (Get-Date)}

        try {
            switch ($actionType) {
                "LogMessage" {
                    $level = $this.GetOrElse($parameters.level, "Info")
                    $message = $this.GetOrElse($parameters.message, "No message provided for LogMessage action.")
                    $logMsgIncidentId = if($context -and $context.PSObject.Properties.Name -contains 'IncidentId') { $context.IncidentId } else { "N/A" }
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
                    $logTagIncidentId = if($context -and $context.PSObject.Properties.Name -contains 'IncidentId') { $context.IncidentId } else { "N/A" }
                    Write-Host "Tagged incident $logTagIncidentId with '$tagName'."
                    $result.Status = "Success"; $result.Output = "Tagged with: $tagName. Current tags: $($context.Tags -join ', ')"
                }
                "RunPowerShellScript" {
                    $scriptPath = $this.GetOrElse($parameters.scriptPath, "")
                    $scriptParametersOriginal = $this.GetOrElse($parameters.scriptParameters, @{})
                    $scriptParameters = $scriptParametersOriginal.Clone() # Work on a copy for placeholder replacement

                    # Placeholder replacement for script parameters
                    if ($scriptParameters -is [hashtable]) {
                        foreach ($key in $scriptParametersOriginal.Keys) { # Iterate original keys
                            if ($scriptParametersOriginal[$key] -is [string] -and $scriptParametersOriginal[$key] -eq "%%incident.Id%%") {
                                if ($context -and $context.PSObject.Properties.Name -contains 'IncidentId' -and $null -ne $context.IncidentId) {
                                    $scriptParameters[$key] = $context.IncidentId
                                    Write-Host "Replaced '%%incident.Id%%' with actual IncidentId '$($context.IncidentId)' for parameter '$key'"
                                } else {
                                    Write-Warning "Could not replace '%%incident.Id%%' for parameter '$key' as IncidentId not found in context or was null."
                                    $scriptParameters[$key] = "ID_Not_Found_In_Context"
                                }
                            }
                        }
                    }

                    $resolvedScriptPath = $scriptPath
                    if ($scriptPath -and -not [System.IO.Path]::IsPathRooted($scriptPath)) {
                        $basePath = (Get-Location -PSProvider FileSystem).Path
                        $resolvedScriptPath = Join-Path -Path $basePath -ChildPath $scriptPath
                        $resolvedScriptPath = Resolve-Path -Path $resolvedScriptPath -ErrorAction SilentlyContinue
                    }

                    if (-not ($resolvedScriptPath -and (Test-Path $resolvedScriptPath -PathType Leaf))) { throw "Action 'RunPowerShellScript': Script path '$scriptPath' (resolved to '$resolvedScriptPath') not found or is not a file." }

                    Write-Host "Executing PowerShell script: $resolvedScriptPath with parameters: $($scriptParameters | ConvertTo-Json -Compress -Depth 3)"
                    $scriptOutput = @()
                    $errors = [System.Collections.Generic.List[object]]::new() # FIXED initialization

                    try {
                        $output = & $resolvedScriptPath @scriptParameters -ErrorVariable +errors
                        if ($output) { $scriptOutput += $output }
                        if ($LASTEXITCODE -ne 0 -and $errors.Count -eq 0) {
                             $errors.Add("Script $resolvedScriptPath exited with code $LASTEXITCODE")
                        }
                    } catch {
                        $errors.Add($_.Exception.Message)
                    }

                    if ($errors.Count -gt 0) {
                        $errorMessages = $errors -join "; "; Write-Warning "Script $resolvedScriptPath execution failed: $errorMessages"
                        $result.Status = "Failed"; $result.Output = "Script execution failed: $errorMessages"; $result.ScriptErrors = $errors
                    } else {
                        $result.Status = "Success"; $result.Output = "Script $resolvedScriptPath executed successfully."
                        if ($scriptOutput.Count -gt 0) { $result.ScriptOutput = $scriptOutput; $result.Output += " Output: $($scriptOutput -join '; ')" }
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
            $logCatchIncidentId = if($context -and $context.PSObject.Properties.Name -contains 'IncidentId') { $context.IncidentId } else { "N/A" }
            Write-Error "Error executing action $actionType for incident ${logCatchIncidentId}: $($_.Exception.Message)"
            $result.Status = "Error"; $result.Output = "Exception: $($_.Exception.Message)"; $result.ErrorRecord = $_
        }
        $result.EndTime = (Get-Date); $result.Duration = $result.EndTime - $result.StartTime
        return $result
    }
'@

# Regex to find the old _ExecuteAction method block
$executeActionRegex = '(?s)hidden \[object\] _ExecuteAction\(\[object\]\$action, \[object\]\$context\)\s*\{.*?`n\s*\}'

if ($sirContent -match $executeActionRegex) {
    $sirContent = $sirContent -replace $executeActionRegex, $newExecuteActionMethodBody
    Write-Host "Replaced _ExecuteAction method with new implementation."
} else {
    Write-Error "Could not find _ExecuteAction method to replace. This is unexpected."
    # As a fallback, try to append (though this might lead to duplicates if the regex failed for subtle reasons)
    # This part of the logic is less critical now as the overwrite_file_with_block in previous steps should have standardized it.
    # $lastBraceIndex = $sirContent.LastIndexOf('}')
    # if ($lastBraceIndex -ne -1) {
    #     $getOrElseRegex = '(?s)\s*hidden \[object\] GetOrElse\(\$value, \$default\)\s*\{.*?`n\s*\}'
    #     if ($sirContent -match $getOrElseRegex) { # If GetOrElse exists, insert _ExecuteAction before it
    #          $sirContent = $sirContent -replace $getOrElseRegex, ($newExecuteActionMethodBody + "`n" + $Matches[0])
    #     } else { # Append _ExecuteAction and GetOrElse (since GetOrElse is part of newExecuteActionMethodBody now)
    #          $sirContent = $sirContent.Substring(0, $lastBraceIndex) + $newExecuteActionMethodBody + "`n}"
    #     }
    #    Write-Host "Attempted to append/insert _ExecuteAction due to regex match failure for replacement."
    # } else {
    #    Write-Error "Could not find closing brace of class to append _ExecuteAction."
    # }
}

Set-Content -Path $sirPath -Value $sirContent -Force
Write-Host "Updated $sirPath with fixes for _ExecuteAction."

# Re-run the integration test harness
Write-Host "--- Re-running Integration Test Harness after _ExecuteAction fixes ---"
pwsh -File ./integration_test_harness.ps1
Write-Host "--- Integration Test Harness Re-run Finished ---"

echo "---DONE---"
