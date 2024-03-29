# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------
# Virtual machine backup
#---------------------------------------
resource "azurerm_backup_protected_vm" "backup" {
  for_each = toset(var.backup_policy_id != null ? ["enabled"] : [])

  resource_group_name = local.backup_resource_group_name
  recovery_vault_name = local.backup_recovery_vault_name
  source_vm_id        = azurerm_windows_virtual_machine.win_vm.0.id
  backup_policy_id    = var.backup_policy_id
}