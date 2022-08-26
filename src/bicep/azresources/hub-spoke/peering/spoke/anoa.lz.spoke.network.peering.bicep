/* Copyright (c) Microsoft Corporation. Licensed under the MIT license. */
/*
SUMMARY: Module to deploy the Spoke Network Peering to Hub based on the Azure Mission Landing Zone conceptual architecture 
DESCRIPTION: The following components will be options in this deployment
              SpokeToHubPeering
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

// REQUIRED PARAMETERS

param parSpokeName string
param parSpokeResourceGroupName string
param parSpokeVirtualNetworkName string

param parHubVirtualNetworkName string
param parHubVirtualNetworkResourceId string

module spokeNetworkPeering '../../../Modules/Microsoft.Network/virtualNetworks/virtualNetworkPeering/az.net.virtual.network.peering.bicep' = {
  name: '${parSpokeName}-to-hub-vnet-peering'
  scope: resourceGroup(parSpokeResourceGroupName)
  params: { 
    name: '${parSpokeVirtualNetworkName}/to-${parHubVirtualNetworkName}'
    remoteVirtualNetworkId: parHubVirtualNetworkResourceId    
    localVnetName: parSpokeVirtualNetworkName
   }
}
