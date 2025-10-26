package test

import (
	"fmt"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestAzureKeyVaultModule(t *testing.T) {
	t.Parallel()

	MultiTenantTestRunner(t, func(t *testing.T, config TestConfig) {
		SetupAzureAuth(t, config)
		CreateResourceGroup(t, config)
		
		uniqueID := config.UniqueID
		expectedKeyVaultName := fmt.Sprintf("kv-test-%s", uniqueID)
		
		terraformDir := filepath.Join("..", "..", "modules", "azure-key-vault-module")
		
		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: terraformDir,
			Vars: map[string]interface{}{
				"key_vault_name":                      expectedKeyVaultName,
				"location":                           config.Region,
				"resource_group_name":                fmt.Sprintf("%s-%s", config.ResourceGroup, uniqueID),
				"tenant_id":                          config.TenantID,
				"sku_name":                           "standard",
				"enabled_for_disk_encryption":        true,
				"enabled_for_deployment":             true,
				"enabled_for_template_deployment":    true,
				"purge_protection_enabled":           true,
				"soft_delete_retention_days":         90,
				"public_network_access_enabled":      false,
			},
			EnvVars: map[string]string{
				"ARM_SUBSCRIPTION_ID": config.SubscriptionID,
				"ARM_TENANT_ID":      config.TenantID,
			},
		})

		defer terraform.Destroy(t, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)

		// Validate Key Vault
		keyVaultName := terraform.Output(t, terraformOptions, "key_vault_name")
		assert.Equal(t, expectedKeyVaultName, keyVaultName)

		// Validate purge protection
		keyVault := azure.GetKeyVault(t, fmt.Sprintf("%s-%s", config.ResourceGroup, uniqueID), keyVaultName, config.SubscriptionID)
		assert.True(t, *keyVault.Properties.EnablePurgeProtection)

		// Validate soft delete
		assert.True(t, *keyVault.Properties.EnableSoftDelete)
		assert.Equal(t, int32(90), *keyVault.Properties.SoftDeleteRetentionInDays)

		// Validate public network access is disabled
		assert.Equal(t, "Disabled", string(keyVault.Properties.PublicNetworkAccess))

		// Validate RBAC is enabled
		assert.True(t, *keyVault.Properties.EnableRbacAuthorization)

		// Security compliance validation
		ValidateSecurityCompliance(t, terraformOptions)
		
		// Validate network ACLs
		assert.NotNil(t, keyVault.Properties.NetworkAcls)
		assert.Equal(t, "Deny", string(keyVault.Properties.NetworkAcls.DefaultAction))
	})
}