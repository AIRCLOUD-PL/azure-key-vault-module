# Azure Key Vault Module - Enterprise Edition
# This module creates a comprehensive Key Vault with advanced security features

locals {
  # Naming convention following Microsoft CAF
  name_prefix = var.name_prefix != "" ? var.name_prefix : "kv-${var.environment}-${var.location_short}"
  kv_name     = var.custom_name != "" ? var.custom_name : "${local.name_prefix}${var.name_suffix}"

  # Default tags
  default_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Module      = "key-vault"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    CreatedBy   = var.created_by
  }

  # Merge tags
  tags = merge(local.default_tags, var.additional_tags)

  # Network ACLs configuration
  network_acls = var.enable_network_acls ? {
    bypass                     = var.network_acls_bypass
    default_action             = var.network_acls_default_action
    ip_rules                   = var.network_acls_ip_rules
    virtual_network_subnet_ids = var.network_acls_subnet_ids
  } : null

  # RBAC configuration
  rbac_enabled = var.enable_rbac_authorization
}

# Data sources
data "azurerm_client_config" "current" {}

# Key Vault Resource
resource "azurerm_key_vault" "this" {
  name                            = local.kv_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.sku_name
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = local.rbac_enabled
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  public_network_access_enabled   = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = local.network_acls != null ? [local.network_acls] : []
    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }

  dynamic "contact" {
    for_each = var.contacts
    content {
      email = contact.value.email
      name  = contact.value.name
      phone = contact.value.phone
    }
  }

  tags = local.tags
}

# Access Policies (when RBAC is not enabled)
resource "azurerm_key_vault_access_policy" "this" {
  for_each = local.rbac_enabled ? {} : var.access_policies

  key_vault_id = azurerm_key_vault.this.id

  tenant_id = each.value.tenant_id
  object_id = each.value.object_id

  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
  storage_permissions     = each.value.storage_permissions
}

# RBAC Role Assignments (when RBAC is enabled)
resource "azurerm_role_assignment" "key_vault_administrator" {
  for_each = local.rbac_enabled ? { for idx, principal_id in var.rbac_administrators : idx => principal_id } : {}

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "key_vault_secrets_officer" {
  for_each = local.rbac_enabled ? { for idx, principal_id in var.rbac_secrets_officers : idx => principal_id } : {}

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  for_each = local.rbac_enabled ? { for idx, principal_id in var.rbac_secrets_users : idx => principal_id } : {}

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "key_vault_crypto_officer" {
  for_each = local.rbac_enabled ? { for idx, principal_id in var.rbac_crypto_officers : idx => principal_id } : {}

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "key_vault_crypto_user" {
  for_each = local.rbac_enabled ? { for idx, principal_id in var.rbac_crypto_users : idx => principal_id } : {}

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "key_vault_certificates_officer" {
  for_each = local.rbac_enabled ? { for idx, principal_id in var.rbac_certificates_officers : idx => principal_id } : {}

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = each.value
}

# Keys
resource "azurerm_key_vault_key" "this" {
  for_each = var.keys

  name         = each.value.name
  key_vault_id = azurerm_key_vault.this.id

  key_type        = each.value.key_type
  key_size        = each.value.key_size
  key_opts        = each.value.key_opts
  curve           = each.value.curve
  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date

  dynamic "rotation_policy" {
    for_each = each.value.rotation_policy != null ? [each.value.rotation_policy] : []
    content {
      automatic {
        time_before_expiry = rotation_policy.value.time_before_expiry
      }
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry
    }
  }

  tags = merge(local.tags, each.value.tags)
}

# Secrets
resource "azurerm_key_vault_secret" "this" {
  for_each = var.secrets

  name         = each.value.name
  value        = each.value.value
  key_vault_id = azurerm_key_vault.this.id

  content_type    = each.value.content_type
  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date

  tags = merge(local.tags, each.value.tags)

  depends_on = [azurerm_key_vault_access_policy.this]
}

# Certificates
resource "azurerm_key_vault_certificate" "this" {
  for_each = var.certificates

  name         = each.value.name
  key_vault_id = azurerm_key_vault.this.id

  certificate_policy {
    issuer_parameters {
      name = each.value.issuer_parameters.name
    }

    key_properties {
      exportable = each.value.key_properties.exportable
      key_size   = each.value.key_properties.key_size
      key_type   = each.value.key_properties.key_type
      reuse_key  = each.value.key_properties.reuse_key
    }

    secret_properties {
      content_type = each.value.secret_properties.content_type
    }

    x509_certificate_properties {
      extended_key_usage = each.value.x509_certificate_properties.extended_key_usage
      key_usage          = each.value.x509_certificate_properties.key_usage
      subject            = each.value.x509_certificate_properties.subject
      validity_in_months = each.value.x509_certificate_properties.validity_in_months

      subject_alternative_names {
        dns_names = each.value.x509_certificate_properties.subject_alternative_names.dns_names
        emails    = each.value.x509_certificate_properties.subject_alternative_names.emails
        upns      = each.value.x509_certificate_properties.subject_alternative_names.upns
      }
    }
  }

  tags = merge(local.tags, each.value.tags)

  depends_on = [azurerm_key_vault_access_policy.this]
}

# Private Endpoint
resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${local.kv_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${local.kv_name}-pe-connection"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_ids != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  tags = local.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${local.kv_name}-diagnostics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_logs
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.diagnostic_metrics
    content {
      category = metric.value
      enabled  = true
    }
  }
}

# Management Lock
resource "azurerm_management_lock" "this" {
  count = var.enable_resource_lock ? 1 : 0

  name       = "${local.kv_name}-lock"
  scope      = azurerm_key_vault.this.id
  lock_level = var.resource_lock_level
  notes      = "Key Vault resource lock to prevent accidental deletion"
}