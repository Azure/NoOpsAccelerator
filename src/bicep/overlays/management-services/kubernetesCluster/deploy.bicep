// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Module Example to deploy the Azure Kubernetes Cluster.
DESCRIPTION: The following components will be options in this deployment
              * Azure Kubernetes Cluster
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

// AZURE KUBERNETES SERVICE - CLUSTER PARAMETERS

@description('Defines the Azure Kubernetes Service - Cluster.')
param parKubernetesCluster object 

// HUB NETWORK PARAMETERS

@description('The virtual network resource Id for the Hub Network.')
param parHubVirtualNetworkResourceId string

// LOGGING PARAMETERS

@description('Log Analytics Workspace Resource Id Needed for NSG, VNet and Activity Logging')
param parLogAnalyticsWorkspaceResourceId string

// TARGET PARAMETERS

@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param parTargetSubscriptionId string = subscription().subscriptionId

@description('The name of the resource group in which the aks will be deployed. If unchanged or not specified, the NoOps Accelerator shared services resource group is used.')
param parTargetResourceGroup string

@description('The name of the VNet in which the aks will be deployed. If unchanged or not specified, the NoOps Accelerator shared services resource group is used.')
param parTargetVNetName string

@description('The name of the Subnet in which the aks will be deployed. If unchanged or not specified, the NoOps Accelerator shared services resource group is used.')
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

// AZURE KUBERNETES SERVICE - CLUSTER NAMES

var varKubernetesClusterName = 'app'
var varKubernetesClusterResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varKubernetesClusterName)

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}


@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-aks-tags-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parTargetSubscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// AZURE KUBERNETES SERVICE - CLUSTER

// Create Azure Kubernetes Cluster resource group
resource rgKubernetesCluster 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varKubernetesClusterResourceGroupName
  location: parLocation
}

// Get Existing VNet
resource vnet 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: parTargetVNetName
  scope: az.resourceGroup(parTargetResourceGroup)
}

// Get Existing subnet
resource subnetakspvt 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: parTargetSubnetName
}

module privatednsAKSZone '../../../azresources/Modules/Microsoft.Network/privateDnsZones/az.net.private.dns.bicep' = {
  name: 'deploy-akspvtdnszone-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetResourceGroup)
  params: {
    name: (environment().name =~ 'AzureCloud' ? 'privatelink.azmk8s.${environment().suffixes.storage}' : 'privatelink.azmk8s.usgovcloudapi.net')
    location: 'global'    
  }  
}

module aksHubLink '../../../azresources/Modules/Microsoft.Network/privateDnsZones/virtualNetworkLinks/az.net.private.dns.vnet.link.bicep' = {
  name: 'deploy-aksHubLink-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetResourceGroup)
  params: {
    location: 'global'
    virtualNetworkResourceId: parHubVirtualNetworkResourceId 
    privateDnsZoneName: privatednsAKSZone.outputs.name
  }
}

// Create Azure Kubernetes Cluster
module modKubernetesCluster '../../../azresources/Modules/Microsoft.ContainerService/managedClusters/az.container.aks.cluster.bicep' = {
  scope: resourceGroup(parTargetSubscriptionId, rgKubernetesCluster.name)
  name: 'deploy-aks-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    name: '${parKubernetesCluster.name}aks'
    location: parLocation
    nodeResourceGroup: '${parKubernetesCluster.name}-aksInfraRG'
    aksClusterSkuTier: parKubernetesCluster.aksClusterSkuTier
    systemAssignedIdentity: parKubernetesCluster.enableSystemAssignedIdentity
    enableRBAC: parKubernetesCluster.enableRBAC
    lock: parKubernetesCluster.enableResourceLock ? 'CanNotDelete' : '' 
    tags: modTags.outputs.tags
    primaryAgentPoolProfile:  [
      {
        name: parKubernetesCluster.primaryAgentPoolProfile.name
        count: parKubernetesCluster.primaryAgentPoolProfile.count
        maxCount: parKubernetesCluster.primaryAgentPoolProfile.maxCount
        minCount: parKubernetesCluster.primaryAgentPoolProfile.minCount
        maxPods: parKubernetesCluster.primaryAgentPoolProfile.maxPods
        vmSize: parKubernetesCluster.primaryAgentPoolProfile.vmSize
        enableAutoScaling: parKubernetesCluster.primaryAgentPoolProfile.enableAutoScaling
        vnetSubnetID: subnetakspvt.id
        osDiskSizeGB: parKubernetesCluster.primaryAgentPoolProfile.osDiskSizeGB
        osDiskType: parKubernetesCluster.primaryAgentPoolProfile.osDiskType
        osType: parKubernetesCluster.primaryAgentPoolProfile.osType
        osSKU: parKubernetesCluster.primaryAgentPoolProfile.osSKU
        mode: parKubernetesCluster.primaryAgentPoolProfile.mode        
      }
    ]
    //Network Profile
    aksClusterLoadBalancerSku: parKubernetesCluster.networkProfile.aksClusterLoadBalancerSku
    aksClusterNetworkPlugin: parKubernetesCluster.networkProfile.aksClusterNetworkPlugin
    aksClusterNetworkPolicy: parKubernetesCluster.networkProfile.aksClusterNetworkPolicy
    aksClusterKubernetesVersion: parKubernetesCluster.aksClusterKubernetesVersion       
    aksClusterServiceCidr: (!empty(parKubernetesCluster.networkProfile.aksClusterServiceCidr)) ? parKubernetesCluster.networkProfile.aksClusterServiceCidr : ''
    aksClusterDnsServiceIP: (!empty(parKubernetesCluster.networkProfile.aksClusterDnsServiceIP)) ? parKubernetesCluster.networkProfile.aksClusterDnsServiceIP : ''
    aksClusterDockerBridgeCidr: (!empty(parKubernetesCluster.networkProfile.aksClusterDockerBridgeCidr)) ? parKubernetesCluster.networkProfile.aksClusterDockerBridgeCidr : ''
    aksClusterOutboundType: parKubernetesCluster.networkProfile.aksClusterOutboundType
    monitoringWorkspaceId: parLogAnalyticsWorkspaceResourceId
    enablePrivateCluster: parKubernetesCluster.enablePrivateCluster
    azurePolicyEnabled: parKubernetesCluster.enableAzurePolicy
    aadProfileEnableAzureRBAC: parKubernetesCluster.enableAadProfileEnableAzureRBAC
    aadProfileAdminGroupObjectIDs: parKubernetesCluster.aadProfileAdminGroupObjectIDs
    aadProfileManaged: parKubernetesCluster.enableAadProfileManaged
  }
}

output aksResourceId string = modKubernetesCluster.outputs.resourceId 
