param deploymentid string = substring(uniqueString(utcNow()),0,6)
param spokeVnets array
param vwan object

targetScope='subscription'

resource resResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: vwan.resourceGroupName
  location: vwan.location
}

module modVwan '../../azresources/vwan-spoke/vdss/vwan/az.net.virtual.wan.with.vhubs.bicep' = {
  name: 'deploy-vwan-${vwan.name}-${deploymentid}'
  scope: resResourceGroup
  params: {
    name: vwan.name
    location: vwan.location
    virtualHubs: vwan.virtualHubs
  }
}

module modSpokeVnets '../../azresources/vwan-spoke/tier3/anoa.lz.vwan.workload.network.bicep' = [for spokeVnet in spokeVnets: {
  name: 'deploy-spokevnet-${spokeVnet.virtualNetworkName}-${deploymentid}'
  params: {
    parLocation: spokeVnet.location
    parTags: spokeVnet.tags
    parVirtualNetworkName: spokeVnet.virtualNetworkName
    parWorkloadResourceGroupName: spokeVnet.resourceGroupName
    parSubnets: spokeVnet.subnets
    parWorkloadVirtualNetworkAddressPrefix: spokeVnet.addressPrefix
  }
}]

module modSpokeVnetConnections '../../azresources/Modules/Microsoft.Network/virtualHubs/hubVirtualNetworkConnections/az.net.virutal.hub.vNet.connection.bicep' = [for (spokeVnet,i) in spokeVnets: {
  name: 'deploy-connection-${spokeVnet.virtualNetworkName}-${deploymentid}'
  scope: resResourceGroup
  dependsOn: [
    modSpokeVnets
    modVwan
  ]
  params: {
    name: spokeVnet.virtualNetworkName
    remoteVirtualNetworkId: modSpokeVnets[i].outputs.virtualNetworkResourceId
    virtualHubName: spokeVnet.virtualHubName
  } 
}]
