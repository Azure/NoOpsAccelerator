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
param policyCategory string = 'KeyVault'

@description('Management Group scope for the policy definition.')
param policyDefinitionManagementGroupId string

// VARAIBLES
var builtinPolicies_keyvault = json(loadTextContent('../../../../../azresources/Policy/builtin/definitions/keyvault.json'))
var customPolicyDefinitionMgScope = tenantResourceId('Microsoft.Management/managementGroups', policyDefinitionManagementGroupId)

resource computePolicySet 'Microsoft.Authorization/policySetDefinitions@2020-03-01' = {
  name: 'custom-keyVault'
  properties: {
    displayName: 'Custom - KeyVault Governance Initiative'
    description: 'KeyVault Governance Initiative - MG Scope via ${policySource}'
    metadata: {
      category: policyCategory
      source: policySource
      version: '1.0.0'      
      author: policySource
    }
    parameters: {
      logAnalytics: {
        type: 'String'
        metadata: {
          displayName: 'Log Analytics workspace'
          description: 'Specify the Log Analytics workspace the Key Vault should be connected to.'
          strongType: 'omsWorkspace'
          assignPermissions: true
        }
      }
      allowedCAs: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed Azure Key Vault Supported CAs'
          description: 'The list of allowed certificate authorities supported by Azure Key Vault.'
        }
        allowedValues: [
          'DigiCert'
          'GlobalSign'
        ]
        defaultValue: [
          'DigiCert'
          'GlobalSign'
        ]
      }
      allowedKeyTypesCertificates: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed key types'
          description: 'The list of allowed certificate key types.'
        }
        allowedValues: [
          'RSA'
          'RSA-HSM'
          'EC'
          'EC-HSM'
        ]
        defaultValue: [
          'RSA'
          'RSA-HSM'
        ]
      }
      allowedKeyTypes: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed key types'
          description: 'The list of allowed key types.'
        }
        allowedValues: [
          'RSA'
          'RSA-HSM'
          'EC'
          'EC-HSM'
        ]
        defaultValue: [
          'RSA'
          'RSA-HSM'
          'EC'
          'EC-HSM'
        ]
      }
      minimumDaysBeforeExpiration: {
        type: 'Integer'
        metadata: {
          displayName: 'The minimum days before expiration'
          description: 'Specify the minimum number of days that a key or secret should remain usable prior to expiration.'
        }
        defaultValue: 30
      }
      maximumValidityInDays: {
        type: 'Integer'
        metadata: {
          displayName: 'The maximum validity period in days'
          description: 'Specify the maximum number of days a key or secret can be valid for. Using a key or secret with a long validity period is not recommended.'
        }
        defaultValue: 200
      }
      minimumRSAKeySize: {
        type: 'Integer'
        metadata: {
          displayName: 'Minimum RSA key size'
          description: 'The minimum key size for RSA keys.'
        }
        allowedValues: [
          2048
          3072
          4096
        ]
        defaultValue: 2048
      }
    }
    policyDefinitionGroups: [
      {
        name: 'KeyVault'
        displayName: 'KeyVault Governance Controls'
      }
      {
        name: 'CUSTOM'
        displayName: 'Additional Controls as Custom Policies'
      }
    ]
    policyDefinitions: [
      {
        groupNames: [
          'KeyVault'
        ]
        policyDefinitionId: builtinPolicies_keyvault.KeyVaultsShouldHavePurgeProtectionEnabled
        policyDefinitionReferenceId: toLower(replace('Key Vaults Should Have Purge Protection Enabled', ' ', '-'))
        parameters: {}
      }
      {
        groupNames: [
          'KeyVault'
        ]
        policyDefinitionId: builtinPolicies_keyvault.KeyVaultsShouldHaveSoftDeleteEnabled
        policyDefinitionReferenceId: toLower(replace('Key Vaults Should Have Soft Delete Enabled', ' ', '-'))
        parameters: {}
      }
      {
        groupNames: [
          'KeyVault'
        ]
        policyDefinitionId: builtinPolicies_keyvault.CertificatesShouldBeIssuedByTheSpecifiedIntegratedCertificateAuthority
        policyDefinitionReferenceId: toLower(replace('Certificates Should Be Issued By The Specified Integrated Certificate Authority', ' ', '-'))
        parameters: {
          allowedCAs: {
            value: '[parameters(\'allowedCAs\')]'
          }
        }
      }
      {
        groupNames: [
          'KeyVault'
        ]
        policyDefinitionId: builtinPolicies_keyvault.CertificatesShouldUseAllowedKeyTypes
        policyDefinitionReferenceId: toLower(replace('Certificates Should Use Allowed Key Types', ' ', '-'))
        parameters: {
          allowedKeyTypesCertificates: {
            value: '[parameters(\'allowedKeyTypesCertificates\')]'
          }
        }
      }
      {
        groupNames: [
          'KeyVault'
        ]
        policyDefinitionId: builtinPolicies_keyvault.CertificatesUsingRSACryptographyShouldHaveTheSpecifiedMinimumKeySize
        policyDefinitionReferenceId: toLower(replace('Certificates Using RSA Cryptography Should Have The Specified Minimum KeySize', ' ', '-'))
        parameters: {
          minimumRSAKeySize: {
            value: '[parameters(\'minimumRSAKeySize\')]'
          }
        }
      }
      {
        groupNames: [
          'KeyVault'
        ]
        policyDefinitionId: builtinPolicies_keyvault.KeysShouldBeTheSpecifiedCryptographicTypeRSAOrEC
        policyDefinitionReferenceId: toLower(replace('Keys Should Be The Specified Cryptographic Type RSA Or EC', ' ', '-'))
        parameters: {
          allowedKeyTypes: {
            value: '[parameters(\'allowedKeyTypes\')]'
          }
        }
      }
      {
        groupNames: [
          'CUSTOM'
        ]
        policyDefinitionId: extensionResourceId(customPolicyDefinitionMgScope, 'Microsoft.Authorization/policyDefinitions', 'Audit-ResourceLocks')
        policyDefinitionReferenceId: toLower(replace('Audit resource locks for Subscriptions', ' ', '-'))
        parameters: {
          resourceTypes: {
            value: '[parameters(\'resourceTypes\')]'
          }
          lockLevel: {
            value: '[parameters(\'lockLevel\')]'
          }
          effect: {
            value: '[parameters(\'effect2\')]'
          }
        }
      }
    ]
  }
}
