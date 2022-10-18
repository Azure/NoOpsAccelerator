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
              * Private Endpoints
              * Private DNS Zones
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

// TARGET PARAMETERS

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
resource resVNet 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: parTargetVNetName
  scope: resourceGroup(parTargetResourceGroup)
}

// Get Existing subnet
resource resSubnetakspvt 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: resVNet
  name: parTargetSubnetName
}

module modAksIdentity '../../../azresources/Modules/Microsoft.ManagedIdentity/userAssignedIdentities/az.managed.identity.user.assigned.bicep' = {
  name: 'deploy-aksIdentity-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(rgKubernetesCluster.name)
  params: {
    location: parLocation
  }
}

module modAksContribRoleAssignement '../../../azresources/Modules/Microsoft.Authorization/roleAssignments/resourceGroup/az.auth.role.assignment.rg.bicep' = {
  scope: resourceGroup(rgKubernetesCluster.name)
  name: 'deploy-aksContribRole-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    principalId: modAksIdentity.outputs.principalId
    roleDefinitionIdOrName: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' //Contributor
  }
  dependsOn: [
    modAksIdentity
  ]
}

module modDefAKSAssignment '../../../azresources/Modules/Microsoft.Authorization/policyAssignments/resourceGroup/az.auth.policy.set.assignment.rg.bicep' = {
  name: 'deploy-aksDefPolicy-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(rgKubernetesCluster.name)
  params: {
    location: parLocation
    name: 'EnableDefenderForAKS'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/64def556-fbad-4622-930e-72d1d5589bf5'
  }
  dependsOn: [
    modKubernetesCluster
  ]
}

// Create Azure Kubernetes Cluster
module modKubernetesCluster '../../../azresources/Modules/Microsoft.ContainerService/managedClusters/az.container.aks.cluster.bicep' = {
  scope: resourceGroup(parTargetSubscriptionId, rgKubernetesCluster.name)
  name: 'deploy-aks-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    name: '${parKubernetesCluster.name}aks'
    location: parLocation
    nodeResourceGroup: 'MC${parKubernetesCluster.name}-aksInfraRG'
    aksClusterSkuTier: parKubernetesCluster.aksClusterSkuTier
    systemAssignedIdentity: parKubernetesCluster.enableSystemAssignedIdentity
    userAssignedIdentities: {
      '${modAksIdentity.outputs.resourceId}': {}
    }
    aksClusterKubernetesVersion: parKubernetesCluster.aksClusterKubernetesVersion
    enableRBAC: parKubernetesCluster.enableRBAC
    lock: parKubernetesCluster.enableResourceLock ? 'CanNotDelete' : ''
    tags: modTags.outputs.tags
    podIdentityProfileEnable: parKubernetesCluster.enablePodIdentity
    podIdentityProfileAllowNetworkPluginKubenet: false
    ingressApplicationGatewayEnabled: parKubernetesCluster.enableIngressApplicationGateway
    primaryAgentPoolProfile: [
      {
        name: parKubernetesCluster.primaryAgentPoolProfile.name
        availabilityZones: !empty(parKubernetesCluster.primaryAgentPoolProfile.availabilityZones) ? parKubernetesCluster.primaryAgentPoolProfile.availabilityZones : null
        count: parKubernetesCluster.primaryAgentPoolProfile.count
        minCount: parKubernetesCluster.primaryAgentPoolProfile.enableAutoScaling ? 1 : null
        maxCount: parKubernetesCluster.primaryAgentPoolProfile.enableAutoScaling ? parKubernetesCluster.primaryAgentPoolProfile.count : null
        vmSize: parKubernetesCluster.primaryAgentPoolProfile.vmSize
        enableAutoScaling: parKubernetesCluster.primaryAgentPoolProfile.enableAutoScaling
        vnetSubnetID: resSubnetakspvt.id
        osDiskSizeGB: parKubernetesCluster.primaryAgentPoolProfile.osDiskSizeGB
        osDiskType: parKubernetesCluster.primaryAgentPoolProfile.osDiskType
        osType: parKubernetesCluster.primaryAgentPoolProfile.osType
        osSKU: parKubernetesCluster.primaryAgentPoolProfile.osSKU
        mode: parKubernetesCluster.primaryAgentPoolProfile.mode
      }
    ]
    //Network Profile
    aksClusterLoadBalancerSku: parKubernetesCluster.networkProfile.aksClusterLoadBalancerSku
    aksClusterNetworkPlugin: 'kubenet'
    aksClusterNetworkPolicy: 'calico'
    aksClusterPodCidr: (!empty(parKubernetesCluster.networkProfile.aksClusterPodCidr)) ? parKubernetesCluster.networkProfile.aksClusterPodCidr : ''
    aksClusterServiceCidr: (!empty(parKubernetesCluster.networkProfile.aksClusterServiceCidr)) ? parKubernetesCluster.networkProfile.aksClusterServiceCidr : ''
    aksClusterDnsServiceIP: (!empty(parKubernetesCluster.networkProfile.aksClusterDnsServiceIP)) ? parKubernetesCluster.networkProfile.aksClusterDnsServiceIP : ''
    aksClusterDockerBridgeCidr: (!empty(parKubernetesCluster.networkProfile.aksClusterDockerBridgeCidr)) ? parKubernetesCluster.networkProfile.aksClusterDockerBridgeCidr : ''
    aksClusterOutboundType: parKubernetesCluster.networkProfile.aksClusterOutboundType

