# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#------------------------------------------------------------
# Local configuration - Default (required). 
#------------------------------------------------------------

locals {
  tenant_id = coalesce(
    var.tenant_id,
    data.azurerm_client_config.current_config.tenant_id,
  )
}