// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Module Example to deploy the TAK Server with Centos.
DESCRIPTION: The following components will be options in this deployment
              * TAK Server 
              * Centos VM
AUTHOR/S: jspinella
VERSION: 1.x.x
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

// TAK SERVER PARAMETERS

@description('Defines the TAK Server.')
param parTakServer object

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
@description('The name of the log analytics workspace in which the Windows VM will be deployed. If unchanged or not specified, the NoOps Accelerator will create an log analytics workspace to be used.')
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

// TAK SERVER NAMES

var varTakServerName = 'AppSvcsPlan'
var varTakServerResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varTakServerName)

//=== TAGS === 

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}

@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-tak-tags--${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parTargetSubscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// TAK SERVER

// Create TAK Server resource group
resource rgTakServerRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varTakServerResourceGroupName
  location: parLocation
}

// Create Storage Account for TAK Server
module modTakServerStorageAccount '../../../azresources/Modules/Microsoft.Storage/storageAccounts/az.data.storage.bicep' = {
  name: 'deploy-tak-sa-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(rgTakServerRg.name)
  params: {
    name: parTakServer.storageAccount.name
    location: parLocation
    storageAccountSku: parTakServer.storageAccount.sku
    blobServices: parTakServer.storageAccount.blobService
  }
}

module modUploadTak '../../../azresources/Modules/Microsoft.Resources/deploymentScripts/az.resources.deployment.scripts.bicep' =  {
  name: 'deploy-tak-sa-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(rgTakServerRg.name)
  params: {
    name: 'upload-file'
    location: parLocation
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: modTakServerStorageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: modTakServerStorageAccount.outputs.listKeys().keys[0].value
      }
      {
        name: 'CONTENT'
        value: loadTextContent('./media/takserver.rpm')
      }
    ]
    scriptContent: 'echo "$CONTENT" > ${filename} && az storage blob upload -f ${filename} -c ${containerName} -n ${filename}'
  }
}

// Create Centos VM
module modTakServer '../vm-centos-base/deploy.bicep' = {
  name: 'deploy-taksvr-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    parRequired: parRequired
    parTags: parTags
    parVirtualMachine: parTakServer.virtualMachine
    parTargetNetworkSecurityGroupResourceId: parTargetNetworkSecurityGroupResourceId
    parTargetSubnetResourceId: parTargetSubnetResourceId
    parTargetResourceGroup: rgTakServerRg.name
    parTargetSubscriptionId: parTargetSubscriptionId
    parLogAnalyticsWorkspaceId: parLogAnalyticsWorkspaceId
  }
}

// Create TAK Server Setup Script
module modVmTakSetup '../../../azresources/Modules/Microsoft.Compute/virtualmachines/extensions/az.com.virtual.machine.extensions.bicep' = {
  scope: resourceGroup(rgTakServerRg.name)
  name: 'taksvr-setup-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    name: 'setup'
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    virtualMachineName: modTakServer.outputs.outCentosVMName
    settings: {
      fileUris: [
        uri(parTakServer.Scripts.artifactsLocation, 'scripts/installScript.sh${parTakServer.Scripts.artifactsLocationSasToken}')
      ]
    }
    protectedSettings: {
      commandToExecute: 'sh installScript.sh'
    }
  }
  dependsOn: [
    modTakServer
    modTakServerStorageAccount
  ]
}

output outTakServerName string = varTakServerName
output outResourceGroupName string = rgTakServerRg.name
output outTags object = modTags.outputs.tags
