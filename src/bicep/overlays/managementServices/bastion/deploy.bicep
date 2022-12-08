// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Module to deploy a Bastion Host with Windows/Linux Jump Boxes to the Hub Network
DESCRIPTION: The following components will be options in this deployment
              Bastion Host
              Windows VM
              Lunix VM
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

// REQUIRED PARAMETERS

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
param parLocation string = resourceGroup().location

// REMOTE ACCESS PARAMETERS

// Bastion Host (Remote Access)
// Example (JSON)
// -----------------------------
// "parRemoteAccess": {
//   "value": {
//     "enable": true,
//     "bastion": {
//       "sku": "Standard",
//       "subnetAddressPrefix": "10.0.100.160/27",
//       "publicIPAddressAvailabilityZones": [],
//       "linux": {
//         "enable": true,
//         "vmAdminUsername": "azureuser",
//         "enableVmPasswordAuthentication": true,
//         "vmAuthenticationType": "password",
//         "vmAdminPasswordOrKey": "Rem0te@2020246",
//         "vmSize": "Standard_B2s",
//         "vmOsDiskCreateOption": "FromImage",
//         "vmOsDiskType": "Standard_LRS",
//         "vmImagePublisher": "Canonical",
//         "vmImageOffer": "UbuntuServer",
//         "vmImageSku": "18.04-LTS",
//         "vmImageVersion": "latest",
//         "networkInterfacePrivateIPAddressAllocationMethod": "Dynamic"
//       },
//       "windows": {
//         "enable": true,
//         "vmAdminUsername": "azureuser",
//         "VmAdminPassword": "Rem0te@2020246",
//         "vmSize": "Standard_DS1_v2",
//         "vmOsDiskCreateOption": "FromImage",
//         "VmStorageAccountType": "StandardSSD_LRS",
//         "vmImagePublisher": "MicrosoftWindowsServer",
//         "vmImageOffer": "WindowsServer",
//         "vmImageSku": "2019-datacenter",
//         "vmImageVersion": "latest",
//         "networkInterfacePrivateIPAddressAllocationMethod": "Dynamic"
//       }
//     }
//   }
// }
@description('When set to "true", provisions Azure Bastion Host. It defaults to "false".')
param parRemoteAccess object

// HUB NETWORK PARAMETERS

// Hub Subnet Resource Id
// (JSON Parameter)
// ---------------------------
// "parHubSubnetResourceId": {
//   "value": "/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourceGroups/anoa-eastus-platforms-hub-rg/providers/Microsoft.Network/virtualNetworks/anoa-eastus-platforms-hub-vnet/subnets/anoa-eastus-platforms-hub-snet"
// }
@description('The name of the The Hub Subnet Resource Id')
param parHubSubnetResourceId string = ''

// Hub Virtual Network Name
// (JSON Parameter)
// ---------------------------
// "parHubVirtualNetworkName": {
//   "value": "anoa-eastus-platforms-hub-vnet"
// }
@description('The Hub Virtual Network Name for the Hub Network.')
param parHubVirtualNetworkName string

// Hub Network Security Group Resource Id
// (JSON Parameter)
// ---------------------------
// "parHubNetworkSecurityGroupResourceId": {
//   "value": "/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourceGroups/anoa-eastus-platforms-hub-rg/providers/Microsoft.Network/networkSecurityGroups/anoa-eastus-platforms-hub-nsg"
// }
@description('The Hub Network Security Group Resource Id')
param parHubNetworkSecurityGroupResourceId string

// LOGGING PARAMETERS

// Logging Log Analytics Workspace Id
// (JSON Parameter)
// ---------------------------
// "parLogAnalyticsWorkspaceId": {
//   "value": "/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourcegroups/anoa-eastus-platforms-logging-rg/providers/microsoft.operationalinsights/workspaces/anoa-eastus-platforms-logging-log"
// }
@description('Log Analytics Workspace Id Needed for NSG, VNet and Activity Logging')
param parLogAnalyticsWorkspaceId string

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

var varBastionHostNamingConvention = replace(varNamingConvention, varResourceToken, 'bas')
var varPublicIpAddressNamingConvention = replace(varNamingConvention, varResourceToken, 'pip')
var varIpConfigurationNamingConvention = replace(varNamingConvention, varResourceToken, 'ipconf')
var varNetworkInterfaceNamingConvention = replace(varNamingConvention, varResourceToken, 'nic')
var varNetworkSecurityGroupNamingConvention = replace(varNamingConvention, varResourceToken, 'nsg')

