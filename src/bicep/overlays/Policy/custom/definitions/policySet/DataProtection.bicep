// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

targetScope = 'managementGroup'

// PARAMETERS
param policySource string = 'ANOA'
param policyCategory string = 'Data Protection'

// VARAIBLES
var builtinPolicies_compute = json(loadTextContent('../../../../../azresources/Policy/builtin/definitions/compute.json'))
var builtinPolicies_backup = json(loadTextContent('../../../../../azresources/Policy/builtin/definitions/backup.json'))

resource computePolicySet 'Microsoft.Authorization/policySetDefinitions@2020-03-01' = {
  name: 'custom-dataProtection'
  properties: {
    displayName: 'Custom - Data Protection Governance Initiative'
    description: 'Data Protection Governance Initiative - MG Scope via ${policySource}'
    metadata: {
      category: policyCategory
      source: policySource
      version: '1.0.0'
      control: ''
      author: policySource
    }
    parameters: {
      vaultLocation: {
        type: 'String'
        metadata: {
          displayName: 'Location (Specify the location of the VMs that you want to protect)'
          description: 'Specify the location of the VMs that you want to protect. VMs should be backed up to a vault in the same location. For example - "East US", "West US"'
          strongType: 'location'
        }
      }
      inclusionTagName: {
        type: 'String'
        metadata: {
          displayName: 'Inclusion Tag Name'
          description: 'Name of the tag to use for including VMs in the scope of this policy. This should be used along with the Inclusion Tag Value parameter. Learn more at https://aka.ms/AppCentricVMBackupPolicy'
        }
        defaultValue: ''
      }
      inclusionTagValues: {
        type: 'Array'
        metadata: {
          displayName: 'Inclusion Tag Values'
          description: 'Value of the tag to use for including VMs in the scope of this policy (in case of multiple values use a comma-separated list). This should be used along with the Inclusion Tag Name parameter. Learn more at https://aka.ms/AppCentricVMBackupPolicy.'
        }
      }
      backupPolicyId: {
        type: 'String'
        metadata: {
          displayName: 'Backup Policy (of type Azure VM from a vault in the location chosen above)'
          description: 'Specify the ID of the Azure Backup policy to configure backup of the virtual machines. The selected Azure Backup policy should be of type Azure Virtual Machine. This policy needs to be in a vault that is present in the location chosen above. For example - /subscriptions/<SubscriptionId>/resourceGroups/<resourceGroupName>/providers/Microsoft.RecoveryServices/vaults/<VaultName>/backupPolicies/<BackupPolicyName>'
          strongType: 'Microsoft.RecoveryServices/vaults/backupPolicies'
        }
      }
      effect: {
        type: 'String'
        metadata: {
          displayName: 'Effect'
          description: 'Enable or disable the execution of the policy'
        }
        allowedValues: [
          'AuditIfNotExists'
          'Disabled'
        ]
        defaultValue: 'AuditIfNotExists'
      }
      effect2: {
        type: 'String'
        metadata: {
          displayName: 'Effect'
          description: 'Enable or disable the execution of the policy'
        }
        allowedValues: [
          'deployIfNotExists'
          'auditIfNotExists'
          'disabled'
        ]
        defaultValue: 'deployIfNotExists'
      }
    }
    policyDefinitionGroups: [
      {
        name: 'Compute'
        displayName: 'Compute Governance Controls'
      }
      {
        name: 'CUSTOM'
        displayName: 'Additional Controls as Custom Policies'
      }
    ]
    policyDefinitions: [
      {
        policyDefinitionId: builtinPolicies_backup.AzureBackupShouldBeEnabledForVirtualMachines
        policyDefinitionReferenceId: 'AzureBackupShouldBeEnabledForVirtualMachines'
        parameters: {
          effect: {
            value: '[parameters(\'effect\')]'
          }
        }
      }
      {
        policyDefinitionId: builtinPolicies_backup.ConfigureBackupOnVirtualMachinesWithAGivenTagToAnExistingRecoveryServicesVaultInTheSameLocation
        policyDefinitionReferenceId: 'ConfigureBackupOnVirtualMachinesWithAGivenTagToAnExistingRecoveryServicesVaultInTheSameLocation'
        parameters: {
          vaultLocation: {
            value: '[parameters(\'vaultLocation\')]'
          }
          inclusionTagName: {
            value: '[parameters(\'inclusionTagName\')]'
          }
          inclusionTagValue: {
            value: '[parameters(\'inclusionTagValues\')]'
          }
          backupPolicyId: {
            value: '[parameters(\'backupPolicyId\')]'
          }
          effect: {
            value: '[parameters(\'effect2\')]'
          }
        }
      }
      {
        policyDefinitionId: builtinPolicies_compute.AuditVirtualMachinesWithoutDisasterRecoveryConfigured
        policyDefinitionReferenceId: 'AuditVirtualMachinesWithoutDisasterRecoveryConfigured'
      }
    ]
  }
}
