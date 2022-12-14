#################################
# Global Configuration
#################################

variable "location" {
  description = "The region for spoke network deployment"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which resources are created"
  type        = string
}

#################################
# Spoke Configuration
#################################

variable "spoke_vnetname" {
  description = "Virtual Network Name for the spoke network deployment"
  type        = string
}

variable "spoke_vnet_address_space" {
  description = "Address space prefixes for the spoke network"
  type        = list(string)
}

variable "spoke_subnets" {
  description = "A complex object that describes subnets for the spoke network"
  type = map(object({
    subnet_name                 = string
    subnet_address_space = list(string)
    service_endpoints    = list(string)

    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool

    network_security_group_rules = map(object({
      name                       = string
      priority                   = string
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = list(string)
      source_address_prefix      = list(string)
      destination_address_prefix = string
    }))   

    enable_ddos_protection  = bool
    ddos_protection_plan_id = string
  }))
}

variable "spoke_network_security_group_name" {
  description = "The name of the network security group"
  type        = string
}

variable "spoke_route_table_name" {
  description = "The name of the route table"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

#################################
# Firewall configuration section
#################################

variable "firewall_private_ip_address" {
  description = "The private IP address of the firewall"
  type        = string
  default     = ""
}

#################################
# Locks configuration section
#################################

variable "enable_resource_locks" {
  description = " Whether to enable resource locks on the resource group"
  type        = bool
  default     = false
}

variable "lock_level" {
  description = "The level of lock to apply to the resource group"
  type        = string
  default     = "CanNotDelete"
}

#################################
# Logging Configuration
#################################

variable "spoke_log_storage_account_name" {
  description = "Storage Account name for the deployment"
  type        = string
  default     = ""
}

variable "spoke_logging_storage_account_config" {
  description = "Storage Account variables for the Spoke deployment"
  type = object({
    sku_name                 = string
    kind                     = string
    min_tls_version          = string
    account_replication_type = string
  })
  default = {
    sku_name                 = "Standard_LRS"
    kind                     = "StorageV2"
    min_tls_version          = "TLS1_2"
    account_replication_type = "LRS"
  }
}