class ExternalAccessHandler {
    [string]$TenantId
    [hashtable]$SecurityPolicies
    hidden [object]$GraphConnection

    ExternalAccessHandler([string]$tenantId, [string]$policyPath) {
        $this.TenantId = $tenantId
        $this.LoadSecurityPolicies($policyPath)
        $this.InitializeConnection()
    }

    [void]ProcessExternalRequest([object]$request) {
        try {
            # Validate request
            $this.ValidateRequest($request)

            # Risk assessment
            $riskScore = $this.AssessRisk($request)

            # Apply appropriate controls
            switch ($riskScore) {
                {$_ -gt 80} {
                    $this.ApplyHighRiskControls($request)
                }
                {$_ -gt 50} {
                    $this.ApplyMediumRiskControls($request)
                }
                default {
                    $this.ApplyBaselineControls($request)
                }
            }

            # Setup monitoring
            $this.ConfigureMonitoring($request.UserId)

            # Documentation and logging
            $this.DocumentAccess($request)
        }
        catch {
            Write-Error "External access processing failed: $_"
            throw
        }
    }

    [int]AssessRisk([object]$request) {
        $riskFactors = @{
            GeographicLocation = $this.AssessLocationRisk($request.Location)
            AccessLevel = $this.AssessAccessLevelRisk($request.AccessLevel)
            PreviousHistory = $this.CheckPreviousAccess($request.UserId)
            DataSensitivity = $this.AssessDataSensitivity($request.Resources)
        }

        return $this.CalculateRiskScore($riskFactors)
    }
}