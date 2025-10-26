# Key Vault Module - Azure Policy Assignments
# This file contains Azure Policy assignments for Key Vault security and compliance

# Data sources for policies
data "azurerm_policy_definition" "key_vault_purge_protection" {
  display_name = "Key vaults should have purge protection enabled"
}

data "azurerm_policy_definition" "key_vault_soft_delete" {
  display_name = "Key vaults should have soft delete enabled"
}

data "azurerm_policy_definition" "key_vault_firewall" {
  display_name = "Key Vault should use a virtual network service endpoint"
}

data "azurerm_policy_definition" "key_vault_rbac" {
  display_name = "Azure Key Vault should disable public network access"
}

data "azurerm_policy_definition" "key_vault_managed_hsm" {
  display_name = "Resource logs in Key Vault should be enabled"
}

data "azurerm_policy_definition" "key_vault_private_endpoint" {
  display_name = "Key Vault should use private link"
}

# Policy Assignments
resource "azurerm_resource_group_policy_assignment" "key_vault_purge_protection" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "kv-purge-protection"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.key_vault_purge_protection.id

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "key_vault_soft_delete" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "kv-soft-delete"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.key_vault_soft_delete.id

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "key_vault_firewall" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "kv-firewall"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.key_vault_firewall.id

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "key_vault_private_network" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "kv-private-network"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.key_vault_rbac.id

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "key_vault_logging" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "kv-logging"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.key_vault_managed_hsm.id

  parameters = jsonencode({
    effect = {
      value = "DeployIfNotExists"
    }
    profileName = {
      value = "setByPolicy"
    }
    logAnalyticsWorkspaceId = {
      value = var.log_analytics_workspace_id
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "key_vault_private_link" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "kv-private-link"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.key_vault_private_endpoint.id

  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })
}

# Custom Policy Definitions for Key Vault
resource "azurerm_policy_definition" "key_vault_key_rotation" {
  count = var.enable_custom_policies ? 1 : 0

  name         = "key-vault-key-rotation-policy"
  policy_type  = "Custom"
  mode         = "Microsoft.KeyVault.Data"
  display_name = "Key Vault keys should have automatic rotation enabled"

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.KeyVault/vaults/keys"
    }
    then = {
      effect = "AuditIfNotExists"
      details = {
        type = "Microsoft.KeyVault/vaults/keys"
        existenceCondition = {
          field  = "Microsoft.KeyVault/vaults/keys/rotationPolicy"
          exists = true
        }
      }
    }
  })
}

resource "azurerm_policy_definition" "key_vault_secret_expiration" {
  count = var.enable_custom_policies ? 1 : 0

  name         = "key-vault-secret-expiration-policy"
  policy_type  = "Custom"
  mode         = "Microsoft.KeyVault.Data"
  display_name = "Key Vault secrets should have expiration dates set"

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.KeyVault/vaults/secrets"
    }
    then = {
      effect = "Audit"
      details = {
        type = "Microsoft.KeyVault/vaults/secrets"
        existenceCondition = {
          field  = "Microsoft.KeyVault/vaults/secrets/attributes.exp"
          exists = true
        }
      }
    }
  })
}

resource "azurerm_policy_definition" "key_vault_certificate_auto_renewal" {
  count = var.enable_custom_policies ? 1 : 0

  name         = "key-vault-certificate-auto-renewal-policy"
  policy_type  = "Custom"
  mode         = "Microsoft.KeyVault.Data"
  display_name = "Key Vault certificates should have auto-renewal enabled"

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.KeyVault/vaults/certificates"
    }
    then = {
      effect = "AuditIfNotExists"
      details = {
        type = "Microsoft.KeyVault/vaults/certificates"
        existenceCondition = {
          field = "Microsoft.KeyVault/vaults/certificates/policy.issuer.name"
          in    = [" DigiCert", "GlobalSign", "Let's Encrypt"]
        }
      }
    }
  })
}

# Initiative Definition for Key Vault Security
resource "azurerm_policy_set_definition" "key_vault_security_initiative" {
  count = var.enable_policy_initiative ? 1 : 0

  name         = "key-vault-security-initiative"
  policy_type  = "Custom"
  display_name = "Key Vault Enterprise Security Initiative"

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.key_vault_purge_protection.id
    parameter_values = jsonencode({
      effect = {
        value = "Deny"
      }
    })
  }

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.key_vault_soft_delete.id
    parameter_values = jsonencode({
      effect = {
        value = "Deny"
      }
    })
  }

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.key_vault_private_endpoint.id
    parameter_values = jsonencode({
      effect = {
        value = "Deny"
      }
    })
  }

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.key_vault_managed_hsm.id
    parameter_values = jsonencode({
      effect = {
        value = "DeployIfNotExists"
      }
      profileName = {
        value = "setByPolicy"
      }
      logAnalyticsWorkspaceId = {
        value = var.log_analytics_workspace_id
      }
    })
  }
}

# Initiative Assignment
resource "azurerm_resource_group_policy_assignment" "key_vault_security_initiative" {
  count = var.enable_policy_initiative ? 1 : 0

  name                 = "kv-security-initiative"
  resource_group_id    = var.resource_group_id
  policy_definition_id = azurerm_policy_set_definition.key_vault_security_initiative[0].id

  parameters = jsonencode({
    logAnalyticsWorkspaceId = {
      value = var.log_analytics_workspace_id
    }
  })
}