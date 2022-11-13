// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Module Example to deploy the Linux VM.
DESCRIPTION: The following components will be options in this deployment
              * Linux VM
AUTHOR/S: jspinella
*/

targetScope = 'subscription' //Deploying at Subscription scope to allow resource groups to be created and resources in one deployment

// REQUIRED PARAMETERS
// Example (JSON)
// These are the required parameters for the deployment
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
// These are the required tags for the deployment
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

// LINUX VM PARAMETERS

@description('Defines the Linux VM.')
param parLinuxVM object 

// TARGETS PARAMETERS

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
@description('The name of the resource group in which the Linux VM will be deployed. If unchanged or not specified, the NoOps Accelerator will create an resource group to be used.')
param parTargetResourceGroup string = ''

// Target Virtual Network Resource Id
// (JSON Parameter)
// ---------------------------
// "parTargetSubnetResourceId": {
//   "value": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxx/resourceGroups/anoa-eastus-platforms-hub-rg/providers/Microsoft.Network/virtualNetworks/anoa-eastus-platforms-hub-vnet/subnets/anoa-eastus-platforms-hub-vnet-sn"
// }
@description('The name of the virtual network in which the Linux VM will be deployed. If unchanged or not specified, the NoOps Accelerator will create an virtual network to be used.')
param parTargetSubnetResourceId string = ''

// Target Netowrk Security Group Resource Id
// (JSON Parameter)
// ---------------------------
// "parTargetNetworkSecurityGroupResourceId": {
//   "value": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxx/resourceGroups/anoa-eastus-platforms-hub-rg/providers/Microsoft.Network/networkSecurityGroups/anoa-eastus-platforms-hub-nsg"
// }
@description('The name of the network security group in which the Windows VM will be deployed. If unchanged or not specified, the NoOps Accelerator will create an network security group to be used.')
param parTargetNetworkSecurityGroupResourceId string = ''

// Log Analytics Workspace Id
// (JSON Parameter)
// ---------------------------
// "parLogAnalyticsWorkspaceId": {
//   "value": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxx/resourceGroups/anoa-eastus-platforms-hub-rg/providers/Microsoft.OperationalInsights/workspaces/anoa-eastus-platforms-hub-rg-logs"
// }
param parLogAnalyticsWorkspaceId string = ''

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
var varIpConfigurationNamingConvention = replace(varNamingConvention, varResourceToken, 'ipconf')
var varNetworkInterfaceNamingConvention = replace(varNamingConvention, varResourceToken, 'nic')

// LINUX VM NAMES

var varLinuxVMName = 'LinuxVM'
var varLinuxVMResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varLinuxVMName)
var varLinuxNetworkInterfaceName = replace(varNetworkInterfaceNamingConvention, varNameToken, varLinuxVMName)
var varLinuxNetworkInterfaceIpConfigurationName = replace(varIpConfigurationNamingConvention, varNameToken, varLinuxVMName)

//=== TAGS === 

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}


@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-linux-tags--${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parTargetSubscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// LINUX VM

// Create Linux VM resource group
resource rgLinuxVMRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varLinuxVMResourceGroupName
  location: parLocation
}

module modLinuxNetworkInterface '../../../azresources/Modules/Microsoft.Network/networkInterfaces/az.net.network.interface.bicep' = {
  name: 'deploy-linux-net-interface-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetSubscriptionId, rgLinuxVMRg.name)
  params: {
    name: varLinuxNetworkInterfaceName
    location: parLocation
    tags: (empty(parTags)) ? modTags : parTags
    networkSecurityGroupResourceId: parTargetNetworkSecurityGroupResourceId
    ipConfigurations: [
      {
        name: varLinuxNetworkInterfaceIpConfigurationName
        subnetResourceId: parTargetSubnetResourceId
        privateIPAllocationMethod: parLinuxVM.networkInterfacePrivateIPAddressAllocationMethod
      }
    ]
  }
}

// Create Linux VM
module modLinuxVirtualMachine '../../../azresources/Modules/Microsoft.Compute/virtualmachines/az.com.virtual.machine.bicep' = {
  name: 'deploy-linux-vm-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetSubscriptionId, rgLinuxVMRg.name)
  params: {   
    name: parLinuxVM.vmName 
    location: parLocation
    tags: (empty(parTags)) ? modTags : parTags

    disablePasswordAuthentication: parLinuxVM.disablePasswordAuthentication
    adminUsername: parLinuxVM.vmAdminUsername    
    adminPassword: parLinuxVM.vmAdminPasswordOrKey

    diagnosticWorkspaceId: parLogAnalyticsWorkspaceId
    encryptionAtHost: parLinuxVM.encryptionAtHost
    imageReference: {
      offer: parLinuxVM.vmImageOffer
      publisher: parLinuxVM.vmImagePublisher
      sku: parLinuxVM.vmImageSku
      version: parLinuxVM.vmImageVersion
    }
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'linux-ipconfig01'
            subnetResourceId: parTargetSubnetResourceId
          }
        ]
        nicSuffix: '${parLinuxVM.vmName}-nic-01'
        enableAcceleratedNetworking: parLinuxVM.enableAcceleratedNetworking
      }
    ]
    osDisk: {
      diskSizeGB: '128'
      createOption: parLinuxVM.vmOsDiskCreateOption
      managedDisk: {
        storageAccountType: parLinuxVM.vmOsDiskType
      }
    }
    osType: 'Linux'
    vmSize: parLinuxVM.vmSize
  }
}

output outLinuxVMName string = varLinuxVMName
output outResourceGroupName string = parTargetResourceGroup
output outTags object = modTags.outputs.tags