@description('Required. Name of the private link scope.')
@minLength(1)
param name string

@description('Optional. The location of the private link scope. Should be global.')
param location string = 'global'

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Resource tags.')
param tags object = {}

@description('The name for the private endpoint.')
param privateEndpointName string

@description('The resource group name for the existing virtual network.')
param virtualNetworkRG string

@description('The name for the existing virtual network.')
param virtualNetworkName string

@description('The name for the existing subnet.')
param subnetName string

@description('Deployment id to associate sub-deployments.')
param deploymentid string = substring(uniqueString(utcNow()),0,6)

@description('Private DNS Zone Group for Private Endpoint.')
param privateDnsZoneGroup object = {}

@description('A grouping of information about the connection to the remote resource for Private Endpoint.')
param manualPrivateLinkServiceConnections array = []

@description('An array of custom dns configurations for Private Endpoint.')
param customDnsConfigs array = []

@description('Log Analytics Workspace Configuration.')
param logAnalyticsWorkspace object = {
  name: ''
}

resource virtualNetwork 'Microsoft.Network/virtualnetworks@2015-05-01-preview' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkRG)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: subnetName
  parent: virtualNetwork
}

module resLogAnalyticsWorkspace '../../Microsoft.OperationalInsights/workspaces/az.app.log.analytics.workspace.bicep' = {
  name: 'deploy-loga-${logAnalyticsWorkspace.name}-${deploymentid}'
  params: {
    name: logAnalyticsWorkspace.name
    location: location
  }
}

module privateLinkScope 'az.insights.private.link.scope.bicep' = {
  name: 'deploy-pls-${name}-${deploymentid}'
  params: {
    name: name
    location: 'global'
    scopedResources: [
      {
        name: resLogAnalyticsWorkspace.outputs.name
        linkedResourceId: resLogAnalyticsWorkspace.outputs.resourceId
      }
    ]
    privateEndpoints: [
      {
        location: location
        name: privateEndpointName
        subnetResourceId: subnet.id
        privateDnsZoneGroup: privateDnsZoneGroup
        roleAssignments: roleAssignments
        lock: lock
        tags: tags
        manualPrivateLinkServiceConnections: manualPrivateLinkServiceConnections
        customDnsConfigs: customDnsConfigs
        service: 'azuremonitor'
      }
    ]
    tags: tags
    lock: lock
    roleAssignments: roleAssignments    
  }
}

@description('The name of the private link scope.')
output name string = privateLinkScope.outputs.name

@description('The resource ID of the private link scope.')
output resourceId string = privateLinkScope.outputs.resourceId

@description('The resource group the private link scope was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = privateLinkScope.outputs.location
