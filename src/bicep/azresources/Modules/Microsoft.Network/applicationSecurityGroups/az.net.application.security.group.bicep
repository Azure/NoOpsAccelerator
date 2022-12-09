/* Copyright (c) Microsoft Corporation. Licensed under the MIT license. */
@description('Required. Name of the Application Security Group.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Tags of the resource.')
param tags object = {}

resource applicationSecurityGroup 'Microsoft.Network/applicationSecurityGroups@2021-08-01' = {
  name: name
  location: location
  tags: tags
  properties: {}
}

resource applicationSecurityGroup_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock)) {
  name: '${applicationSecurityGroup.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: applicationSecurityGroup
}

module applicationSecurityGroup_roleAssignments './rbac/roleAssignments.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-AppSecurityGroup-Rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    resourceId: applicationSecurityGroup.id
  }
}]

@description('The resource group the application security group was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The resource ID of the application security group.')
output resourceId string = applicationSecurityGroup.id

@description('The name of the application security group.')
output name string = applicationSecurityGroup.name

@description('The location the resource was deployed into.')
output location string = applicationSecurityGroup.location
