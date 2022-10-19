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
param parPolicyCategory string = 'Azure Kubernetes Service'

module computePolicySetDefinitions '../../../../../azresources/Modules/Microsoft.Authorization/policySetDefinitions/az.auth.policy.set.def.bicep' = {
  name: 'compute-${uniqueString(deployment().name)}-policySetDefs'
  params: {
    // Required parameters
    name: 'custom-aks'
    location: ''
    policyDefinitions: [
      {
        groupNames: [
          'AKS'
        ]
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/a8eff44f-8c92-45c3-a3fb-9880802d67a7'
        policyDefinitionReferenceId: toLower(replace('Deploy Azure Policy Add-on to Azure Kubernetes Service clusters', ' ', '-'))
        parameters: {}
      }
      {
        groupNames: [
          'AKS'
        ]
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/3fc4dc25-5baf-40d8-9b05-7fe74c1bc64e'
        policyDefinitionReferenceId: toLower(replace('Kubernetes clusters should use internal load balancers', ' ', '-'))
        parameters: {}
      }
    ]
    // Non-required parameters
    displayName: 'Custom - Azure Kubernetes Service Governance Initiative'
    description: 'Azure Kubernetes Service Governance Initiative - MG Scope via ${parPolicySource}'
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
        name: 'Azure Kubernetes Service'
      }
      {
        name: 'Custom'
      }
    ]
  }
}
