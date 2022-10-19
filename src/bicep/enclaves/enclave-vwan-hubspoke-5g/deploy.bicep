/*
SUMMARY: Module Example to deploy the Full Hub/ Multi-Spoke Enclave with 5G Workloads
DESCRIPTION: The following components will be options in this deployment            
            * Hub VWAN with Secured Hubs
            * Spokes (VNET)
             * 5g-Mgmt (Tier 1) - 0 or more
             * 5g-Spoke (Tier 3) - 0 or more
             * 5g-Workloads (Tier 3) - 0 or more
AUTHOR/S: joblevin
VERSION: 1.x.x
*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

/*
  PARAMETERS
  Here are all the parameters a user can override.
  These are the required parameters that Network does not provide a default for:    
*/

// **Scope**
targetScope = 'subscription'

// REQUIRED PARAMETERS
// Example (JSON)
// -----------------------------
// "workloads_5g_Mgmt": {
//   "value": [
//    {
//    }
//   ]
// }
//
// "workloads_5g_Spoke": {
//   "value": [
//    {
//    }
//   ]
// }
//
param vwan object = {}
param workloads_5g_mgmt array
param workloads_5g_spoke array
param spokeVnets array

param deploymentid string = substring(uniqueString(utcNow()),0,6)

// Platform Module - VWAN Multi-Spoke Design
// ----------------------------------------------
//
// ----------------------------------------------
module modVwan '../../platforms/lz-platform-vwan-hub-spokes/deploy.bicep' = {
  name: 'deploy-vwan-${vwan.name}-${deploymentid}'
  scope: subscription(vwan.subId)
  params:{
    vwan: vwan
    spokeVnets: spokeVnets
    deploymentid: deploymentid
  }
}

// Workload Module - 5g-mgmt Workloads
// ----------------------------------------------
//
// ----------------------------------------------
module modWorkloads_5g_mgmt '../../workloads/wl-5g-mgmt/deploy.bicep' = [for workload in workloads_5g_mgmt: {
  name: 'deploy-workload_5g_Mgmt-${workload.name}-${deploymentid}'
  dependsOn: [
    modVwan
  ]
  scope: subscription(workload.subId)
  params:{
    location: workload.location
    arcPrivateLinkScope: workload.arcPrivateLinkScope
    containerRegistry: workload.containerRegistry
    mobileNetwork: workload.mobileNetwork
    monitorPrivateLinkScope: workload.monitorPrivateLinkScope
    resourceGroupName: workload.resourceGroupName
    deploymentid: deploymentid
  }
}]

// Workload Module - 5g-spoke Workloads
// ----------------------------------------------
//
// ----------------------------------------------
//module modWorkloads_5g_Spoke '../../workloads/wl-5g-spoke/deploy.bicep' = [for workload in workloads_5g_Spoke: {
//  scope: subscription()
//
//}]

// Module - AKS Workload
// ----------------------------------------------
//
// ----------------------------------------------
module modAKSWorkload '../../workloads/wl-5g-spoke/deploy.bicep' = [for workload in workloads_5g_spoke: {
  name: 'deploy-HubSpoke-${workload.Location}-${workload.kubernetesCluster.name}-${deploymentid}'
  dependsOn: [
    modWorkloads_5g_mgmt
  ]
  scope: subscription(workload.subscriptionId)
  params: {
    parLocation: workload.location
    parVirtualNetworkName: workload.virtualNetworkName
    parVirtualNetworkResourceGroup: workload.virtualNetworkResourceGroup
    parTags: workload.tags
    parLogAnalyticsWorkspaceName: workload.logAnalyticsWorkspaceName    
    parKubernetesCluster: workload.kubernetesCluster
    parRequired: workload.required    
    parDeploymentNameSuffix: deploymentid
    parLogAnalyticsWorkspaceResourceGroup: workload.logAnalyticsResourceGroup
    parTargetResourceGroup: workload.resourceGroupName
    parTargetSubnetName: workload.subnetName
    parTargetVNetName: workload.virtualNetworkName    
  }  
}]
