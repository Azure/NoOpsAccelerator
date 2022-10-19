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
param policyCategory string = 'Security'

// VARAIBLES
var builtinPolicies_security = json(loadTextContent('../../../../../azresources/Policy/builtin/definitions/security.json'))

resource computePolicySet 'Microsoft.Authorization/policySetDefinitions@2020-03-01' = {
  name: 'custom-keyVault'
  properties: {
    displayName: 'Custom - Security Governance Initiative'
    description: 'Security Governance Initiative - MG Scope via ${policySource}'
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
        name: 'Security'
        displayName: 'Security Governance Controls'
      }
      {
        name: 'CUSTOM'
        displayName: 'Additional Controls as Custom Policies'
      }
    ]
    policyDefinitions: [
      {
        groupNames: [
          'Security'
        ]
        policyDefinitionId: builtinPolicies_security.AllNetworkPortsShouldBeRestrictedOnNetworkSecurityGroupsAssociatedToYourVirtualMachine
        policyDefinitionReferenceId: toLower(replace('All Network Ports Should Be Restricted On Network Security Groups Associated To Your Virtual Machine', ' ', '-'))
        parameters: {}
      }      
    ]
  }
}
