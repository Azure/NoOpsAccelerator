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
param policyCategory string = 'Storage'

// VARAIBLES
var builtinPolicies_storage = json(loadTextContent('../../../../../azresources/Policy/builtin/definitions/storage.json'))

resource computePolicySet 'Microsoft.Authorization/policySetDefinitions@2020-03-01' = {
  name: 'custom-keyVault'
  properties: {
    displayName: 'Custom - Storage Governance Initiative'
    description: 'Storage Governance Initiative - MG Scope via ${policySource}'
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
        name: 'Storage'
        displayName: 'Storage Governance Controls'
      }
      {
        name: 'CUSTOM'
        displayName: 'Additional Controls as Custom Policies'
      }
    ]
    policyDefinitions: [
      {
        groupNames: [
          'Storage'
        ]
        policyDefinitionId: builtinPolicies_storage.Storageaccountpublicaccessshouldbedisallowed
        policyDefinitionReferenceId: toLower(replace('Storage Account Public Access should be disallowed', ' ', '-'))
        parameters: {}
      }      
    ]
  }
}