// BASTION NAMES

var varBastionHostName = replace(varBastionHostNamingConvention, varNameToken, 'hub')
var varBastionHostPublicIPAddressName = replace(varPublicIpAddressNamingConvention, varNameToken, 'bas')
var varLinuxNetworkInterfaceName = replace(varNetworkInterfaceNamingConvention, varNameToken, 'bas-linux')
var varLinuxNetworkInterfaceIpConfigurationName = replace(varIpConfigurationNamingConvention, varNameToken, 'bas-linux')
var varWindowsNetworkInterfaceName = replace(varNetworkInterfaceNamingConvention, varNameToken, 'bas-windows')
var varWindowsNetworkInterfaceIpConfigurationName = replace(varIpConfigurationNamingConvention, varNameToken, 'bas-windows')
var varBastionHostNetworkSecurityGroupName = replace(varNetworkSecurityGroupNamingConvention, varNameToken, 'bas')

// BASTION VALUES

var varBastionHostPublicIPAddressSkuName = 'Standard'
var varBastionHostPublicIPAddressAllocationMethod = 'Static'

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}

@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = if (empty(parTags)) {
  name: 'deploy-ra-tags--${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription()
  params: {
    tags: union(parTags, referential)
  }
}

resource resHubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: parHubVirtualNetworkName
}

resource resBastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: '${parHubVirtualNetworkName}/AzureBastionSubnet'
  properties: {
    addressPrefix: parRemoteAccess.bastion.subnetAddressPrefix
  }
}

module modBastionHost '../../../azresources/Modules/Microsoft.Network/bastionHost/az.net.bastion.host.bicep' = {
  name: 'deploy-ra-bastionHost-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    // Required parameters
    name: varBastionHostName
    location: parLocation
    tags: (empty(parTags)) ? modTags : parTags
    vNetId: resHubVirtualNetwork.id

    // Non-required parameters
    isCreateDefaultPublicIP: true
    publicIPAddressObject: {
      diagnosticLogCategoriesToEnable: [
        'DDoSMitigationFlowLogs'
        'DDoSMitigationReports'
        'DDoSProtectionNotifications'
      ]
      diagnosticMetricsToEnable: [
        'AllMetrics'
      ]
      name: varBastionHostPublicIPAddressName
      publicIPAllocationMethod: varBastionHostPublicIPAddressAllocationMethod     
      skuName: varBastionHostPublicIPAddressSkuName
      skuTier: 'Regional'
    }
    skuType: parRemoteAccess.bastion.sku    
  }
  dependsOn: [
    resBastionSubnet
  ]
}

module modNetworkSecurityGroupBastion '../../../azresources/Modules/Microsoft.Network/networkSecurityGroups/az.net.network.security.group.with.diagnostics.bicep' = {
  name: 'deploy-nsg-bastion-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    name: varBastionHostNetworkSecurityGroupName
    location: parLocation
    tags: (empty(parTags)) ? modTags : parTags
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          priority: 130
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

module modLinuxNetworkInterface '../../../azresources/Modules/Microsoft.Network/networkInterfaces/az.net.network.interface.bicep' = if (parRemoteAccess.bastion.linux.enable) {
  name: 'deploy-ra-linux-net-interface-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    name: varLinuxNetworkInterfaceName
    location: parLocation
    tags: (empty(parTags)) ? modTags : parTags
    networkSecurityGroupResourceId: parHubNetworkSecurityGroupResourceId
    ipConfigurations: [
      {
        name: varLinuxNetworkInterfaceIpConfigurationName
        subnetResourceId: parHubSubnetResourceId
        privateIPAllocationMethod: parRemoteAccess.bastion.linux.networkInterfacePrivateIPAddressAllocationMethod
      }
    ]
  }
}


module modLinuxAvSet '../../../azresources/Modules/Microsoft.Compute/availabilitySets/az.com.availabilty.set.bicep' = {
  name: 'deploy-ra-lx-avset-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    name: '${take(toLower(uniqueString(resourceGroup().name)), 10)}-linux-avset'
    location: parLocation
    availabilitySetSku: 'Aligned'
  }
}

