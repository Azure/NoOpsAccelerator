// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

targetScope = 'managementGroup'

@description('Location for the deployment.')
param parLocation string = deployment().location

@description('Management Group varScope for the policy assignment.')
param parPolicyAssignmentManagementGroupId string

@allowed([
  'Default'
  'DoNotEnforce'
])
@description('Policy set assignment enforcement mode.  Possible values are { Default, DoNotEnforce }.  Default value:  Default')
param parEnforcementMode string = 'Default'

var varPolicyId = '179d1daa-458f-4e47-8086-2a68d0d6c38f' // NIST SP 800-53 R5 
var varAssignmentName = 'NIST SP 800-53 R5'
var varScope = tenantResourceId('Microsoft.Management/managementGroups', parPolicyAssignmentManagementGroupId)
var varPolicyScopedId = resourceId('Microsoft.Authorization/policySetDefinitions', varPolicyId)

resource resPolicySetAssignment 'Microsoft.Authorization/policyAssignments@2020-03-01' = {
  name: 'nistr5-${uniqueString('nist-sp-800-53-r5-',parPolicyAssignmentManagementGroupId)}'
  properties: {
    displayName: varAssignmentName
    policyDefinitionId: varPolicyScopedId
    scope: varScope
    notScopes: [
    ]
    parameters: {
    }
    enforcementMode: parEnforcementMode
  }
  identity: {
    type: 'SystemAssigned'
  }
  location: parLocation
}

// These role assignments are required to allow Policy Assignment to remediate.
resource resPolicySetRoleAssignmentContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(parPolicyAssignmentManagementGroupId, 'nist-sp-800-53-r5-contributor')
  scope: managementGroup()
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalId: resPolicySetAssignment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
