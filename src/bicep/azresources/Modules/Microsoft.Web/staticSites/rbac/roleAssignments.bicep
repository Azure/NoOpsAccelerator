/* Copyright (c) Microsoft Corporation. Licensed under the MIT license. */
param principalIds array
param principalType string = ''
param roleDefinitionIdOrName string
param resourceId string

resource staticSite 'Microsoft.Web/staticSites@2021-02-01' existing = {
  name: last(split(resourceId, '/'))
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in principalIds: {
  name: guid(staticSite.id, principalId, roleDefinitionIdOrName)
  properties: {
    roleDefinitionId: roleDefinitionIdOrName
    principalId: principalId
    principalType: !empty(principalType) ? any(principalType) : null
  }
  scope: staticSite
}]
