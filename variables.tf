# Key Vault Module Variables

# Naming and Resource Configuration
variable "name_prefix" {
  description = "Prefix for resource naming. If empty, defaults to 'kv-{environment}-{location_short}'"
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Suffix for resource naming"
  type        = string
  default     = ""
}

variable "custom_name" {
  description = "Custom name for the Key Vault. If provided, name_prefix and name_suffix are ignored"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for the Key Vault"
  type        = string
}

variable "location_short" {
  description = "Short name for the location (e.g., 'eus' for East US)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod, etc.)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "enterprise"
}

variable "created_by" {
  description = "Identifier of who created this resource"
  type        = string
  default     = "terraform"
}

variable "additional_tags" {
  description = "Additional tags to add to resources"
  type        = map(string)
  default     = {}
}

# Key Vault Configuration
variable "sku_name" {
  description = "SKU name for the Key Vault (standard or premium)"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

variable "enabled_for_deployment" {
  description = "Enable Key Vault for Azure Resource Manager deployment"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Enable Key Vault for disk encryption"
  type        = bool
  default     = true
}

variable "enabled_for_template_deployment" {
  description = "Enable Key Vault for ARM template deployment"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization instead of access policies"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for the Key Vault"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain deleted items"
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

# Network ACLs
variable "enable_network_acls" {
  description = "Enable network ACLs for the Key Vault"
  type        = bool
  default     = true
}

variable "network_acls_bypass" {
  description = "Bypass options for network ACLs"
  type        = string
  default     = "AzureServices"
  validation {
    condition     = contains(["None", "AzureServices"], var.network_acls_bypass)
    error_message = "Network ACLs bypass must be 'None' or 'AzureServices'."
  }
}

variable "network_acls_default_action" {
  description = "Default action for network ACLs"
  type        = string
  default     = "Deny"
  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "Network ACLs default action must be 'Allow' or 'Deny'."
  }
}

variable "network_acls_ip_rules" {
  description = "List of IP rules for network ACLs"
  type        = list(string)
  default     = []
}

variable "network_acls_subnet_ids" {
  description = "List of subnet IDs for network ACLs"
  type        = list(string)
  default     = []
}

# Access Policies (when RBAC is disabled)
variable "access_policies" {
  description = "List of access policies for the Key Vault"
  type = map(object({
    tenant_id               = string
    object_id               = string
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
    storage_permissions     = list(string)
  }))
  default = {}
}

# RBAC Configuration (when RBAC is enabled)
variable "rbac_administrators" {
  description = "List of principal IDs for Key Vault Administrator role"
  type        = list(string)
  default     = []
}

variable "rbac_secrets_officers" {
  description = "List of principal IDs for Key Vault Secrets Officer role"
  type        = list(string)
  default     = []
}

variable "rbac_secrets_users" {
  description = "List of principal IDs for Key Vault Secrets User role"
  type        = list(string)
  default     = []
}

variable "rbac_crypto_officers" {
  description = "List of principal IDs for Key Vault Crypto Officer role"
  type        = list(string)
  default     = []
}

variable "rbac_crypto_users" {
  description = "List of principal IDs for Key Vault Crypto User role"
  type        = list(string)
  default     = []
}

variable "rbac_certificates_officers" {
  description = "List of principal IDs for Key Vault Certificates Officer role"
  type        = list(string)
  default     = []
}

# Keys Configuration
variable "keys" {
  description = "Map of keys to create in the Key Vault"
  type = map(object({
    name            = string
    key_type        = string
    key_size        = optional(number)
    key_opts        = list(string)
    curve           = optional(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    rotation_policy = optional(object({
      time_before_expiry   = optional(string)
      expire_after         = optional(string)
      notify_before_expiry = optional(string)
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

# Secrets Configuration
variable "secrets" {
  description = "Map of secrets to create in the Key Vault"
  type = map(object({
    name            = string
    value           = string
    content_type    = optional(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
  }))
  default = {}
}

# Certificates Configuration
variable "certificates" {
  description = "Map of certificates to create in the Key Vault"
  type = map(object({
    name = string
    issuer_parameters = object({
      name = string
    })
    key_properties = object({
      exportable = bool
      key_size   = number
      key_type   = string
      reuse_key  = bool
    })
    secret_properties = object({
      content_type = string
    })
    x509_certificate_properties = object({
      extended_key_usage = list(string)
      key_usage          = list(string)
      subject            = string
      validity_in_months = number
      subject_alternative_names = object({
        dns_names = list(string)
        emails    = list(string)
        upns      = list(string)
      })
    })
    tags = optional(map(string), {})
  }))
  default = {}
}

# Contacts
variable "contacts" {
  description = "List of contacts for certificate management"
  type = list(object({
    email = string
    name  = optional(string)
    phone = optional(string)
  }))
  default = []
}

# Private Endpoint Configuration
variable "enable_private_endpoint" {
  description = "Enable private endpoint for the Key Vault"
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "List of private DNS zone IDs for the private endpoint"
  type        = list(string)
  default     = null
}

# Diagnostic Settings
variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for the Key Vault"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings"
  type        = string
  default     = null
}

variable "diagnostic_logs" {
  description = "List of diagnostic logs to enable"
  type        = list(string)
  default = [
    "AuditEvent",
    "AzurePolicyEvaluationDetails"
  ]
}

variable "diagnostic_metrics" {
  description = "List of diagnostic metrics to enable"
  type        = list(string)
  default = [
    "AllMetrics"
  ]
}

# Resource Lock
variable "enable_resource_lock" {
  description = "Enable resource lock for the Key Vault"
  type        = bool
  default     = true
}

variable "resource_lock_level" {
  description = "Level of the resource lock"
  type        = string
  default     = "CanNotDelete"
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.resource_lock_level)
    error_message = "Resource lock level must be 'CanNotDelete' or 'ReadOnly'."
  }
}

# Azure Policy Configuration
variable "enable_policy_assignments" {
  description = "Enable Azure Policy assignments for Key Vault"
  type        = bool
  default     = true
}

variable "resource_group_id" {
  description = "Resource group ID for policy assignments"
  type        = string
  default     = null
}

variable "enable_custom_policies" {
  description = "Enable custom Azure Policy definitions"
  type        = bool
  default     = false
}

variable "enable_policy_initiative" {
  description = "Enable Azure Policy initiative for Key Vault security"
  type        = bool
  default     = true
}