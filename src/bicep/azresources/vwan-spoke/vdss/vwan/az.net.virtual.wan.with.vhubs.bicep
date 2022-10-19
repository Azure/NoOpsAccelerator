@description('Optional. Location where all resources will be created.')
param location string = resourceGroup().location

@description('Required. Name of the Virtual WAN.')
param name string

@description('Optional. The type of the Virtual WAN.')
@allowed([
  'Standard'
  'Basic'
])
param type string = 'Standard'

@description('Optional. True if branch to branch traffic is allowed.')
param allowBranchToBranchTraffic bool = false

@description('Optional. True if VNET to VNET traffic is allowed.')
param allowVnetToVnetTraffic bool = false

@description('Optional. VPN encryption to be disabled or not.')
param disableVpnEncryption bool = false

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Tags of the resource.')
param tags object = {}

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

param virtualHubs array = []

param deploymentid string = substring(uniqueString(utcNow()),0,6)

module modVirtualWan '../../../Modules/Microsoft.Network/virtualWans/az.net.virtual.wan.bicep' = {
  name: 'deploy'
  params: {
    name: name
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
    allowVnetToVnetTraffic: allowVnetToVnetTraffic
    disableVpnEncryption: disableVpnEncryption
    location: location
    lock: lock
    roleAssignments: roleAssignments
    tags: tags
    type: type
  }
}

module modVirtualHubs '../../../Modules/Microsoft.Network/virtualHubs/az.net.virutal.hub.bicep' = [for virtualHub in virtualHubs: {
  name: 'deploy-virtualHub-${virtualHub.name}-${deploymentid}'
  params: {
    location: virtualHub.location
    addressPrefix: virtualHub.addressPrefix
    name: virtualHub.name
    virtualWanId: modVirtualWan.outputs.resourceId
    /*allowBranchToBranchTraffic: 
    azureFirewallId:
    expressRouteGatewayId:
    hubRouteTables:
    hubVirtualNetworkConnections:
    lock:
    p2SVpnGatewayId:
    preferredRoutingGateway:
    routeTableRoutes:
    securityPartnerProviderId:
    securityProviderName:
    sku:
    tags:
    virtualHubRouteTableV2s:
    virtualRouterAsn:
    virtualRouterIps:
    vpnGatewayId:*/
  }
}]

@description('The name of the virtual WAN.')
output name string = modVirtualWan.outputs.name

@description('The resource ID of the virtual WAN.')
output resourceId string = modVirtualWan.outputs.resourceId

@description('The resource group the virtual WAN was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = modVirtualWan.outputs.location
