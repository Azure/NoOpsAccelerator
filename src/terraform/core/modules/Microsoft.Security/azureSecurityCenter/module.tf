# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# This module deploys Azure Security Center
# For more information see the module documentation at
# https://techcommunity.microsoft.com/t5/microsoft-defender-for-cloud/deploy-microsoft-defender-for-cloud-via-terraform/ba-p/3563710

#----------------------------------------------------------
# Resource Group, Log Analytics Data Resources
#----------------------------------------------------------
data "azurerm_resource_group" "logging_rg" {
  name = var.resource_group_name
}

data "azurerm_log_analytics_workspace" "logws" {
  name                = var.log_analytics_workspace_name
  resource_group_name = data.azurerm_resource_group.logging_rg.name
}

#----------------------------------------------------------
# Current Subscription Data Resources
#----------------------------------------------------------

data "azurerm_subscription" "current" {}

#----------------------------------------------------------
# Azure Security Center Workspace Resource
#----------------------------------------------------------

resource "azurerm_security_center_workspace" "main" {
  scope        = var.scope_resource_id == null ? data.azurerm_subscription.current.id : var.scope_resource_id
  workspace_id = data.azurerm_log_analytics_workspace.logws.id
}

#----------------------------------------------------------
# Azure Security Center Subscription Pricing Resources
#----------------------------------------------------------

resource "azurerm_security_center_subscription_pricing" "main" {
  for_each      = toset(local.bundle)
  tier          = "Standard"
  resource_type = each.value
}

#----------------------------------------------------------
# Azure Security Center Contact Resources
#----------------------------------------------------------
resource "azurerm_security_center_contact" "main" {
  email               = lookup(var.security_center_contacts, "email")
  phone               = lookup(var.security_center_contacts, "phone", null)
  alert_notifications = lookup(var.security_center_contacts, "alert_notifications", true)
  alerts_to_admins    = lookup(var.security_center_contacts, "alerts_to_admins", true)
}

resource "azurerm_security_center_setting" "main" {
  count        = var.enable_security_center_setting ? 1 : 0
  setting_name = var.security_center_setting_name
  enabled      = var.enable_security_center_setting
}

resource "azurerm_security_center_auto_provisioning" "main" {
  count          = var.enable_security_center_auto_provisioning == "On" ? 1 : 0
  auto_provision = var.enable_security_center_auto_provisioning
}
