/*
SUMMARY: Module to deploy the Workload Network (tier 3) and it's components based on the Azure Mission Landing Zone conceptual architecture 
DESCRIPTION: The following components will be options in this deployment
              Workload Virtual Network (Vnet)
              Subnets                
AUTHOR/S: joblevin
VERSION: 1.x.x
*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

targetScope = 'subscription'

// REQUIRED PARAMETERS

@description('The subscription ID for the Workload Network and resources. It defaults to the deployment subscription.')
param parWorkloadSubscriptionId string = subscription().subscriptionId

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

@description('The Resource Group name for the Workload Virtual Network.')
param parWorkloadResourceGroupName string

@description('The Virtual Network Name for the Workload Virtual Network.')
param parVirtualNetworkName string

@description('The CIDR Virtual Network Address Prefix for the Workload Virtual Network.')
param deploymentid string = substring(uniqueString(utcNow()),0,6)

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

// NETWORK ADDRESS SPACE PARAMETERS

@description('The CIDR Virtual Network Address Prefix for the Workload Virtual Network.')
param parWorkloadVirtualNetworkAddressPrefix string = '10.8.125.0/26'

@description('The CIDR Virtual Network Address Prefix for the Workload Virtual Network.')
param parSubnets array = [
  {
    name: 'subnet-01'
    addressPrefix: '10.8.125.0/27'
    serviceEndpoints: []
  }
]

// RESOURCE GROUPS

module modWorkloadResourceGroup '../../Modules/Microsoft.Resources/resourceGroups/az.resource.groups.bicep' = {
  name: 'deploy-rg-${parWorkloadResourceGroupName}-${deploymentid}'
  scope: subscription(parWorkloadSubscriptionId)
  params: {
    name: parWorkloadResourceGroupName
    location: parLocation
  }
}

module modWorkloadVirtualNetwork '../../Modules/Microsoft.Network/virtualNetworks/az.net.virtual.network.with.diagnostics.bicep' = {
  name: 'deploy-vnet-${parVirtualNetworkName}-${deploymentid}'
  scope: resourceGroup(parWorkloadResourceGroupName)
  dependsOn: [
    modWorkloadResourceGroup
  ]
  params: {
    name: parVirtualNetworkName
    location: parLocation
    addressPrefixes: [
      parWorkloadVirtualNetworkAddressPrefix
    ]
    subnets: [ for subnet in parSubnets: {
      name: subnet.name
      addressPrefix: subnet.addressPrefix
      serviceEndpoints: subnet.serviceEndpoints      
    }]
  }
}

output virtualNetworkName string = modWorkloadVirtualNetwork.outputs.name
output virtualNetworkResourceId string = modWorkloadVirtualNetwork.outputs.resourceId
output subnetNames array = modWorkloadVirtualNetwork.outputs.subnetNames
output subnetResourceIds array = modWorkloadVirtualNetwork.outputs.subnetResourceIds
output workloadResourceGroupName string = parWorkloadResourceGroupName