    //Addons
    omsAgentEnabled: parKubernetesCluster.addonProfiles.omsagent.enable
    monitoringWorkspaceId: parKubernetesCluster.addonProfiles.omsagent.config.logAnalyticsWorkspaceResourceID
    azurePolicyEnabled: parKubernetesCluster.addonProfiles.enableAzurePolicy

    //ApiServerAccessProfile
    enablePrivateCluster: parKubernetesCluster.apiServerAccessProfile.enablePrivateCluster
    enablePrivateClusterPublicFQDN: parKubernetesCluster.apiServerAccessProfile.enablePrivateClusterPublicFQDN

    //AADProfile
    aadProfileEnableAzureRBAC: parKubernetesCluster.aadProfile.enableAadProfileEnableAzureRBAC
    aadProfileAdminGroupObjectIDs: parKubernetesCluster.aadProfile.aadProfileAdminGroupObjectIDs
    aadProfileManaged: parKubernetesCluster.aadProfile.enableAadProfileManaged
    aadProfileTenantId: parKubernetesCluster.aadProfile.aadProfileTenantId
 
    //ServicePrincipalProfile
    aksServicePrincipalProfile: parKubernetesCluster.servicePrincipalProfile
    roleAssignments: [
      {
        principalIds: [
          modAksIdentity.outputs.principalId
        ]
        roleDefinitionIdOrName: 'Reader'
      }
    ]
  }
  dependsOn: [
    modAksIdentity
    modAksContribRoleAssignement
  ]
}

/* module akspvtEndpoint '../../../azresources/Modules/Microsoft.Network/privateEndPoints/az.net.private.endpoint.bicep' = {
  name: 'deploy-akspvtendpnt-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetResourceGroup)
  params: {
    name: 'akspvtEndpoint'
    location: parLocation
    groupIds:  [
      'management'
    ]
    subnetResourceId: resSubnetakspvt.id
    serviceResourceId: modKubernetesCluster.outputs.resourceId
  }  
}

module privatednsAKSZone '../../../azresources/Modules/Microsoft.Network/privateDnsZones/az.net.private.dns.bicep' = {
  name: 'deploy-akspvtdnszone-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetResourceGroup)
  params: {
    name: (environment().name =~ 'AzureCloud' ? 'privatelink.azmk8s.io' : 'privatelink.azmk8s.us')
    location: 'global'     
  }  
}

module privateDNSAKS '../../../azresources/Modules/Microsoft.Network/privateDnsZones/virtualNetworkLinks/az.net.private.dns.vnet.link.bicep' = {
  name: 'deploy-akspvtdns-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetResourceGroup)
  params: {
    location: 'global'
    virtualNetworkResourceId: resVNet.id
    privateDnsZoneName: privatednsAKSZone.outputs.name
  }
}

module privateAKSDNSZoneGroup  '../../../azresources/Modules/Microsoft.Network/privateEndPoints/privateDnsZoneGroups/az.net.private.dns.groups.bicep' = {
  name: 'deploy-akspvtdnsgrp-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetResourceGroup)
  params:  {
    privateDNSResourceIds: [
      privatednsAKSZone.outputs.resourceId
    ]
    privateEndpointName: akspvtEndpoint.outputs.name
  }
}

module modAKSHubLink '../../../azresources/Modules/Microsoft.Network/privateDnsZones/virtualNetworkLinks/az.net.private.dns.vnet.link.bicep' = {
  name: 'deploy-aksHubLink-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parHubSubscriptionId, parHubResourceGroupName)
  params: {
    virtualNetworkResourceId: parHubVirtualNetworkResourceId
    privateDnsZoneName: privateAKSDNSZoneGroup.name
  }
  dependsOn: [
    modKubernetesCluster
  ]
} */

output aksResourceId string = modKubernetesCluster.outputs.resourceId
output aksIdentityPrincipalId string = modAksIdentity.outputs.principalId
output aksControlPlaneFQDN string = modKubernetesCluster.outputs.controlPlaneFQDN
