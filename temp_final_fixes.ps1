# Part 1: Modify playbooks/malware_playbook.json
$playbookPath = "playbooks/malware_playbook.json"
$malwarePlaybook = Get-Content $playbookPath | ConvertFrom-Json

# Find the RunPowerShellScript step
$runScriptStepModified = $false
for ($i = 0; $i -lt $malwarePlaybook.steps.Count; $i++) {
    if ($malwarePlaybook.steps[$i].actionType -eq "RunPowerShellScript") {
        if ($malwarePlaybook.steps[$i].id -eq "malware_step4_logtofile") {
            Write-Host "Found RunPowerShellScript step (malware_step4_logtofile) to modify in playbook."
            $oldParams = $malwarePlaybook.steps[$i].parameters

            $newStepParams = @{
                scriptPath = $oldParams.scriptPath
                scriptParameters = @{
                    FilePath = $oldParams.FilePath
                    IncidentId = "%%incident.Id%%"
                    Message = "Malware incident details for review via LogToFile.ps1." # Simplified
                    LogLevel = $oldParams.LogLevel
                }
            }
            $malwarePlaybook.steps[$i].parameters = $newStepParams
            $runScriptStepModified = $true
            Write-Host "Restructured parameters for RunPowerShellScript step."
            break
        }
    }
}
if (-not $runScriptStepModified) {
    Write-Warning "Could not find the specific RunPowerShellScript step (malware_step4_logtofile) in $playbookPath to modify."
}

$malwarePlaybook | ConvertTo-Json -Depth 10 | Set-Content -Path $playbookPath -Force
Write-Host "Updated $playbookPath."

# Part 2: _ExecuteAction in SecurityIncidentResponder.ps1 is assumed to be correct from previous full overwrite.
# No changes to SIR in this script anymore. Diagnostic logging removed.
Write-Host "Skipping direct modification of SecurityIncidentResponder.ps1 in this script; assumed correct from prior overwrite."

Write-Host "Fix script finished."
echo "---FIX SCRIPT DONE---"
