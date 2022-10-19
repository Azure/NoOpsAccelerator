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
param policyCategory string = 'SQL'

// VARAIBLES
var builtinPolicies_sql = json(loadTextContent('../../../../../azresources/Policy/builtin/definitions/sql.json'))

resource computePolicySet 'Microsoft.Authorization/policySetDefinitions@2020-03-01' = {
  name: 'custom-keyVault'
  properties: {
    displayName: 'Custom - SQL Governance Initiative'
    description: 'SQL Governance Initiative - MG Scope via ${policySource}'
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
        name: 'SQL'
        displayName: 'SQL Governance Controls'
      }
      {
        name: 'CUSTOM'
        displayName: 'Additional Controls as Custom Policies'
      }
    ]
    policyDefinitions: [
      {
        groupNames: [
          'SQL'
        ]
        policyDefinitionId: builtinPolicies_sql.SQL_DeployAdvancedDataSecurityOnSQLServers
        policyDefinitionReferenceId: toLower(replace('Deploy Advanced Data Security on SQL servers', ' ', '-'))
        parameters: {}
      }      
    ]
  }
}
