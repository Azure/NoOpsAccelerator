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

@description('Management Group scope for the policy definition.')
param parPolicyDefinitionManagementGroupId string

@description('Management Group scope for the policy assignment.')
param parPolicyAssignmentManagementGroupId string

@allowed([
  'Default'
  'DoNotEnforce'
])
@description('Policy set assignment enforcement mode.  Possible values are { Default, DoNotEnforce }.  Default value:  Default')
param parEnforcementMode string = 'Default'

var policyId = 'custom-compute'
var assignmentName = 'Custom - Compute Governance Initiative'

var scope = tenantResourceId('Microsoft.Management/managementGroups', parPolicyAssignmentManagementGroupId)
var policyScopedId = '/providers/Microsoft.Management/managementGroups/${parPolicyDefinitionManagementGroupId}/providers/Microsoft.Authorization/policySetDefinitions/${policyId}'

resource policySetAssignment 'Microsoft.Authorization/policyAssignments@2020-03-01' = {
  name: 'compute-${uniqueString(parPolicyAssignmentManagementGroupId)}'
  properties: {
    displayName: assignmentName
    policyDefinitionId: policyScopedId
    scope: scope
    notScopes: []
    parameters: {}
    enforcementMode: parEnforcementMode
  }
  identity: {
    type: 'SystemAssigned'
  }
  location: parLocation
}

// These role assignments are required to allow Policy Assignment to remediate.
resource policySetRoleAssignmentVirtualMachineContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(parPolicyAssignmentManagementGroupId, 'compute', 'Virtual Machine Contributor')
  scope: managementGroup()
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
    principalId: policySetAssignment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
