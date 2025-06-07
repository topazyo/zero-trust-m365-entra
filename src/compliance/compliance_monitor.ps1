class ComplianceMonitor {
    [string]$TenantId
    [hashtable]$ComplianceFrameworks
    [System.Collections.Generic.List[string]]$Violations
    hidden [object]$GraphConnection

    ComplianceMonitor([string]$tenantId, [string]$frameworksPath) {
        $this.TenantId = $tenantId
        $this.Violations = [System.Collections.Generic.List[string]]::new()
        # Ensure LoadComplianceFrameworks is called after Violations list is initialized,
        # though its current implementation doesn't depend on it.
        $this.LoadComplianceFrameworks($frameworksPath)
    }

    # --- Public Methods ---

    [hashtable]RunComplianceCheck() {
        $this.Violations.Clear() # Clear previous violations
        $results = @{
            Timestamp = [DateTime]::UtcNow
            Status = "Compliant"
            Violations = [System.Collections.Generic.List[string]]::new() # Use List for AddRange
            Recommendations = [System.Collections.Generic.List[string]]::new() # Use List for AddRange
        }

        if ($null -eq $this.ComplianceFrameworks -or $this.ComplianceFrameworks.Keys.Count -eq 0) {
            Write-Warning "No compliance frameworks loaded. Skipping compliance check."
            $results.Status = "Error_NoFrameworksLoaded"
            return $results
        }

        foreach ($frameworkName in $this.ComplianceFrameworks.Keys) {
            $frameworkResults = $this.EvaluateFramework($frameworkName) # Pass framework name
            if (-not $frameworkResults.Compliant) {
                $results.Status = "NonCompliant"
                if ($null -ne $frameworkResults.Violations) { $results.Violations.AddRange($frameworkResults.Violations) }
                if ($null -ne $frameworkResults.Recommendations) { $results.Recommendations.AddRange($frameworkResults.Recommendations) }
            }
        }

        # Update the class property $this.Violations for GenerateRemediationPlan
        if ($results.Violations.Count -gt 0) {
            $this.Violations.AddRange($results.Violations)
        }

        # Convert lists to arrays for the final returned hashtable
        $results.Violations = $results.Violations.ToArray()
        $results.Recommendations = $results.Recommendations.ToArray()

        $this.LogComplianceResults($results) # Call to new hidden method
        return $results
    }

    [hashtable]EvaluateFramework([string]$frameworkName) { # Parameter is frameworkName
        $rules = $this.ComplianceFrameworks[$frameworkName] # Corrected variable name here
        $_violations = @() # Renamed local variable
        $_recommendations = @() # Renamed local variable

        foreach ($rule in $rules) {
            try {
                $ruleResult = $this.EvaluateRule($rule)
                if (-not $ruleResult.Compliant) {
                    $_violations += $ruleResult.Violation
                    $_recommendations += $ruleResult.Recommendation
                }
            }
            catch {
                Write-Error "Failed to evaluate rule $($rule.Id): $_"
                continue
            }
        }

        return @{
            Compliant = ($_violations.Count -eq 0)
            Violations = $_violations
            Recommendations = $_recommendations
        }
    }

    [void]GenerateComplianceReport([string]$outputPath) {
        $report = @{
            GeneratedAt = [DateTime]::UtcNow
            TenantId = $this.TenantId
            ComplianceStatus = $this.RunComplianceCheck()
            RemediationPlan = $this.GenerateRemediationPlan()
        }

        $report | ConvertTo-Json -Depth 10 | Out-File $outputPath
    }

    # --- Hidden Helper Methods ---

    hidden [void] LoadComplianceFrameworks([string]$frameworksPath) {
        Write-Host "ComplianceMonitor.LoadComplianceFrameworks called with path: $frameworksPath"
        $this.ComplianceFrameworks = @{} # Initialize

        # Resolve frameworksPath relative to the script location (src/compliance/) to repo root, then to path
        $basePath = $null
        if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
            $basePath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
        } else { $basePath = Get-Location }
        $repoRoot = Join-Path -Path $basePath -ChildPath "../../"
        $resolvedFrameworksPath = Resolve-Path -Path (Join-Path -Path $repoRoot -ChildPath $frameworksPath) -ErrorAction SilentlyContinue

        if ($null -ne $resolvedFrameworksPath -and (Test-Path -Path $resolvedFrameworksPath -PathType Container)) {
            Get-ChildItem -Path $resolvedFrameworksPath -Filter "*.json" -File | ForEach-Object {
                try {
                    $frameworkNameFromFile = $_.BaseName # Use actual framework name from file
                    $frameworkContent = Get-Content -Path $_.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
                    if ($null -ne $frameworkContent) {
                        $this.ComplianceFrameworks[$frameworkNameFromFile] = $frameworkContent # Store under actual name
                        Write-Host "Loaded compliance framework '$frameworkNameFromFile' from $($_.FullName)"
                    } else {
                        Write-Warning "Framework file '$($_.FullName)' is empty or invalid JSON."
                    }
                } catch {
                    Write-Warning "Failed to load or parse framework file '$($_.FullName)': $($_.Exception.Message)"
                }
            }
            Write-Host "Loaded $($this.ComplianceFrameworks.Keys.Count) compliance frameworks from '$resolvedFrameworksPath'."
        } else {
            Write-Warning "Compliance frameworks path '$frameworksPath' (resolved to '$resolvedFrameworksPath') not found or not a directory. Using default frameworks."
        }

        if ($this.ComplianceFrameworks.Keys.Count -eq 0) {
            $this.ComplianceFrameworks = @{
                "CIS_Benchmark_L1" = @( # Array of rule objects
                    @{ RuleId="CIS1.1"; Description="Ensure MFA is enabled for all console users."; CheckType="Configuration"; Severity="Critical"; CurrentCheckValue_Placeholder="NotAllMFA"; ExpectedValue_Placeholder="AllMFA"},
                    @{ RuleId="CIS1.2"; Description="Ensure no root account access keys exist."; CheckType="Configuration"; Severity="Critical"; CurrentCheckValue_Placeholder="KeysExist"; ExpectedValue_Placeholder="NoKeys"}
                );
                "SOC2_Type2_Placeholder" = @(
                    @{ RuleId="SOC2.CC1.1"; Description="Control environment criteria (placeholder)."; CheckType="Process"; Severity="High"; CurrentCheckValue_Placeholder="PartialDocumentation"; ExpectedValue_Placeholder="FullDocumentation"}
                )
            }
            Write-Host "Loaded default/demo compliance frameworks."
        }
    }

    hidden [void] LogComplianceResults([object]$results) {
        Write-Host "ComplianceMonitor.LogComplianceResults called. Overall Status: $($results.Status)"
        # TODO: Log results to a persistent store (database, log file, SIEM).
        $violationsCount = if ($null -ne $results.Violations) {$results.Violations.Count} else {0}
        $recommendationsCount = if ($null -ne $results.Recommendations) {$results.Recommendations.Count} else {0}
        Write-Host "Simulated logging of compliance check results. Violations found: $violationsCount. Recommendations: $recommendationsCount."
        # Example: $results | ConvertTo-Json -Depth 5 | Out-File "./logs/compliance_check_$(Get-Date -Format 'yyyyMMddHHmmss').json"
    }

    hidden [object] EvaluateRule([object]$rule) { # Expects a rule object
        Write-Host "ComplianceMonitor.EvaluateRule called for RuleId: $($rule.RuleId) - $($rule.Description)"
        # TODO: Implement actual rule evaluation logic based on $rule.CheckType.
        # This would involve querying systems, configurations, logs, etc.
        # For now, simulate a result.
        $isCompliant = (Get-Random -Min 0 -Max 10) -gt 2 # ~80% compliant rate for simulation
        $violationMessage = $null
        $recommendationMessage = $null

        if (-not $isCompliant) {
            $violationMessage = "Violation for Rule '$($rule.RuleId)': Expected '$($rule.ExpectedValue_Placeholder)', but found '$($rule.CurrentCheckValue_Placeholder)' (simulated)."
            $recommendationMessage = "Recommendation for Rule '$($rule.RuleId)': Remediate to meet '$($rule.ExpectedValue_Placeholder)'."
            Write-Warning $violationMessage
        } else {
             Write-Host "Rule '$($rule.RuleId)' is compliant (simulated)."
        }

        return @{
            RuleId = $rule.RuleId
            Compliant = $isCompliant
            Violation = $violationMessage
            Recommendation = $recommendationMessage
            Timestamp = Get-Date
        }
    }

    hidden [object] GenerateRemediationPlan() {
        Write-Host "ComplianceMonitor.GenerateRemediationPlan called."
        # This would typically take the list of violations from the last compliance check.
        # For simplicity, it will generate a generic plan based on $this.Violations (which RunComplianceCheck populates).

        $planSteps = [System.Collections.Generic.List[object]]::new()
        if ($null -ne $this.Violations -and $this.Violations.Count -gt 0) {
            foreach ($violationText in $this.Violations) {
                # Extract rule ID or description from violation text for more specific steps if possible
                $ruleIdGuess = ""
                if ($violationText -match "Rule '([^']*)'") { $ruleIdGuess = $Matches[1] }
                else { $ruleIdGuess = "UnknownRuleRef_CheckViolationText" }

                $planSteps.Add(@{
                    StepId = "RemStep_$(Get-Random -Max 1000)"
                    Description = "Address violation: $violationText"
                    RuleReference = $ruleIdGuess
                    AssignedTo_Placeholder = "ComplianceTeam"
                    DueDate_Placeholder = (Get-Date).AddDays(14).ToString("yyyy-MM-dd")
                })
            }
        } else {
            $planSteps.Add(@{ StepId="NoViolations"; Description="No violations found, no remediation steps required."})
        }

        Write-Host "Generated remediation plan with $($planSteps.Count) steps (simulated)."
        return @{
            PlanGeneratedDate = Get-Date
            OverallStatus = if($this.Violations.Count -eq 0) {"NoActionNeeded"} else {"ActionRequired"}
            Steps = $planSteps.ToArray()
        }
    }
}