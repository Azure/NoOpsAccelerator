@description('Region where the ARC enabled machine will be deployed (must match the resource group region).')
param location string = resourceGroup().location

@description('The name for the private link scope.')
param name string

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Indicates whether machines associated with the private link scope can also use public Azure Arc service endpoints.')
param publicNetworkAccess string

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

var groupIds = [
  'hybridcompute'
]

resource virtualNetwork 'Microsoft.Network/virtualnetworks@2015-05-01-preview' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkRG)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: subnetName
  parent: virtualNetwork
}

module privateLinkScope 'az.hybridcompute.private.link.scope.bicep' = {
  name: 'deploy-privatelinkscope-${name}-${deploymentid}'
  params: {
    location: location
    name: name
    tags: tags
    publicNetworkAccess: publicNetworkAccess
  }
}

module privateEndpoint '../Microsoft.Network/privateEndPoint/az.net.private.endpoint.bicep' = {
  name:  'deploy-privateendpoint-${privateEndpointName}-${deploymentid}'
  params: {
    location: location
    groupIds: groupIds
    name: privateEndpointName
    serviceResourceId: privateLinkScope.outputs.id
    subnetResourceId: subnet.id
  }
}

output id string = privateLinkScope.outputs.id
output name string = privateLinkScope.outputs.name
output location string = privateLinkScope.outputs.location
