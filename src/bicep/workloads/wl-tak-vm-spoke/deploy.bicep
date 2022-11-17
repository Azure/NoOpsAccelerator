/*
SUMMARY: Workload Module to deploy a Centos VM with TAK Server to an target sub.
DESCRIPTION: The following components will be deployed:
            - Centos 7.4
              - TAK Server 4.6
              - Postgres DB
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
//     "deployEnvironment": "platforms"
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

// Telemetry - Azure customer usage attribution
// Reference:  https://docs.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution
var telemetry = json(loadTextContent('../../azresources/Modules/Global/partnerUsageAttribution/telemetry.json'))
resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (telemetry.customerUsageAttribution.enabled) {
  name: 'pid-${telemetry.customerUsageAttribution.modules.workloads.takvm}-${uniqueString(deployment().name, parLocation)}'
  location: parLocation
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
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
  }
}

//=== End Workload Tier 3 Buildout === 

//=== TAK VM Workload Buildout === 

module takServer '../../overlays/management-services/vm-tak-server/deploy.bicep' =  {
  name: 'deploy-wl-tak-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parWorkloadSpoke.subscriptionId)
  params: {
    parRequired: parRequired 
    parTags: parTags
    parLocation: parLocation
    parTakServer: parWorkloadSpoke.takServer    
  }
}

//=== End TAK VM Workload Buildout === 

//output azureKubernetesName string = parKubernetesCluster.name
//output azureKubernetesResourceId string = modDeployAzureKS.outputs.aksResourceId
//output azureContainerRegistryResourceId string = modAcrDeploy.outputs.acrResourceId
output workloadResourceGroupName string = modTier3.outputs.workloadResourceGroupName
output tags object = modTags.outputs.tags
