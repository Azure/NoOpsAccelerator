/*
SUMMARY: Workload Module to deploy a Azure Kubernetes Service to an target sub.
DESCRIPTION: The following components will be options in this deployment
              Azure Kubernetes Service
AUTHOR/S: jspinella

*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

// === PARAMETERS ===
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

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

// WORKLOAD PARAMETERS

@description('Required values used with the workload, Please review the Read Me for required parameters')
param parWorkloadSpoke object

// HUB NETWORK PARAMETERS

@description('The subscription ID for the Hub Network.')
param parHubSubscriptionId string

// Hub Resource Group Name
// (JSON Parameter)
// ---------------------------
// "parHubResourceGroupName": {
//   "value": "anoa-eastus-platforms-hub-rg"
// }
@description('The resource group name for the Hub Network.')
param parHubResourceGroupName string

// Hub Virtual Network Name
// (JSON Parameter)
// ---------------------------
// "parHubResourceGroupName": {
//   "value": "anoa-eastus-platforms-hub-rg"
// }
@description('The virtual network name for the Hub Network.')
param parHubVirtualNetworkName string

// Hub Virtual Network Resource Id
// (JSON Parameter)
// ---------------------------
// "parHubVirtualNetworkResourceId": {
//   "value": "/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourceGroups/anoa-eastus-platforms-hub-rg/providers/Microsoft.Network/virtualNetworks/anoa-eastus-platforms-hub-vnet/subnets/anoa-eastus-platforms-hub-vnet"
// }
@description('The virtual network resource Id for the Hub Network.')
param parHubVirtualNetworkResourceId string

// LOGGING PARAMETERS

@description('Log Analytics Workspace Resource Id Needed for NSG, VNet and Activity Logging')
param parLogAnalyticsWorkspaceResourceId string

@description('Log Analytics Workspace Name Needed Activity Logging')
param parLogAnalyticsWorkspaceName string

// Azure Container Registry
// Example (JSON)
// -----------------------------
// "parContainerRegistry": {
//   "value": {
//     "name": "anoa-eastus-dev-acr",
//     "acrSku": "Premium",
//     "enableResourceLock": true,
//     "privateEndpoints": [
//       {
//         "privateDnsZoneGroup": {
//           "privateDNSResourceIds": [
//             "/subscriptions/<<subscriptionId>>/resourceGroups/validation-rg/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io"
//           ]
//         },
//         "service": "registry",
//         "subnetResourceId": "/subscriptions/<<subscriptionId>>/resourceGroups/validation-rg/providers/Microsoft.Network/virtualNetworks/adp-<<namePrefix>>-az-vnet-x-001/subnets/<<namePrefix>>-az-subnet-x-005-privateEndpoints"
//       }
//     ]
//   }
// }
@description('Defines the Container Registry.')
param parContainerRegistry object

// Azure Kubernetes Service - Cluster
// Example (JSON)
// -----------------------------
// "parKubernetesCluster": {
//   "value": {
//     "name": "anoa-eastus-dev-aks",
//     "enableSystemAssignedIdentity": true,
//     "aksClusterKubernetesVersion": "1.21.9",
//     "enableResourceLock": true,
//     "primaryAgentPoolProfile": [
//       {
//         "name": "aksPoolName",
//         "vmSize": "Standard_DS3_v2",
//         "osDiskSizeGB": 128,
//         "count": 2,
//         "osType": "Linux",
//         "type": "VirtualMachineScaleSets",
//         "mode": "System"
//       }
//     ],
//     "aksClusterLoadBalancerSku": "standard",
//     "aksClusterNetworkPlugin": "azure",
//     "aksClusterNetworkPolicy": "azure",
//     "aksClusterDnsServiceIP": "",
//     "aksClusterServiceCidr": "",
//     "aksClusterDockerBridgeCidr": "",
//     "aksClusterDnsPrefix": "anoaaks"
//   }
// }
@description('Parmaters Object of Azure Kubernetes specified when creating the managed cluster.')
param parKubernetesCluster object

// Storage Account RBAC
// Example (JSON)
// -----------------------------
// "parStorageAccountAccess": {
//   "value": {
//     "enableRoleAssignmentForStorageAccount": true,
//     "principalIds": [
//       "xxxxxx-xxxxx-xxxxx-xxxx-xxxxxxx"
//     ],
//     "roleDefinitionIdOrName": "Group"
//   }
// },  
@description('Account for access to Storage')
param parWorkloadStorageAccountAccess object


// Telemetry - Azure customer usage attribution
// Reference:  https://docs.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution
var telemetry = json(loadTextContent('../../azresources/Modules/Global/telemetry.json'))
module telemetryCustomerUsageAttribution '../../azresources/Modules/Global/partnerUsageAttribution/customer-usage-attribution-subscription.bicep' = if (telemetry.customerUsageAttribution.enabled) {
  name: 'pid-${telemetry.customerUsageAttribution.modules.workloads.aks}'
  scope: subscription(parWorkloadSpoke.subscriptionId)
}

//=== TAGS === 

var referential = {
  workload: parWorkloadSpoke.name
}

@description('Resource group tags')
module modTags '../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'AKS-Resource-Tags-${parDeploymentNameSuffix}'
  scope: subscription()
  params: {
    tags: union(parTags, referential)
  }
}

//=== Workload Tier 3 Buildout === 
module modTier3 '../../overlays/management-services/workloadSpoke/deploy.bicep' = {
  name: 'deploy-wl-vnet-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parWorkloadSpoke.subscriptionId)
  params: {
    //Required Parameters
    parRequired:parRequired
    parLocation: parLocation
    parTags: modTags.outputs.tags

    //Hub Network Parameters
    parHubSubscriptionId: parHubSubscriptionId
    parHubVirtualNetworkResourceId: parHubVirtualNetworkResourceId
    parHubVirtualNetworkName: parHubVirtualNetworkName
    parHubResourceGroupName: parHubResourceGroupName

    //WorkLoad Parameters
    parWorkloadSpoke: parWorkloadSpoke    

    //Logging Parameters
    parLogAnalyticsWorkspaceName: parLogAnalyticsWorkspaceName
    parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
    parEnableActivityLogging: true

    //Storage Parameters
    parWorkloadStorageAccountAccess: parWorkloadStorageAccountAccess
  }
}

//=== End Workload Tier 3 Buildout === 

//=== Azure Kubernetes Service Workload Buildout === 

module modAcrDeploy '../../overlays/management-services/containerRegistry/deploy.bicep' = {
  name: 'deploy-aks-acr-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parWorkloadSpoke.subscriptionId)
  params: {
    parLocation: parLocation
    parContainerRegistry: parContainerRegistry
    parRequired: parRequired
    parTags: modTags.outputs.tags
    parTargetResourceGroup: modTier3.outputs.workloadResourceGroupName
    parTargetSubscriptionId: parWorkloadSpoke.subscriptionId
    parTargetSubnetName: modTier3.outputs.subnetNames[0]
    parTargetVNetName: modTier3.outputs.virtualNetworkName
    parHubVirtualNetworkResourceId: parHubVirtualNetworkResourceId
    parHubResourceGroupName: parHubResourceGroupName
    parHubSubscriptionId: parHubSubscriptionId
  }
  dependsOn: [
    modTier3
  ]
}

// Create a AKS Cluster
module modDeployAzureKS '../../overlays/management-services/kubernetesPrivateCluster-Kubnet/deploy.bicep' = {
  scope: subscription(parWorkloadSpoke.subscriptionId)
  name: 'deploy-aks-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    parLocation: parLocation
    parKubernetesCluster: parKubernetesCluster
    parRequired: parRequired
    parTags: modTags.outputs.tags
    parTargetResourceGroup: modTier3.outputs.workloadResourceGroupName
    parTargetSubnetName: modTier3.outputs.subnetNames[0]
    parTargetVNetName: modTier3.outputs.virtualNetworkName
    parTargetSubscriptionId: parWorkloadSpoke.subscriptionId
    parHubVirtualNetworkResourceId: parHubVirtualNetworkResourceId
    parHubResourceGroupName: parHubResourceGroupName
    parHubSubscriptionId: parHubSubscriptionId
  }
  dependsOn: [
    modTier3
  ]
}

//=== End Azure Kubernetes Service Workload Buildout === 

output azureKubernetesName string = parKubernetesCluster.name
output azureKubernetesResourceId string = modDeployAzureKS.outputs.aksResourceId
output azureContainerRegistryResourceId string = modAcrDeploy.outputs.acrResourceId
output workloadResourceGroupName string = modTier3.outputs.workloadResourceGroupName
output tags object = modTags.outputs.tags
