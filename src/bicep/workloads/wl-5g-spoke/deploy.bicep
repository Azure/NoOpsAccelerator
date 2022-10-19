/*
SUMMARY: Workload Module to deploy a Azure Kubernetes Service to an target sub.
DESCRIPTION: The following components will be options in this deployment
              Azure Kubernetes Service
AUTHOR/S: jspinella
VERSION: 1.x.x
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

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

// NETWORK PARAMETERS
@description('The virtual network resource group for the cluster.')
param parVirtualNetworkResourceGroup string

@description('The virtual network name for the cluster.')
param parVirtualNetworkName string

// LOGGING PARAMETERS

@description('Log Analytics Workspace Resource Group.')
param parLogAnalyticsWorkspaceResourceGroup string

@description('Log Analytics Workspace Name.')
param parLogAnalyticsWorkspaceName string

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

param parTargetResourceGroup string
param parTargetSubnetName string
param parTargetVNetName string

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

resource resVirtualNetwork 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: parVirtualNetworkName
  scope: resourceGroup(parVirtualNetworkResourceGroup)  
}

resource resLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: parLogAnalyticsWorkspaceName
  scope: resourceGroup(parLogAnalyticsWorkspaceResourceGroup)  
}

// Create a AKS Cluster
module modDeployAzureKS '../../overlays/management-services/kubernetesCluster/deploy.bicep' = {
  name: 'deploy-aks-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    parLocation: parLocation
    parKubernetesCluster: parKubernetesCluster
    parRequired: parRequired
    parTargetResourceGroup: parTargetResourceGroup
    parTargetSubnetName: parTargetSubnetName
    parTargetVNetName: parTargetVNetName
    parTargetSubscriptionId: subscription().subscriptionId
    parHubVirtualNetworkResourceId: resVirtualNetwork.id
    parLogAnalyticsWorkspaceResourceId: resLogAnalyticsWorkspace.id
    parTags: parTags    
  }
}

//=== End Azure Kubernetes Service Workload Buildout === 

output azureKubernetesName string = parKubernetesCluster.name
output azureKubernetesResourceId string = modDeployAzureKS.outputs.aksResourceId
