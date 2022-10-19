param deploymentid string = substring(uniqueString(utcNow()),0,6)
param resourceGroupName string
param location string
param mobileNetwork object
param arcPrivateLinkScope object
param monitorPrivateLinkScope object
param containerRegistry object

targetScope='subscription'

resource resResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location  
}

/*module resMobileNetworkWithSims '../../overlays/management-services/mobileNetwork/az.mobilenet.mobile.network.with.sims.bicep' = {
  name: 'deploy-${mobileNetwork.name}-${deploymentid}'
  scope: resResourceGroup
  params: {
    name: mobileNetwork.name
    location: mobileNetwork.location
    simGroups: mobileNetwork.simGroups
    dataNetworks: mobileNetwork.dataNetworks
    services: mobileNetwork.services
    simPolicies: mobileNetwork.simPolicies
    slices: mobileNetwork.slices
    packetCoreDataPlanes: mobileNetwork.packetCoreDataPlanes
    packetCoreControlPlanes: mobileNetwork.packetCoreControlPlanes
    sims: mobileNetwork.sims
  }
  dependsOn: [
    resVirtualNetwork
    resArcarcPrivateLinkScope
    resArcarcPrivateLinkScope
    resACR
  ]
}*/

module resArcarcPrivateLinkScope '../../overlays/management-services/hybridCompute/az.hybridcompute.private.link.scope.with.private.endpoint.bicep' = {
  scope: resResourceGroup
  name: 'deploy-${arcPrivateLinkScope.name}-${deploymentid}'
  params: {
    location: arcPrivateLinkScope.location
    name: arcPrivateLinkScope.name
    privateEndpointName: arcPrivateLinkScope.privateEndpointName
    publicNetworkAccess: arcPrivateLinkScope.publicNetworkAccess
    subnetName: arcPrivateLinkScope.subnetName
    virtualNetworkName: arcPrivateLinkScope.virtualNetworkName
    virtualNetworkRG: arcPrivateLinkScope.virtualNetworkRG
    deploymentid: deploymentid    
  }
}

module resMonitormonitorPrivateLinkScope '../../azresources/Modules/Microsoft.Insights/privateLinkScopes/az.insights.private.link.scope.with.log.analytics.workspace.bicep' = {
  scope: resResourceGroup
  name: 'deploy-${monitorPrivateLinkScope.name}-${deploymentid}'
  params: {
    location: monitorPrivateLinkScope.location
    name: monitorPrivateLinkScope.name
    privateEndpointName: monitorPrivateLinkScope.privateEndpointName
    subnetName: monitorPrivateLinkScope.subnetName
    virtualNetworkName: monitorPrivateLinkScope.virtualNetworkName
    virtualNetworkRG: monitorPrivateLinkScope.virtualNetworkRG
    deploymentid: deploymentid
    logAnalyticsWorkspace: monitorPrivateLinkScope.logAnalyticsWorkspace
  }
}

module resACR '../../azresources/Modules/Microsoft.ContainerRegistry/registries/az.container.registry.with.private.endpoint.bicep' = {
  scope: resResourceGroup
  name: 'deploy-${containerRegistry.name}-${deploymentid}'
  params: {
    location: containerRegistry.location
    name: containerRegistry.name
    privateEndpointName: containerRegistry.privateEndpointName
    subnetName: containerRegistry.subnetName
    virtualNetworkName: containerRegistry.virtualNetworkName
    virtualNetworkRG: containerRegistry.virtualNetworkRG
    acrSku: containerRegistry.acrSku
  }
}

/*
Microsoft.HybridCompute/PrivateLinkScopes
Microsoft.Network/privateEndpoints
Microsoft.Network/privateDnsZones - privatelink.his.arc.azure.com
Microsoft.Network/privateDnsZones - privatelink.guestconfiguration.azure.com
Microsoft.Network/privateDnsZones - privatelink.dp.kubernetesconfiguration.azure.com
Microsoft.Network/privateDnsZones/virtualNetworkLinks x3
Microsoft.Network/privateEndpoints/privateDnsZoneGroups
*/
