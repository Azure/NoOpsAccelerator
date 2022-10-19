/* Copyright (c) Microsoft Corporation. Licensed under the MIT license. */
@sys.description('Required. The IDs of the principals to assign the role to.')
param principalIds array

@sys.description('Required. The name of the role to assign. If it cannot be found you can specify the role definition ID instead.')
param roleDefinitionIdOrName string

@sys.description('Required. The resource ID of the resource to apply the role assignment to.')
param resourceId string

@sys.description('Optional. The principal type of the assigned principal ID.')
@allowed([
  'ServicePrincipal'
  'Group'
  'User'
  'ForeignGroup'
  'Device'
  ''
])
param principalType string = ''

@sys.description('Optional. The description of the role assignment.')
param description string = ''

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' existing = {
  name: last(split(resourceId, '/'))
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in principalIds: {
  name: guid(privateEndpoint.id, principalId, roleDefinitionIdOrName)
  properties: {
    description: description
    roleDefinitionId: roleDefinitionIdOrName
    principalId: principalId
    principalType: !empty(principalType) ? any(principalType) : null
  }
  scope: privateEndpoint
}]
