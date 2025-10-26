# Key Vault Module Outputs

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "key_vault_resource_group_name" {
  description = "The resource group name of the Key Vault"
  value       = azurerm_key_vault.this.resource_group_name
}

output "key_vault_location" {
  description = "The location of the Key Vault"
  value       = azurerm_key_vault.this.location
}

output "key_vault_tenant_id" {
  description = "The tenant ID of the Key Vault"
  value       = azurerm_key_vault.this.tenant_id
}

# Keys outputs
output "key_ids" {
  description = "Map of key names to key IDs"
  value = {
    for k, v in azurerm_key_vault_key.this : k => v.id
  }
}

output "key_versions" {
  description = "Map of key names to key versions"
  value = {
    for k, v in azurerm_key_vault_key.this : k => v.version
  }
}

output "key_public_keys" {
  description = "Map of key names to public key PEMs"
  value = {
    for k, v in azurerm_key_vault_key.this : k => v.public_key_pem
  }
  sensitive = true
}

# Secrets outputs
output "secret_ids" {
  description = "Map of secret names to secret IDs"
  value = {
    for k, v in azurerm_key_vault_secret.this : k => v.id
  }
}

output "secret_versions" {
  description = "Map of secret names to secret versions"
  value = {
    for k, v in azurerm_key_vault_secret.this : k => v.version
  }
}

# Certificates outputs
output "certificate_ids" {
  description = "Map of certificate names to certificate IDs"
  value = {
    for k, v in azurerm_key_vault_certificate.this : k => v.id
  }
}

output "certificate_versions" {
  description = "Map of certificate names to certificate versions"
  value = {
    for k, v in azurerm_key_vault_certificate.this : k => v.version
  }
}

output "certificate_thumbprints" {
  description = "Map of certificate names to certificate thumbprints"
  value = {
    for k, v in azurerm_key_vault_certificate.this : k => v.thumbprint
  }
}

# Private Endpoint outputs
output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.this[0].id : null
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address : null
}

# RBAC outputs
output "rbac_role_assignments" {
  description = "Map of RBAC role assignments created"
  value = merge(
    { for k, v in azurerm_role_assignment.key_vault_administrator : "administrator_${k}" => v.id },
    { for k, v in azurerm_role_assignment.key_vault_secrets_officer : "secrets_officer_${k}" => v.id },
    { for k, v in azurerm_role_assignment.key_vault_secrets_user : "secrets_user_${k}" => v.id },
    { for k, v in azurerm_role_assignment.key_vault_crypto_officer : "crypto_officer_${k}" => v.id },
    { for k, v in azurerm_role_assignment.key_vault_crypto_user : "crypto_user_${k}" => v.id },
    { for k, v in azurerm_role_assignment.key_vault_certificates_officer : "certificates_officer_${k}" => v.id }
  )
}

# Access Policies outputs
output "access_policy_ids" {
  description = "Map of access policy keys to policy IDs"
  value = {
    for k, v in azurerm_key_vault_access_policy.this : k => v.id
  }
}

# Diagnostic Settings outputs
output "diagnostic_setting_id" {
  description = "The ID of the diagnostic setting"
  value       = var.enable_diagnostic_settings ? azurerm_monitor_diagnostic_setting.this[0].id : null
}

# Resource Lock outputs
output "resource_lock_id" {
  description = "The ID of the resource lock"
  value       = var.enable_resource_lock ? azurerm_management_lock.this[0].id : null
}

# Resource information
output "resource_tags" {
  description = "Tags applied to the Key Vault"
  value       = azurerm_key_vault.this.tags
}

# Security information
output "purge_protection_enabled" {
  description = "Whether purge protection is enabled"
  value       = azurerm_key_vault.this.purge_protection_enabled
}

output "soft_delete_enabled" {
  description = "Whether soft delete is enabled"
  value       = azurerm_key_vault.this.soft_delete_retention_days > 0
}

output "network_acls_enabled" {
  description = "Whether network ACLs are enabled"
  value       = var.enable_network_acls
}

output "private_endpoint_enabled" {
  description = "Whether private endpoint is enabled"
  value       = var.enable_private_endpoint
}

output "rbac_enabled" {
  description = "Whether RBAC authorization is enabled"
  value       = var.enable_rbac_authorization
}