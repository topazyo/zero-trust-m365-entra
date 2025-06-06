class ComplianceMonitor {
    [string]$TenantId
    [hashtable]$ComplianceFrameworks
    [System.Collections.Generic.List[string]]$Violations
    hidden [object]$GraphConnection

    ComplianceMonitor([string]$tenantId, [string]$frameworksPath) {
        $this.TenantId = $tenantId
        $this.LoadComplianceFrameworks($frameworksPath)
        $this.Violations = [System.Collections.Generic.List[string]]::new()
    }

    [hashtable]RunComplianceCheck() {
        $results = @{
            Timestamp = [DateTime]::UtcNow
            Status = "Compliant"
            Violations = @()
            Recommendations = @()
        }

        foreach ($framework in $this.ComplianceFrameworks.Keys) {
            $frameworkResults = $this.EvaluateFramework($framework)
            if (-not $frameworkResults.Compliant) {
                $results.Status = "NonCompliant"
                $results.Violations += $frameworkResults.Violations
                $results.Recommendations += $frameworkResults.Recommendations
            }
        }

        $this.LogComplianceResults($results)
        return $results
    }

    [hashtable]EvaluateFramework([string]$framework) {
        $rules = $this.ComplianceFrameworks[$framework]
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
}