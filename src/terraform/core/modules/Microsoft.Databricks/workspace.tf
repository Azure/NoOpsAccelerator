# Tested with :  AzureRM version 2.74.0
# Ref : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace

resource "azurerm_databricks_workspace" "ws" {
  name                        = var.name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  sku                         = try(var.settings.sku, "standard")
  managed_resource_group_name = try(var.settings.managed_resource_group_name, null)
  tags                        = try(local.tags, null)

  infrastructure_encryption_enabled     = try(var.settings.infrastructure_encryption_enabled, null)
  public_network_access_enabled         = try(var.settings.public_network_access_enabled, null)
  network_security_group_rules_required = try(var.settings.network_security_group_rules_required, null)
  customer_managed_key_enabled          = try(var.settings.customer_managed_key_enabled, null)

  dynamic "custom_parameters" {
    for_each = try(var.settings.custom_parameters, null) == null ? [] : [1]

    content {
      no_public_ip             = try(var.settings.custom_parameters.no_public_ip, false)
      vnet_address_prefix      = try(var.settings.custom_parameters.vnet_address_prefix, null)
      nat_gateway_name         = try(var.settings.custom_parameters.nat_gateway_name, null)
      public_ip_name           = try(var.settings.custom_parameters.public_ip_name, null)
      storage_account_name     = try(var.settings.custom_parameters.storage_account_name, null)
      storage_account_sku_name = try(var.settings.custom_parameters.storage_account_sku_name, null)

      virtual_network_id = can(var.settings.custom_parameters.virtual_network_id) || can(var.settings.custom_parameters.vnet_key) == false ? try(var.settings.custom_parameters.virtual_network_id, null) : var.vnets[try(var.settings.custom_parameters.lz_key, var.client_config.landingzone_key)][var.settings.custom_parameters.vnet_key].id
      public_subnet_name = can(var.settings.custom_parameters.public_subnet_name) || can(var.settings.custom_parameters.vnet_key) == false ? try(var.settings.custom_parameters.public_subnet_name, null) : var.vnets[try(var.settings.custom_parameters.lz_key, var.client_config.landingzone_key)][var.settings.custom_parameters.vnet_key].subnets[var.settings.custom_parameters.public_subnet_key].name

      #the NSG-association ID is the subnet-id, so it can be simplified:
      public_subnet_network_security_group_association_id = can(var.settings.custom_parameters.public_subnet_network_security_group_association_id) || can(var.settings.custom_parameters.public_subnet_key) == false ? try(var.settings.custom_parameters.public_subnet_network_security_group_association_id, null) : var.vnets[try(var.settings.custom_parameters.lz_key, var.client_config.landingzone_key)][var.settings.custom_parameters.vnet_key].subnets[var.settings.custom_parameters.public_subnet_key].id
      private_subnet_name                                 = can(var.settings.custom_parameters.private_subnet_name) || can(var.settings.custom_parameters.private_subnet_key) == false ? try(var.settings.custom_parameters.private_subnet_name, null) : var.vnets[try(var.settings.custom_parameters.lz_key, var.client_config.landingzone_key)][var.settings.custom_parameters.vnet_key].subnets[var.settings.custom_parameters.private_subnet_key].name

      #the NSG-association ID is the subnet-id, so it can be simplified:
      private_subnet_network_security_group_association_id = can(var.settings.custom_parameters.private_subnet_network_security_group_association_id) || can(var.settings.custom_parameters.public_subnet_key) == false ? try(var.settings.custom_parameters.private_subnet_network_security_group_association_id, null) : var.vnets[try(var.settings.custom_parameters.lz_key, var.client_config.landingzone_key)][var.settings.custom_parameters.vnet_key].subnets[var.settings.custom_parameters.public_subnet_key].id
    }
  }
}
