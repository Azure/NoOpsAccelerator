/*
SUMMARY: Module to deploy the Hub Network Peering to Spokes based on the Azure Mission Landing Zone conceptual architecture 
DESCRIPTION: The following components will be options in this deployment
              hubToSpokePeering
AUTHOR/S: jspinella

*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

// REQUIRED PARAMETERS

// Hub Virtual Network Name
// (JSON Parameter)
// Parmeters Example: /deployments/hubspoke/networking/peering/hub
// ---------------------------
// "parHubVirtualNetworkName": {
//   "value": "anoa-eastus-platforms-hub-vnet"
// }
@description('The Virtual Network Name for the Hub Network.')
param parHubVirtualNetworkName string

// Spokes
// Example (JSON Parameter)
// Parmeters Example: /deployments/hubspoke/networking/peering/hub
// ---------------------------
//"parSpokes": {
// "value": [
//      {
//          "name": "operations",
//          "virtualNetworkResourceId": "/subscriptions/xxxxx-xxxx-xxxxx-xxxxxx-xxxx/resourceGroups/anoa-eastus-platforms-operations-rg/providers/Microsoft.Network/virtualNetworks/anoa-eastus-platforms-operations-vnet",
//          "virtualNetworkName": "anoa-eastus-platforms-operations-vnet"
//      },                
//      {
//          "name": "sharedServices",
//          "virtualNetworkResourceId": "/subscriptions/xxxxx-xxxx-xxxxx-xxxxxx-xxxx/resourceGroups/anoa-eastus-platforms-sharedservices-rg/providers/Microsoft.Network/virtualNetworks/anoa-eastus-platforms-sharedservices-vnet",
//          "virtualNetworkName": "anoa-eastus-platforms-sharedservices-vnet"
//      },                
//      {
//          "name": "identity",
//          "virtualNetworkResourceId": "/subscriptions/xxxxx-xxxx-xxxxx-xxxxxx-xxxx/resourceGroups/anoa-eastus-platforms-identity-rg/providers/Microsoft.Network/virtualNetworks/anoa-eastus-platforms-identity-vnet",
//          "virtualNetworkName": "anoa-eastus-platforms-identity-vnet"
//      }
//  ]
//}
@description('The Virtual Network ResourceIds and Names for all spokes')
param parSpokes array = [
   {
     name: 'operations'
     virtualNetworkResourceId: ''
     virtualNetworkName: ''
   }
   {
    name: 'identity'
    virtualNetworkResourceId: ''
    virtualNetworkName: ''
  }
  {
    name: 'sharedServices'
    virtualNetworkResourceId: ''
    virtualNetworkName: ''
  }
]

module hubToSpokePeering '../../../Modules/Microsoft.Network/virtualNetworks/virtualNetworkPeering/az.net.virtual.network.peering.bicep' = [ for varSpoke in parSpokes: {
  name: 'hub-to-${varSpoke.name}-vnet-peering'
  params: { 
    name: '${parHubVirtualNetworkName}/to-${varSpoke.virtualNetworkName}'
    remoteVirtualNetworkId: varSpoke.virtualNetworkResourceId
    localVnetName: parHubVirtualNetworkName
  }
}]
