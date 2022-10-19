/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

targetScope = 'subscription'

@description('Required values used with all resources.')
param parRequired object

@description('Required tags values used with all resources.')
param parTags object

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

@description('Hub Virtual network configuration.  See azresources/hub-spoke-core/vdss/hub/readme.md')
param parHub object

@description('Operations Spoke Virtual network configuration.  See azresources/hub-spoke-core/vdms/operations/readme.md')
param parOperationsSpoke object

@description('Enables Operations Network Artifacts Resource Group with KV and Storage account for the ops subscriptions used in the deployment.')
param parNetworkArtifacts object

@description('Enables DDOS deployment on the Hub Network.')
param parDdosStandard object

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

@description('Required. Azure Firewall configuration. Azure Firewall is deployed in Forced Tunneling mode where a route table must be added as the next hop.')
param parAzureFirewall object

@description('Enables logging parmeters and Microsoft Sentinel within the Log Analytics Workspace created in this deployment. See azresources/hub-spoke-core/vdms/logging/readme.md')
param parLogging object
 
@description('Account for access to Storage')
param parWorkloadLogStorageAccountAccess object

@description('Microsoft Defender for Cloud.  It includes contact email and phone.')
param parSecurityCenter object

@description('When set to "true", provisions Azure Bastion Host with Jumpboxes, when specified. It defaults to "false".')
param parRemoteAccess object

@description('Parmaters Object of the Container Registry, Please review the Read Me for required parameters.')
param parContainerRegistry object

@description('Parmaters Object of Azure Kubernetes specified when creating the managed cluster Azure Kubernetes, Please review the Read Me for required parameters.')
param parKubernetesCluster object

@description('Parmaters Object of the workload, Please review the Read Me for required parameters.')
param parAksWorkload object

@description('The firewall source addresses for the Rule Collection Groups, Must be Hub/Spoke addresses.')
param parSourceAddresses array = []

var telemetry = json(loadTextContent('../../azresources/Modules/Global/telemetry.json'))
module telemetryCustomerUsageAttribution '../../azresources/Modules/Global/partnerUsageAttribution/customer-usage-attribution-subscription.bicep' = if (telemetry.customerUsageAttribution.enabled) {
  name: 'pid-${telemetry.customerUsageAttribution.modules.enclaves.sccahubspokeaks}'
  scope: subscription(parHub.subscriptionId)
}

module modHubSpoke '../../platforms/lz-platform-scca-hub-1spoke/deploy.bicep' = {
  name: 'deploy-HubSpoke-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHub.subscriptionId)
  params: {
    parRequired: parRequired
    parLocation: parLocation
    parTags: parTags
    parNetworkArtifacts: parNetworkArtifacts
    parDdosStandard: parDdosStandard
    parHub: parHub 
    parOperationsSpoke: parOperationsSpoke
    parLogging: parLogging  
    parAzureFirewall: parAzureFirewall
    parSecurityCenter: parSecurityCenter
    parRemoteAccess: parRemoteAccess    
  }
}

module modAKSWorkload '../../workloads/wl-aks-spoke/deploy.bicep' = {
  name: 'deploy-wl-aks-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHub.subscriptionId)
  params: {
    parRequired: parRequired
    parLocation: parLocation
    parTags: parTags        
    parHubResourceGroupName: modHubSpoke.outputs.hub.resourceGroupName
    parHubSubscriptionId: modHubSpoke.outputs.hub.subscriptionId
    parHubVirtualNetworkName: modHubSpoke.outputs.hub.virtualNetworkName
    parHubVirtualNetworkResourceId: modHubSpoke.outputs.hub.virtualNetworkResourceId
    parWorkloadSpoke: parAksWorkload
    parContainerRegistry: parContainerRegistry
    parKubernetesCluster: parKubernetesCluster
    parLogAnalyticsWorkspaceName: modHubSpoke.outputs.logAnalyticsWorkspaceName
    parLogAnalyticsWorkspaceResourceId: modHubSpoke.outputs.logAnalyticsWorkspaceResourceId
    parWorkloadStorageAccountAccess: parWorkloadLogStorageAccountAccess 
  }        
}
