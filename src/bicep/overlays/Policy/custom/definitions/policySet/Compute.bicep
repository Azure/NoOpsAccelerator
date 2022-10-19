// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

targetScope = 'managementGroup'

// PARAMETERS
param parPolicySource string = 'ANOA'
param parPolicyCategory string = 'Compute'

@description('Management Group scope for the policy definition.')
param parPolicyDefinitionManagementGroupId string

// VARAIBLES
var builtinPolicies_compute = json(loadTextContent('../../../../../azresources/Policy/builtin/definitions/compute.json'))
var customPolicyDefinitionMgScope = tenantResourceId('Microsoft.Management/managementGroups', parPolicyDefinitionManagementGroupId)

module computePolicySetDefinitions '../../../../../azresources/Modules/Microsoft.Authorization/policySetDefinitions/az.auth.policy.set.def.bicep' = {
  name: 'compute-${uniqueString(deployment().name)}-policySetDefs'
  params: {
    // Required parameters
    name: 'custom-compute'
    location: ''
    policyDefinitions: [
      {
        groupNames: [
          'Compute'
        ]
        parameters: {
          listOfAllowedSKUs: {
            type: 'Array' 
            metadata: {
              description: 'The list of size SKUs that can be specified for virtual machines.'
              displayName: 'Allowed Size SKUs'
              strongType: 'VMSKUs'
            }       
            defaultValue: []
          }  
          effect: {
            type: 'String'
            metadata: {
              displayName: 'Effect'
              description: 'Enable or disable the execution of the policy'
            }
            allowedValues: [
              'Modify'
              'Disabled'
            ]
            defaultValue: 'Modify'
          }      
        }
        policyDefinitionId: builtinPolicies_compute.AllowedVirtualMachineSizeSkus
        policyDefinitionReferenceId: toLower(replace('Allowed Virtual Machine Size Skus', ' ', '-'))
      }
      {
        groupNames: [
          'ARM'
        ]
        parameters: {
          listOfAllowedLocations: {
            value: [
              'australiaeast'
            ]
          }
        }
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988'
        policyDefinitionReferenceId: 'Allowed locations for resource groups_1'
      }
    ]
    // Non-required parameters
    displayName: 'Custom - Compute Governance Initiative'
    description: 'Compute Governance Initiative - MG Scope via ${parPolicySource}'
    managementGroupId: '<<managementGroupId>>'
    metadata: {
      category: parPolicyCategory
      source: parPolicySource
      version: '1.0.0'
      control: ''
      author: parPolicySource
    }
    policyDefinitionGroups: [
      {
        name: 'Compute'
      }
      {
        name: 'Custom'
      }
    ]
  }
}
