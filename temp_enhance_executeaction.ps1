# Part 1: Create scripts/actions/ directory and LogToFile.ps1 script
New-Item -ItemType Directory -Path "scripts/actions" -Force -ErrorAction SilentlyContinue
Write-Host "Created/Ensured directory scripts/actions/"

Set-Content -Path "scripts/actions/LogToFile.ps1" -Value @'
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,

    [Parameter(Mandatory=$true)]
    [string]$Message,

    [string]$IncidentId = "N/A",
    [string]$LogLevel = "Info"
)

try {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$LogLevel] Incident: $IncidentId | Message: $Message"

    $directory = Split-Path -Path $FilePath -Resolve
    if ($directory -and (-not (Test-Path -Path $directory -PathType Container))) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    Add-Content -Path $FilePath -Value $logEntry
    Write-Host "LogToFile.ps1: Successfully wrote to $FilePath"
}
catch {
    Write-Error "LogToFile.ps1: Failed to write to $FilePath. Error: $($_.Exception.Message)"
    throw
}
'@
Write-Host "Created scripts/actions/LogToFile.ps1"

# Part 2: Modify SecurityIncidentResponder._ExecuteAction in src/automation/Security_Incident_Responder.ps1
$sirPath = "src/automation/Security_Incident_Responder.ps1"
$sirContent = Get-Content -Path $sirPath -Raw

