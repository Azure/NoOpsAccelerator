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
param policyCategory string = 'Network'

@description('Management Group scope for the policy definition.')
param policyDefinitionManagementGroupId string

// VARAIBLES
var builtinPolicies_network = json(loadTextContent('../../../../../azresources/Policy/builtin/definitions/network.json'))

var customPolicyDefinitionMgScope = tenantResourceId('Microsoft.Management/managementGroups', policyDefinitionManagementGroupId)

resource computePolicySet 'Microsoft.Authorization/policySetDefinitions@2020-03-01' = {
  name: 'custom-keyVault'
  properties: {
    displayName: 'Custom - Network Governance Initiative'
    description: 'Network Governance Initiative - MG Scope via ${policySource}'
    metadata: {
      category: policyCategory
      source: policySource
      version: '1.0.0'      
      author: policySource
    }
    parameters: {
      
    }
    policyDefinitionGroups: [
      {
        name: 'Network'
        displayName: 'Network Governance Controls'
      }
      {
        name: 'CUSTOM'
        displayName: 'Additional Controls as Custom Policies'
      }
    ]
    policyDefinitions: [
      {
        groupNames: [
          'Network'
        ]
        policyDefinitionId: builtinPolicies_network.NetworkWatcherShouldBeEnabled
        policyDefinitionReferenceId: toLower(replace('Network Watcher Should Be Enabled', ' ', '-'))
        parameters: {}
      }   
      {
        groupNames: [
          'Network'
        ]
        policyDefinitionId: builtinPolicies_network.NetworkInterfacesShouldNotHavePublicIps
        policyDefinitionReferenceId: toLower(replace('Network interfaces should not have public IPs', ' ', '-'))
        parameters: {}
      } 
      {
        groupNames: [
          'Network'
        ]
        policyDefinitionId: extensionResourceId(customPolicyDefinitionMgScope, 'Microsoft.Authorization/policyDefinitions', 'Network-Audit-Missing-UDR')
        policyDefinitionReferenceId: toLower(replace('Audit for missing UDR on subnets', ' ', '-'))
        parameters: {}
      }     
    ]
  }
}
