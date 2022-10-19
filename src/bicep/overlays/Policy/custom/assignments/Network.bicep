// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

targetScope = 'managementGroup'

@description('Location for the deployment.')
param location string = deployment().location

@description('Management Group scope for the policy definition.')
param policyDefinitionManagementGroupId string

@description('Management Group scope for the policy assignment.')
param policyAssignmentManagementGroupId string

@allowed([
  'Default'
  'DoNotEnforce'
])
@description('Policy set assignment enforcement mode.  Possible values are { Default, DoNotEnforce }.  Default value:  Default')
param enforcementMode string = 'Default'

var policyId = 'custom-network'
var assignmentName = 'Custom - Network Governance Initiative'

var scope = tenantResourceId('Microsoft.Management/managementGroups', policyAssignmentManagementGroupId)
var policyScopedId = '/providers/Microsoft.Management/managementGroups/${policyDefinitionManagementGroupId}/providers/Microsoft.Authorization/policySetDefinitions/${policyId}'

resource policySetAssignment 'Microsoft.Authorization/policyAssignments@2020-03-01' = {
  name: 'network-${uniqueString(policyAssignmentManagementGroupId)}'
  properties: {
    displayName: assignmentName
#disable-next-line use-resource-id-functions
    policyDefinitionId: policyScopedId
    scope: scope
    notScopes: []
    parameters: {}
    enforcementMode: enforcementMode
  }
  identity: {
    type: 'SystemAssigned'
  }
  location: location
}