module modLinuxVirtualMachine '../../../azresources/Modules/Microsoft.Compute/virtualmachines/az.com.virtual.machine.bicep' = if (parRemoteAccess.bastion.linux.enable) {
  name: 'deploy-ra-linux-vm-${parLocation}-${parDeploymentNameSuffix}'
  params: {   
    name: parRemoteAccess.bastion.linux.vmName 
    location: parLocation
    tags: (empty(parTags)) ? modTags : parTags

    disablePasswordAuthentication: parRemoteAccess.bastion.linux.disablePasswordAuthentication
    adminUsername: parRemoteAccess.bastion.linux.vmAdminUsername    
    adminPassword: parRemoteAccess.bastion.linux.vmAdminPasswordOrKey

    diagnosticWorkspaceId: parLogAnalyticsWorkspaceId
    availabilitySetResourceId:modLinuxAvSet.outputs.resourceId
    encryptionAtHost: parRemoteAccess.bastion.encryptionAtHost
    imageReference: {
      offer: parRemoteAccess.bastion.linux.vmImageOffer
      publisher: parRemoteAccess.bastion.linux.vmImagePublisher
      sku: parRemoteAccess.bastion.linux.vmImageSku
      version: parRemoteAccess.bastion.linux.vmImageVersion
    }
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'linux-ipconfig01'
            subnetResourceId: parHubSubnetResourceId
          }
        ]
        nicSuffix: '-nic-01'
        enableAcceleratedNetworking: false
      }
    ]
    osDisk: {
      diskSizeGB: '128'
      createOption: parRemoteAccess.bastion.linux.vmOsDiskCreateOption
      managedDisk: {
        storageAccountType: parRemoteAccess.bastion.linux.vmOsDiskType
      }
    }
    osType: 'Linux'
    vmSize: parRemoteAccess.bastion.linux.vmSize
  }
}

module modWindowsNetworkInterface '../../../azresources/Modules/Microsoft.Network/networkInterfaces/az.net.network.interface.bicep' = if (parRemoteAccess.bastion.windows.enable) {
  name: 'deploy-ra-win-net-interface-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    name: varWindowsNetworkInterfaceName
    location: parLocation
    tags: (empty(parTags)) ? modTags : parTags

    networkSecurityGroupResourceId: parHubNetworkSecurityGroupResourceId
    ipConfigurations: [
      {
        name: varWindowsNetworkInterfaceIpConfigurationName
        subnetResourceId: parHubSubnetResourceId
        privateIPAllocationMethod: parRemoteAccess.bastion.windows.networkInterfacePrivateIPAddressAllocationMethod
      }
    ]

  }
}

module modWinAvSet '../../../azresources/Modules/Microsoft.Compute/availabilitySets/az.com.availabilty.set.bicep' = {
  name: 'deploy-ra-win-avset-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    name: '${take(toLower(uniqueString(resourceGroup().name)), 10)}-windows-avset'
    location: parLocation
    availabilitySetSku: 'Aligned'
  }
}

module modWindowsVirtualMachine '../../../azresources/Modules/Microsoft.Compute/virtualmachines/az.com.virtual.machine.bicep' = if (parRemoteAccess.bastion.windows.enable) {
  name: 'deploy-ra-windows-vm-${parLocation}-${parDeploymentNameSuffix}'
  params: {  
    name: parRemoteAccess.bastion.windows.vmName  
    location: parLocation
    tags: (empty(parTags)) ? modTags : parTags

    adminUsername: parRemoteAccess.bastion.windows.vmAdminUsername
    adminPassword: parRemoteAccess.bastion.windows.vmAdminPassword //kv.getSecret('WindowsVmAdminPassword')
    diagnosticWorkspaceId: parLogAnalyticsWorkspaceId
    availabilitySetResourceId:modWinAvSet.outputs.resourceId
    encryptionAtHost: parRemoteAccess.bastion.encryptionAtHost
    imageReference: {
      offer: parRemoteAccess.bastion.windows.vmImageOffer
      publisher: parRemoteAccess.bastion.windows.vmImagePublisher
      sku: parRemoteAccess.bastion.windows.vmImageSku
      version: parRemoteAccess.bastion.windows.vmImageVersion
    }
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'win-ipconfig01'
            subnetResourceId: parHubSubnetResourceId
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      diskSizeGB: '128'
      createOption: parRemoteAccess.bastion.windows.vmOsDiskCreateOption
      managedDisk: {
        storageAccountType: parRemoteAccess.bastion.windows.vmStorageAccountType
      }
    }
    osType: 'Windows'
    vmSize: parRemoteAccess.bastion.windows.vmSize
  }
}

output linuxVMName string = modLinuxVirtualMachine.outputs.name
output windowsVMName string = modWindowsVirtualMachine.outputs.name
