// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Module Example to deploy the App Service Plan.
DESCRIPTION: The following components will be options in this deployment
              * App Service Plan
              * App Service Plan Settings (Optional)
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

//  AZURE KEY VAULT PARAMETERS

@description('Defines AZURE KEY VAULT.')
param parKeyVault object

@description('Private Endpoint Subnet Resource Id.')
param parPrivateEndpointSubnetId string = ''

@description('Private DNS Zone Resource Id.')
param parPrivateZoneId string = ''

// SUBSCRIPTIONS PARAMETERS

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
@description('The name of the resource group in which the App Service Plan will be deployed. If unchanged or not specified, the NoOps Accelerator will create an resource group to be used.')
param parTargetResourceGroup string = ''

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

// AZURE KEY VAULT NAMES

var varKeyVaultName = parKeyVault.name
var varKeyVaultResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varKeyVaultName)

//=== TAGS === 

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}

@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-akv-tags--${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parTargetSubscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// AZURE KEY VAULT

// Create Key Vault resource group
resource rgKeyVaultRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varKeyVaultResourceGroupName
  location: parLocation
}

// Create Key Vault
module modKeyVault '../../../azresources/Modules/Microsoft.KeyVault/vaults/az.sec.key.vault.bicep' = {
  name: 'deploy-akv-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetSubscriptionId, rgKeyVaultRg.name)
  params: {
    location: parLocation
    name: varKeyVaultName
    vaultSku: parKeyVault.vaultSku
    enableSoftDelete: parKeyVault.enableSoftDelete
    enablePurgeProtection: parKeyVault.enablePurgeProtection
    softDeleteRetentionInDays: parKeyVault.softDeleteRetentionInDays
    networkAcls: parKeyVault.networkAcls
    enableRbacAuthorization: parKeyVault.enableRbacAuthorization
    enableVaultForDeployment: parKeyVault.enableVaultForDeployment
    enableVaultForTemplateDeployment: parKeyVault.enableVaultForTemplateDeployment
    enableVaultForDiskEncryption: parKeyVault.enableVaultForDiskEncryption
    lock: parKeyVault.enableResourceLock ? 'CanNotDelete' : ''
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDNSResourceIds: [
            parPrivateEndpointSubnetId
          ]
        }
        service: 'vault'
        subnetResourceId: '/subscriptions/<<subscriptionId>>/resourceGroups/validation-rg/providers/Microsoft.Network/virtualNetworks/adp-<<namePrefix>>-az-vnet-x-001/subnets/<<namePrefix>>-az-subnet-x-005-privateEndpoints'
      }
    ]
  }
}

// Create Key Vault Private Dns Zone Group
module modKeyVaultPrivateDnsZoneGroup '../../../azresources/Modules/Microsoft.Network/privateDnsZones/virtualNetworkLinks/az.net.private.dns.vnet.link.bicep' = {
  name: 'deploy-akv-pdns-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parTargetSubscriptionId, rgKeyVaultRg.name)
  params: {
    name: '${modKeyVault.outputs.name}-privateDnsZoneGroup'
    location: parLocation
    privateDnsZoneName: 'privatelink_vaultcore_azure_net'
    virtualNetworkResourceId: parPrivateZoneId
  }  
}

output keyVaultName string = varKeyVaultName
output resourceGroupName string = parTargetResourceGroup
output tags object = modTags.outputs.tags
