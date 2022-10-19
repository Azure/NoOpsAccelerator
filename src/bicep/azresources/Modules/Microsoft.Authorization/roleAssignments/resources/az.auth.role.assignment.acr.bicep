/* Copyright (c) Microsoft Corporation. Licensed under the MIT license. */
targetScope = 'resourceGroup'

@sys.description('Required. You can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleDefinitionIdOrName string

@sys.description('Required. The Principal or Object ID of the Security Principal (User, Group, Service Principal, Managed Identity).')
param principalId string

@sys.description('Optional. Name of the Resource Group to assign the RBAC role to. If not provided, will use the current scope for deployment.')
param resourceGroupName string = resourceGroup().name

@sys.description('Optional. Subscription ID of the subscription to assign the RBAC role to. If not provided, will use the current scope for deployment.')
param subscriptionId string = subscription().subscriptionId

@sys.description('Optional. The description of the role assignment.')
param description string = ''

@sys.description('Optional. ID of the delegated managed identity resource.')
param delegatedManagedIdentityResourceId string = ''

@sys.description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to.')
param condition string = ''

@sys.description('Optional. name of acr for assignment. This limits the resources it can be assigned to.')
param acrName string = ''

@sys.description('Optional. Version of the condition. Currently accepted value is "2.0".')
@allowed([
  '2.0'
])
param conditionVersion string = '2.0'

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

var builtInRoleNames_var = {
  'AcrPush': '/providers/Microsoft.Authorization/roleDefinitions/8311e382-0749-4cb8-b61a-304f252e45ec'
  'API Management Service Contributor': '/providers/Microsoft.Authorization/roleDefinitions/312a565d-c81f-4fd8-895a-4e21e48d571c'
  'AcrPull': '/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
  'AcrImageSigner': '/providers/Microsoft.Authorization/roleDefinitions/6cef56e8-d556-48e5-a04f-b8e64114680f'
  'AcrDelete': '/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11'
  'AcrQuarantineReader': '/providers/Microsoft.Authorization/roleDefinitions/cdda3590-29a3-44f6-95f2-9f980659eb04'
  'AcrQuarantineWriter': '/providers/Microsoft.Authorization/roleDefinitions/c8d4ff99-41c3-41a8-9f60-21dfdad59608'
}

var roleDefinitionId_var = (contains(builtInRoleNames_var, roleDefinitionIdOrName) ? builtInRoleNames_var[roleDefinitionIdOrName] : roleDefinitionIdOrName)

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: acrName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscriptionId, resourceGroupName, roleDefinitionId_var, principalId)
  properties: {
    roleDefinitionId: roleDefinitionId_var
    principalId: principalId
    description: !empty(description) ? description : null
    principalType: !empty(principalType) ? any(principalType) : null
    delegatedManagedIdentityResourceId: !empty(delegatedManagedIdentityResourceId) ? delegatedManagedIdentityResourceId : null
    conditionVersion: !empty(conditionVersion) && !empty(condition) ? conditionVersion : null
    condition: !empty(condition) ? condition : null
  }
  scope: acr
}

@sys.description('The GUID of the Role Assignment.')
output name string = roleAssignment.name

@sys.description('The resource ID of the Role Assignment.')
output resourceId string = az.resourceId(resourceGroupName, 'Microsoft.Authorization/roleAssignments', roleAssignment.name)

@sys.description('The name of the resource group the role assignment was applied at.')
output resourceGroupName string = resourceGroup().name

@sys.description('The scope this Role Assignment applies to.')
output rgscope string = resourceGroup().id
