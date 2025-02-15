Describe "Zero Trust Access Control Integration Tests" {
    BeforeAll {
        $testConfig = @{
            TenantId = $env:TEST_TENANT_ID
            TestUserId = $env:TEST_USER_ID
            TestRoleId = $env:TEST_ROLE_ID
        }

        $permissionManager = [PermissionManager]::new($testConfig.TenantId)
    }

    Context "Zero Trust Policy Application" {
        It "Should apply time-bound access successfully" {
            # Arrange
            $userId = $testConfig.TestUserId
            $roleId = $testConfig.TestRoleId

            # Act
            $result = $permissionManager.ApplyZeroTrustPolicy($userId, $roleId)

            # Assert
            $result.Status | Should -Be "Success"
            $access = $permissionManager.GetCurrentAccess($userId)
            $access.Timebound | Should -Be $true
            $access.RequireMFA | Should -Be $true
        }

        It "Should detect and prevent privilege escalation" {
            # Arrange
            $userId = $testConfig.TestUserId
            $elevatedRoleId = "GlobalAdmin"

            # Act & Assert
            { $permissionManager.ApplyZeroTrustPolicy($userId, $elevatedRoleId) } | 
                Should -Throw -ErrorId "PrivilegeEscalationAttempt"
        }
    }
}