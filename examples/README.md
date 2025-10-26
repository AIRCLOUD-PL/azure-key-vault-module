# Key Vault Module - Examples

This directory contains examples for deploying the Key Vault module in various enterprise scenarios.

## Examples Overview

### 1. Basic Key Vault with RBAC
A simple Key Vault with RBAC authorization enabled.

```hcl
module "key_vault_basic" {
  source = "../"

  resource_group_name = "rg-enterprise-kv"
  location           = "East US"
  location_short     = "eus"
  environment        = "prod"

  # RBAC Authorization
  enable_rbac_authorization = true
  rbac_administrators      = [data.azurerm_client_config.current.object_id]

  # Basic security settings
  sku_name                   = "premium"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  # Network security
  enable_network_acls = true
  network_acls_default_action = "Deny"

  # Monitoring
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  # Resource lock
  enable_resource_lock = true

  tags = {
    BusinessUnit = "IT"
    CostCenter   = "12345"
    Owner        = "platform-team"
  }
}
```

### 2. Enterprise Key Vault with Keys, Secrets, and Certificates
A comprehensive Key Vault with encryption keys, secrets, and certificates.

```hcl
module "key_vault_enterprise" {
  source = "../"

  resource_group_name = "rg-enterprise-kv"
  location           = "East US"
  location_short     = "eus"
  environment        = "prod"

  # RBAC Authorization
  enable_rbac_authorization = true
  rbac_administrators      = [data.azurerm_client_config.current.object_id]
  rbac_crypto_officers     = [azuread_group.crypto_officers.object_id]
  rbac_secrets_users       = [azuread_group.application_team.object_id]

  # Security settings
  sku_name                   = "premium"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  public_network_access_enabled = false

  # Network security
  enable_network_acls = true
  network_acls_default_action = "Deny"
  network_acls_subnet_ids = [azurerm_subnet.keyvault_subnet.id]

  # Private endpoint
  enable_private_endpoint = true
  private_endpoint_subnet_id = azurerm_subnet.private_endpoints.id
  private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]

  # Encryption Keys
  keys = {
    "app-encryption-key" = {
      name     = "app-encryption-key"
      key_type = "RSA"
      key_size = 2048
      key_opts = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
      rotation_policy = {
        expire_after         = "P1Y"
        notify_before_expiry = "P30D"
      }
      tags = {
        Purpose = "Application Encryption"
        Rotation = "Automatic"
      }
    }
    "data-encryption-key" = {
      name     = "data-encryption-key"
      key_type = "RSA"
      key_size = 3072
      key_opts = ["decrypt", "encrypt", "unwrapKey", "wrapKey"]
      rotation_policy = {
        expire_after         = "P2Y"
        notify_before_expiry = "P60D"
      }
      tags = {
        Purpose = "Data Encryption"
        Compliance = "PCI-DSS"
      }
    }
  }

  # Secrets
  secrets = {
    "database-connection-string" = {
      name         = "database-connection-string"
      value        = "Server=tcp:sql-server.database.windows.net;Database=myDB;User ID=user;Password=password;Encrypt=true;"
      content_type = "text/plain"
      expiration_date = "2024-12-31T23:59:59Z"
      tags = {
        Type = "Connection String"
        Environment = "Production"
      }
    }
    "api-key" = {
      name         = "external-api-key"
      value        = "sk-1234567890abcdef"
      content_type = "text/plain"
      tags = {
        Service = "External API"
        Rotation = "Manual"
      }
    }
  }

  # Certificates
  certificates = {
    "ssl-certificate" = {
      name = "wildcard-domain-com"
      issuer_parameters = {
        name = "DigiCert"
      }
      key_properties = {
        exportable = false
        key_size   = 2048
        key_type   = "RSA"
        reuse_key  = false
      }
      secret_properties = {
        content_type = "application/x-pkcs12"
      }
      x509_certificate_properties = {
        extended_key_usage = ["1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2"]
        key_usage          = ["cRLSign", "dataEncipherment", "digitalSignature", "keyAgreement", "keyCertSign", "keyEncipherment"]
        subject            = "CN=*.domain.com"
        validity_in_months = 12
        subject_alternative_names = {
          dns_names = ["*.domain.com", "domain.com"]
          emails    = []
          upns      = []
        }
      }
      tags = {
        Type = "SSL Certificate"
        Issuer = "DigiCert"
      }
    }
  }

  # Certificate contacts
  contacts = [
    {
      email = "security@domain.com"
      name  = "Security Team"
      phone = "+1-555-0123"
    }
  ]

  # Monitoring
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
  diagnostic_logs = [
    "AuditEvent",
    "AzurePolicyEvaluationDetails"
  ]
  diagnostic_metrics = [
    "AllMetrics"
  ]

  # Resource lock
  enable_resource_lock = true

  # Azure Policy
  enable_policy_assignments = true
  enable_policy_initiative  = true

  tags = {
    BusinessUnit    = "IT"
    CostCenter      = "12345"
    Owner           = "platform-team"
    Compliance      = "SOX"
    DataSensitivity = "High"
  }
}
```