# Define the NEW, complete _ExecuteAction method and its GetOrElse helper
$newExecuteActionAndHelperMethods = @'
    hidden [object] _ExecuteAction([object]$action, [object]$context) {
        Write-Host "SecurityIncidentResponder._ExecuteAction() (REAL ACTIONS UPDATE) called for action type: $($action.actionType)"
        $actionType = $action.actionType
        $parameters = $action.parameters
        $result = @{ Status = "Failed"; Output = "Action type '$actionType' not implemented or failed."; StartTime = (Get-Date)}

        try {
            switch ($actionType) {
                "LogMessage" {
                    $level = $this.GetOrElse($parameters.level, "Info")
                    $message = $this.GetOrElse($parameters.message, "No message provided for LogMessage action.")
                    Write-Host "[$level] Playbook Action Log: $message (Incident: $($context.IncidentId))"
                    $result.Status = "Success"; $result.Output = "Logged message: $message"
                }
                "TagIncident" {
                    if (-not $context.PSObject.Properties.Name -contains 'Tags' -or $null -eq $context.Tags) {
                        $context.Tags = [System.Collections.Generic.List[string]]::new()
                    }
                    $tagName = $this.GetOrElse($parameters.tagName, "DefaultTag")
                    $context.Tags.Add($tagName)
                    Write-Host "Tagged incident $($context.IncidentId) with '$tagName'."
                    $result.Status = "Success"; $result.Output = "Tagged with: $tagName. Current tags: $($context.Tags -join ', ')"
                }
                "RunPowerShellScript" {
                    $scriptPath = $this.GetOrElse($parameters.scriptPath, "")
                    $scriptParameters = $this.GetOrElse($parameters.scriptParameters, @{})

                    # Resolve path relative to the script's location if it's a relative path
                    # Assuming $PSScriptRoot is the root of the repo for scripts run by the agent.
                    # If $scriptPath starts with ./ or .\ it's relative to PSScriptRoot.
                    $resolvedScriptPath = $scriptPath
                    if (-not (Test-Path $scriptPath -IsAbsolute)) {
                        $resolvedScriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptPath
                        # For scripts in 'scripts/actions', if scriptPath is './scripts/actions/LogToFile.ps1'
                        # and PSScriptRoot is /app, then Join-Path will work.
                        # If scriptPath is just 'LogToFile.ps1' and meant to be in a specific dir, logic needs to be smarter.
                        # For this case, assume scriptPath is like "./scripts/actions/LogToFile.ps1" from repo root.
                        if (-not (Test-Path $resolvedScriptPath)) { # Try one level up if PSScriptRoot is 'scripts/setup' etc.
                             $resolvedScriptPath = Join-Path -Path (Split-Path $PSScriptRoot) -ChildPath $scriptPath
                        }
                         $resolvedScriptPath = Resolve-Path -Path $resolvedScriptPath -ErrorAction SilentlyContinue
                    }

                    if (-not ($resolvedScriptPath -and (Test-Path $resolvedScriptPath -PathType Leaf))) {
                        throw "Action 'RunPowerShellScript': Script path '$scriptPath' (resolved to '$resolvedScriptPath') not found or is not a file."
                    }

                    Write-Host "Executing PowerShell script: $resolvedScriptPath with parameters: $($scriptParameters | ConvertTo-Json -Compress -Depth 3)"
                    $scriptOutput = @()
                    $errors = @()
                    try {
                        # Ensure incidentId is passed if the script expects it and placeholder is used
                        if ($scriptParameters.ContainsKey("IncidentId") -and $scriptParameters.IncidentId -eq "%%incident.Id%%") {
                            $scriptParameters.IncidentId = $context.IncidentId
                        }

                        $output = & $resolvedScriptPath @scriptParameters -ErrorVariable +errors # ErrorAction Stop will terminate this script
                        if ($output) { $scriptOutput += $output }
                        if ($LASTEXITCODE -ne 0 -and $errors.Count -eq 0) {
                             $errors.Add("Script $resolvedScriptPath exited with code $LASTEXITCODE")
                        }
                    } catch {
                        $errors.Add($_.Exception.Message)
                    }

                    if ($errors.Count -gt 0) {
                        $errorMessages = $errors -join "; "
                        Write-Warning "Script $resolvedScriptPath execution failed or produced errors: $errorMessages"
                        $result.Status = "Failed"; $result.Output = "Script execution failed: $errorMessages"; $result.ScriptErrors = $errors
                    } else {
                        $result.Status = "Success"; $result.Output = "Script $resolvedScriptPath executed successfully."
                        if ($scriptOutput.Count -gt 0) { $result.ScriptOutput = $scriptOutput; $result.Output += " Output: $($scriptOutput -join '; ')" }
                    }
                }
                "InvokeBasicRestMethod" {
                    $uri = $parameters.uri
                    $method = $this.GetOrElse($parameters.method, "GET")
                    $body = $parameters.body
                    $headers = $this.GetOrElse($parameters.headers, @{})
                    $contentType = $this.GetOrElse($parameters.contentType, "application/json")

                    Write-Host "Attempting $method to $uri"
                    if ($body) { Write-Host ("With body: " + ($body | ConvertTo-Json -Compress -Depth 3)) }
                    if ($headers.Keys.Count -gt 0) { Write-Host ("With headers: " + ($headers | ConvertTo-Json -Compress -Depth 3)) }

                    try {
                        $apiResponse = Invoke-RestMethod -Uri $uri -Method $method -Body $body -Headers $headers -ContentType $contentType -ErrorAction Stop
                        $result.Status = "Success"; $result.Output = "Successfully invoked $method to $uri."; $result.ApiResponse = $apiResponse
                        Write-Host "API call successful."
                    } catch {
                        Write-Error "InvokeBasicRestMethod: API call to $uri failed. Error: $($_.Exception.Message)"
                        $result.Status = "Failed"; $result.Output = "API call to $uri failed: $($_.Exception.Message)"; $result.ErrorRecord = $_
                    }
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

    hidden [object] GetOrElse($value, $default) {
        if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrEmpty($value))) { return $default }
        return $value
    }
'@

# Regex to find the old _ExecuteAction method and the GetOrElse method if it immediately follows
$executeActionAndHelperRegex = '(?s)hidden \[object\] _ExecuteAction\(\[object\]\$action, \[object\]\$context\)\s*\{.*?`n\s*\}\s*hidden \[object\] GetOrElse\(\$value, \$default\)\s*\{.*?`n\s*\}'
# Simpler regex if GetOrElse is not guaranteed to be there or immediately after
$executeActionOnlyRegex = '(?s)hidden \[object\] _ExecuteAction\(\[object\]\$action, \[object\]\$context\)\s*\{.*?`n\s*\}'
$getOrElseRegex = '(?s)\s*hidden \[object\] GetOrElse\(\$value, \$default\)\s*\{.*?`n\s*\}' # Separate regex for GetOrElse

if ($sirContent -match $executeActionAndHelperRegex) {
    $sirContent = $sirContent -replace $executeActionAndHelperRegex, $newExecuteActionAndHelperMethods
    Write-Host "Replaced _ExecuteAction and its adjacent GetOrElse helper with new implementations."
} elseif ($sirContent -match $executeActionOnlyRegex) {
    $sirContent = $sirContent -replace $executeActionOnlyRegex, "" # Remove old _ExecuteAction
    # Remove old GetOrElse separately if it exists somewhere else
    if ($sirContent -match $getOrElseRegex) {
        $sirContent = $sirContent -replace $getOrElseRegex, ""
        Write-Host "Removed standalone GetOrElse."
    }
    # Now append the new combined block before the class's final closing brace
    $lastBraceIndex = $sirContent.LastIndexOf('}')
    if ($lastBraceIndex -ne -1) {
        $sirContent = $sirContent.Substring(0, $lastBraceIndex) + $newExecuteActionAndHelperMethods + "`n}"
        Write-Host "Appended new _ExecuteAction and GetOrElse methods."
    } else {
        Write-Error "Could not find closing brace to append methods."
    }
} else {
    Write-Warning "Could not find existing _ExecuteAction method to replace. Appending methods."
    $lastBraceIndex = $sirContent.LastIndexOf('}')
    if ($lastBraceIndex -ne -1) {
        $sirContent = $sirContent.Substring(0, $lastBraceIndex) + $newExecuteActionAndHelperMethods + "`n}"
    } else {
         Write-Error "Could not find closing brace to append methods (fallback)."
    }
}

Set-Content -Path $sirPath -Value $sirContent -Force
Write-Host "Updated $sirPath with new _ExecuteAction and GetOrElse."

# Part 3: Modify playbooks/malware_playbook.json
$playbookPath = "playbooks/malware_playbook.json"
$malwarePlaybookContent = Get-Content $playbookPath | ConvertFrom-Json

$newSteps = @(
    @{
        id = "malware_step4_logtofile"
        name = "Log Incident Details to File"
        actionType = "RunPowerShellScript"
        parameters = @{
            scriptPath = "./scripts/actions/LogToFile.ps1"
            FilePath = "./logs/incident_actions.log"
            Message = "Malware incident details for review. DeviceId: %%incident.DeviceId%%" # Example of placeholder
            IncidentId = "%%incident.Id%%"
            LogLevel = "Warning"
        }
        onSuccess = "malware_step5_testapi"
    },
    @{
        id = "malware_step5_testapi"
        name = "Test Public API Call"
        actionType = "InvokeBasicRestMethod"
        parameters = @{
            uri = "https://jsonplaceholder.typicode.com/todos/1"
            method = "GET"
        }
    }
)

$malwarePlaybookContent.steps += $newSteps

if ($malwarePlaybookContent.steps.Count -gt 2) {
    $linkingStepIndex = -1
    for($i=0; $i -lt $malwarePlaybookContent.steps.Count; $i++) {
        if ($malwarePlaybookContent.steps[$i].id -eq "malware_step3") {
            $linkingStepIndex = $i
            break
        }
    }
    if ($linkingStepIndex -ne -1) {
        $malwarePlaybookContent.steps[$linkingStepIndex].onSuccess = "malware_step4_logtofile"
    } else {
        Write-Warning "Could not find malware_step3 to link new steps in $playbookPath"
    }
}

$malwarePlaybookContent | ConvertTo-Json -Depth 10 | Set-Content -Path $playbookPath -Force # Increased depth
Write-Host "Updated $playbookPath with new action steps."

Write-Host "Subtask 'Enhance SecurityIncidentResponder._ExecuteAction for Real Actions' completed."
echo "---DONE---"
