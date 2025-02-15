class RoleManager {
    [string]$TenantId
    [hashtable]$RoleDefinitions
    [System.Collections.Generic.Dictionary[string,object]]$RoleAssignments

    RoleManager([string]$tenantId) {
        $this.TenantId = $tenantId
        $this.InitializeRoleDefinitions()
        $this.RoleAssignments = [System.Collections.Generic.Dictionary[string,object]]::new()
    }

    [void]CreateCustomRole([hashtable]$roleDefinition) {
        try {
            # Validate role definition
            $this.ValidateRoleDefinition($roleDefinition)

            # Create role with least privilege principle
            $roleParams = @{
                DisplayName = $roleDefinition.Name
                Description = $roleDefinition.Description
                Permissions = $this.FilterMinimumRequiredPermissions($roleDefinition.Permissions)
                AssignableScopes = $roleDefinition.Scopes
            }

            $newRole = New-AzureADMSRoleDefinition @roleParams
            $this.RoleDefinitions[$newRole.Id] = $newRole

            # Setup monitoring for this role
            $this.ConfigureRoleMonitoring($newRole.Id)
        }
        catch {
            Write-Error "Failed to create custom role: $_"
            throw
        }
    }

    [void]AssignRoleWithJIT([string]$userId, [string]$roleId, [int]$durationHours) {
        try {
            # Validate JIT request
            $this.ValidateJITRequest($userId, $roleId)

            # Create time-bound assignment
            $assignment = @{
                PrincipalId = $userId
                RoleDefinitionId = $roleId
                ExpirationTime = (Get-Date).AddHours($durationHours)
                JustificationRequired = $true
                MFARequired = $true
            }

            $this.CreateRoleAssignment($assignment)
            $this.EnableJITMonitoring($assignment)
        }
        catch {
            Write-Error "Failed to assign JIT role: $_"
            throw
        }
    }

    [void]ReviewRoleAssignments() {
        foreach ($assignment in $this.RoleAssignments.Values) {
            if ($this.RequiresReview($assignment)) {
                $reviewResult = $this.PerformAccessReview($assignment)
                if (-not $reviewResult.Approved) {
                    $this.RevokeRoleAssignment($assignment)
                }
            }
        }
    }
}