### 3. Key Vault with Access Policies (Legacy)
Key Vault using access policies instead of RBAC (for backward compatibility).

```hcl
module "key_vault_access_policies" {
  source = "../"

  resource_group_name = "rg-legacy-kv"
  location           = "East US"
  location_short     = "eus"
  environment        = "prod"

  # Access Policies (legacy)
  enable_rbac_authorization = false
  access_policies = {
    "platform-team" = {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = azuread_group.platform_team.object_id
      key_permissions = [
        "Get", "List", "Create", "Delete", "Update",
        "Import", "Backup", "Restore", "Recover", "Purge"
      ]
      secret_permissions = [
        "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover", "Purge"
      ]
      certificate_permissions = [
        "Get", "List", "Create", "Delete", "Update",
        "Import", "Backup", "Restore", "Recover", "Purge",
        "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
      ]
      storage_permissions = [
        "Get", "List", "Set", "Delete", "Update", "RegenerateKey", "Recover", "Purge"
      ]
    }
    "application-service-principal" = {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = azuread_service_principal.app_sp.object_id
      key_permissions         = ["Get", "List", "Decrypt", "Encrypt"]
      secret_permissions      = ["Get", "List"]
      certificate_permissions = ["Get", "List"]
      storage_permissions     = []
    }
  }

  # Security settings
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  # Network security
  enable_network_acls = true
  network_acls_default_action = "Allow"
  network_acls_ip_rules = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  # Monitoring
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  tags = {
    BusinessUnit = "IT"
    Migration   = "Access Policies to RBAC"
  }
}
```

### 4. Development Environment Key Vault
Minimal Key Vault configuration for development environments.

```hcl
module "key_vault_dev" {
  source = "../"

  resource_group_name = "rg-dev-kv"
  location           = "East US"
  location_short     = "eus"
  environment        = "dev"

  # RBAC Authorization
  enable_rbac_authorization = true
  rbac_administrators      = [data.azurerm_client_config.current.object_id]

  # Relaxed security for development
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  public_network_access_enabled = true

  # Minimal network restrictions
  enable_network_acls = false

  # Basic monitoring
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.dev.id

  # No resource lock for development
  enable_resource_lock = false

  # No Azure Policy for development
  enable_policy_assignments = false
  enable_policy_initiative  = false

  # Sample secrets for development
  secrets = {
    "dev-api-key" = {
      name  = "dev-api-key"
      value = "dev-key-12345"
      tags = {
        Environment = "Development"
        Temporary   = "true"
      }
    }
  }

  tags = {
    Environment = "Development"
    CostCenter  = "DevOps"
    Temporary   = "true"
  }
}
```

## Complete Example Implementation

For a complete working example, see the `complete-example` directory which includes:

- Full Terraform configuration
- Required Azure resources (Resource Group, Virtual Network, Log Analytics, etc.)
- Azure AD groups and role assignments
- Private DNS zones
- Monitoring and alerting setup

## Usage Notes

1. **RBAC vs Access Policies**: Prefer RBAC authorization for new deployments. Access policies are maintained for backward compatibility.

2. **Network Security**: Always configure network ACLs or private endpoints. Avoid public access except for development environments.

3. **Key Rotation**: Configure automatic key rotation for production keys to maintain security compliance.

4. **Certificate Management**: Use certificate contacts for automated certificate lifecycle management.

5. **Monitoring**: Enable diagnostic settings and configure appropriate log retention based on compliance requirements.

6. **Resource Locks**: Use resource locks in production to prevent accidental deletion.

7. **Azure Policy**: Enable policy assignments for automated compliance monitoring and enforcement.

## Security Best Practices

- Enable purge protection and soft delete
- Use premium SKU for production workloads
- Configure network restrictions (ACLs or private endpoints)
- Enable diagnostic logging and monitoring
- Use RBAC with least privilege principle
- Configure key rotation policies
- Set appropriate retention periods
- Use resource locks to prevent deletion
- Enable Azure Policy for compliance