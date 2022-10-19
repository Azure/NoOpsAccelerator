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
param policyCategory string = 'IAM'

@description('Management Group scope for the policy definition.')
param policyDefinitionManagementGroupId string

// VARAIBLES
var builtinPolicies_general = json(loadTextContent('../../../../../azresources/Policy/builtin/definitions/general.json'))
var customPolicyDefinitionMgScope = tenantResourceId('Microsoft.Management/managementGroups', policyDefinitionManagementGroupId)

resource computePolicySet 'Microsoft.Authorization/policySetDefinitions@2020-03-01' = {
  name: 'custom-compute'
  properties: {
    displayName: 'Custom - IAM Governance Initiative'
    description: 'IAM Governance Initiative - MG Scope via ${policySource}'
    metadata: {
      category: policyCategory
      source: policySource
      version: '1.0.0'
      control: ''
      author: policySource
    }
    parameters: {
      resourceTypes: {
        type: 'Array'
        metadata: {
          description: 'Azure resource types to audit for locks e.g. microsoft.network/expressroutecircuits and microsoft.network/expressroutegateways'
          displayName: 'Resource types to audit for locks'
        }
        defaultValue: []
      }
      lockLevel: {
        type: 'Array'
        metadata: {
          description: 'Resource lock level to audit for'
          displayName: 'Lock level'
        }
        allowedValues: [
          'ReadOnly'
          'CanNotDelete'
        ]
        defaultValue: [
          'ReadOnly'
          'CanNotDelete'
        ]
      }
      principalType: {
        type: 'String'
        metadata: {
          description: 'Which principalType to audit against e.g. User'
          displayName: 'principalType'
        }
        allowedValues: [
          'User'
          'Group'
          'ServicePrincipal'
        ]
        defaultValue: 'User'
      }
      effect: {
        type: 'String'
        metadata: {
          displayName: 'Effect'
          description: 'Enable or disable the execution of the policy'
        }
        allowedValues: [
          'Audit'
          'Disabled'
        ]
        defaultValue: 'Audit'
      } 
      effect2: {
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
    }
    policyDefinitionGroups: [
      {
        name: 'IAM'
        displayName: 'IAM Governance Controls'
      }
      {
        name: 'CUSTOM'
        displayName: 'Additional Controls as Custom Policies'
      }
    ]
    policyDefinitions: [
      {
        groupNames: [
          'IAM'
        ]
        policyDefinitionId: builtinPolicies_general.CustomSubscriptionOwnerRolesShouldNotExist
        policyDefinitionReferenceId: toLower(replace('Custom Subscription Owner Roles Should Not Exist', ' ', '-'))
        parameters: {
          effect: {
            value: '[parameters(\'effect\')]'
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
