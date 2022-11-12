// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Module Example to deploy the Centos VM.
DESCRIPTION: The following components will be options in this deployment
              * Centos VM
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

// CENTOS VM PARAMETERS

@description('Defines the Centos VM.')
param parCentosVM object 

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
@description('The name of the resource group in which the Centos VM will be deployed. If unchanged or not specified, the NoOps Accelerator will create an resource group to be used.')
param parTargetResourceGroup string = ''

// Target Virtual Network Resource Id
// (JSON Parameter)
// ---------------------------
// "parTargetSubnetResourceId": {
//   "value": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxx/resourceGroups/anoa-eastus-platforms-hub-rg/providers/Microsoft.Network/virtualNetworks/anoa-eastus-platforms-hub-vnet/subnets/anoa-eastus-platforms-hub-vnet-sn"
// }
@description('The name of the virtual network in which the Centos VM will be deployed. If unchanged or not specified, the NoOps Accelerator will create an virtual network to be used.')
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

// CENTOS VM NAMES

var varCentosVMName = 'CentosVM'
var varCentosVMResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varCentosVMName)
var varCentosNetworkInterfaceName = replace(varNetworkInterfaceNamingConvention, varNameToken, varCentosVMName)
var varCentosNetworkInterfaceIpConfigurationName = replace(varIpConfigurationNamingConvention, varNameToken, varCentosVMName)

//=== TAGS === 

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}


@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-centos-tags--${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parTargetSubscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// CENTOS VM

// Create Centos VM resource group
resource rgCentosVMRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varCentosVMResourceGroupName
  location: parLocation
}

module modCentosNetworkInterface '../../../azresources/Modules/Microsoft.Network/networkInterfaces/az.net.network.interface.bicep' = {
  name: 'deploy-linux-net-interface-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetSubscriptionId, rgCentosVMRg.name)
  params: {
    name: varCentosNetworkInterfaceName
    location: parLocation
    tags: (empty(parTags)) ? modTags : parTags
    networkSecurityGroupResourceId: parTargetNetworkSecurityGroupResourceId
    ipConfigurations: [
      {
        name: varCentosNetworkInterfaceIpConfigurationName
        subnetResourceId: parTargetSubnetResourceId
        privateIPAllocationMethod: parCentosVM.networkInterfacePrivateIPAddressAllocationMethod
      }
    ]
  }
}

// Create Centos VM
module modCentosVirtualMachine '../../../azresources/Modules/Microsoft.Compute/virtualmachines/az.com.virtual.machine.bicep' = {
  name: 'deploy-centos-vm-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetSubscriptionId, rgCentosVMRg.name)
  params: {   
    name: parCentosVM.vmName 
    location: parLocation
    tags: (empty(parTags)) ? modTags : parTags

    disablePasswordAuthentication: parCentosVM.disablePasswordAuthentication
    adminUsername: parCentosVM.vmAdminUsername    
    adminPassword: parCentosVM.vmAdminPasswordOrKey

    diagnosticWorkspaceId: parLogAnalyticsWorkspaceId
    encryptionAtHost: parCentosVM.encryptionAtHost
    imageReference: {
      offer: parCentosVM.vmImageOffer
      publisher: parCentosVM.vmImagePublisher
      sku: parCentosVM.vmImageSku
      version: parCentosVM.vmImageVersion
    }
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'centos-ipconfig01'
            subnetResourceId: parTargetSubnetResourceId
          }
        ]
        nicSuffix: '${parCentosVM.vmName}-nic-01'
        enableAcceleratedNetworking: parCentosVM.enableAcceleratedNetworking
      }
    ]
    osDisk: {
      diskSizeGB: '128'
      createOption: parCentosVM.vmOsDiskCreateOption
      managedDisk: {
        storageAccountType: parCentosVM.vmOsDiskType
      }
    }
    osType: 'Linux'
    vmSize: parCentosVM.vmSize
  }
}

output outCentosVMName string = varCentosVMName
output outResourceGroupName string = parTargetResourceGroup
output outTags object = modTags.outputs.tags
