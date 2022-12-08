// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Module Example to deploy the Container Registry.
DESCRIPTION: The following components will be options in this deployment
              * Container Registry
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

targetScope = 'subscription' //Deploying at Subscription scope to allow resource groups to be created and resources in one deployment

// REQUIRED PARAMETERS
// Example (JSON)
// -----------------------------
// "parRequired": {
//   "value": {
//     "orgPrefix": "anoa",
//     "templateVersion": "v1.0",
//     "deployEnvironment": "mlz"
//   }
// }
@description('Required values used with all resources.')
param parRequired object

// REQUIRED TAGS
// Example (JSON)
// -----------------------------
// "parTags": {
//   "value": {
//     "organization": "anoa",
//     "region": "eastus",
//     "templateVersion": "v1.0",
//     "deployEnvironment": "platforms",
//     "deploymentType": "NoOpsBicep"
//   }
// }
@description('Required tags values used with all resources.')
param parTags object

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

// CONTAINER REGISTRY PARAMETERS

@description('Defines the Container Registry.')
param parContainerRegistry object 

// HUB NETWORK PARAMETERS

// Hub Virtual Network Name
// (JSON Parameter)
// ---------------------------
// "parHubSubscriptionId": {
//   "value": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxx"
// }
@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param parHubSubscriptionId string = subscription().subscriptionId

// Hub Subnet Resource Id
// (JSON Parameter)
// ---------------------------
// "parHubVirtualNetworkResourceId": {
//   "value": "/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourceGroups/anoa-eastus-platforms-hub-rg/providers/Microsoft.Network/virtualNetworks/anoa-eastus-platforms-hub-vnet/subnets/anoa-eastus-platforms-hub-vnet"
// }
@description('The virtual network resource Id for the Hub Network.')
param parHubVirtualNetworkResourceId string = ''

// Hub Resource Group Name
// (JSON Parameter)
// ---------------------------
// "parHubResourceGroupName": {
//   "value": "anoa-eastus-platforms-hub-rg"
// }
@description('The name of the Hub resource group which contains the network for vnet peering.')
param parHubResourceGroupName string = ''

// SUBSCRIPTIONS PARAMETERS

// Target Virtual Network Name
// (JSON Parameter)
// ---------------------------
// "parTargetSubscriptionId": {
//   "value": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxx"
// }
@description('The subscription ID for the Target Network and resources. It defaults to the deployment subscription.')
param parTargetSubscriptionId string = subscription().subscriptionId

// Target Resource Group Name
// (JSON Parameter)
// ---------------------------
// "parTargetResourceGroup": {
//   "value": "anoa-eastus-platforms-hub-rg"
// }
@description('The name of the resource group in which the service will be deployed. If unchanged or not specified, the NoOps Accelerator will create an resource group to be used.')
param parTargetResourceGroup string = ''

// Target Virtual Network Name
// (JSON Parameter)
// ---------------------------
// "parHubVirtualNetworkName": {
//   "value": "anoa-eastus-platforms-hub-vnet"
// }
@description('The name of the VNet in which the aks will be deployed.')
param parTargetVNetName string

// Target Subnet Name
// (JSON Parameter)
// ---------------------------
// "parHubVirtualNetworkName": {
//   "value": "anoa-eastus-platforms-hub-snet"
// }
@description('The name of the Subnet in which the aks will be deployed.')
param parTargetSubnetName string

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()


@description('The current date - do not override the default value')
param dateUtcNow string = utcNow('yyyy-MM-dd HH:mm:ss')

/*
  NAMING CONVENTION
  Here we define a naming conventions for resources.
  First, we take `parDeployEnvironment` and `parDeployEnvironment` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.
*/

var varResourceToken = 'resource_token'
var varNameToken = 'name_token'
var varNamingConvention = '${toLower(parRequired.orgPrefix)}-${toLower(parLocation)}-${toLower(parRequired.deployEnvironment)}-${varNameToken}-${toLower(varResourceToken)}'

// RESOURCE NAME CONVENTIONS WITH ABBREVIATIONS

var varResourceGroupNamingConvention = replace(varNamingConvention, varResourceToken, 'rg')

// SERVICE HEALTH NAMES

var varContainerRegistryName = 'conreg'
var varContainerRegistryResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varContainerRegistryName)

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}


@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-conreg-tags-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parTargetSubscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// AZURE CONTAINER REGISTRY

// Get Existing VNet
resource vnetacrpvt  'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: parTargetVNetName
  scope: az.resourceGroup(parTargetResourceGroup)
}

// Get Existing subnet
resource subnetacrpvt 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnetacrpvt
  name: parTargetSubnetName
}

// Create Container Registry resource group
resource rgContainerRegistry 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varContainerRegistryResourceGroupName
  location: parLocation
}

module acrpvtEndpoint '../../../azresources/Modules/Microsoft.Network/privateEndPoints/az.net.private.endpoint.bicep' = {
  name: 'deploy-acrpvtendpnt-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetResourceGroup)
  params: {
    name: 'acrpvtEndpoint'
    location: parLocation
    groupIds:  [
      'registry'
    ]
    subnetResourceId: subnetacrpvt.id
    serviceResourceId: modContainerRegistry.outputs.resourceId
  }  
}

module privatednsACRZone '../../../azresources/Modules/Microsoft.Network/privateDnsZones/az.net.private.dns.bicep' = {
  name: 'deploy-acrpvtdnszone-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetResourceGroup)
  params: {
    name: 'privatelink${environment().suffixes.acrLoginServer}'
    location: 'global'     
  }  
  dependsOn: [
    acrpvtEndpoint
  ]
}

module privateDNSACR '../../../azresources/Modules/Microsoft.Network/privateDnsZones/virtualNetworkLinks/az.net.private.dns.vnet.link.bicep' = {
  name: 'deploy-acrpvtdns-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetResourceGroup)
  params: {
    location: 'global'
    virtualNetworkResourceId: vnetacrpvt.id
    privateDnsZoneName: privatednsACRZone.outputs.name
  }
  dependsOn: [
    privatednsACRZone
  ]
}

module privateACRDNSZoneGroup  '../../../azresources/Modules/Microsoft.Network/privateEndPoints/privateDnsZoneGroups/az.net.private.dns.groups.bicep' = {
  name: 'deploy-acrpvtdnsgrp-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetResourceGroup)
  params:  {
    privateDNSResourceIds: [
      privatednsACRZone.outputs.resourceId
    ]
    privateEndpointName: acrpvtEndpoint.outputs.name
  }
  dependsOn: [
    acrpvtEndpoint
    privatednsACRZone
    privateDNSACR
  ]
}

// Create Container Registry
module modContainerRegistry '../../../azresources/Modules/Microsoft.ContainerRegistry/registries/az.container.registry.bicep' = {
  scope: resourceGroup(parTargetSubscriptionId, rgContainerRegistry.name)
  name: 'deploy-conReg-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    // Required parameters
    name: parContainerRegistry.name
    location: parLocation
    // Non-required parameters
    acrSku: parContainerRegistry.acrSku    
    lock: parContainerRegistry.enableResourceLock ? 'CanNotDelete' : ''
    publicNetworkAccess: 'Disabled'   
  }
}

output acrResourceId string = modContainerRegistry.outputs.resourceId 
