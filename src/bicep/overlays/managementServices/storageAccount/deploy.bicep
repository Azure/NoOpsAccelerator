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

// STORAGE ACCOUNT PARAMETERS
// Example (JSON)
// -----------------------------
//"parStorageAccount": {
//        "value": {
//           "storageAccountKind": "Storage",
//           "storageAccountSku": "Standard_LRS"
//        }
//   }
@description('Defines the App Service Plan.')
param parStorageAccount object

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
@description('The name of the resource group in which the service will be deployed. If unchanged or not specified, the NoOps Accelerator will create an resource group to be used.')
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
var varStorageAccountNamingConvention = toLower('${parRequired.deployEnvironment}st${varNameToken}unique_storage_token')

// APP SERVICE PLAN NAMES

var varStorageAccountName = 'AppSvcsPlan'
var varStorageAccountGroupName = replace(varResourceGroupNamingConvention, varNameToken, varStorageAccountName)
var varStorageAccountLogStorageAccountShortName = replace(varStorageAccountNamingConvention, varNameToken, varStorageAccountName)
var varStorageAccountLogStorageAccountUniqueName = replace(varStorageAccountLogStorageAccountShortName, 'unique_storage_token', uniqueString(parTargetSubscriptionId, parLocation, parRequired.deployEnvironment))
var varStorageAccountLogStorageAccountName = take(varStorageAccountLogStorageAccountUniqueName, 23)

//=== TAGS === 

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}

@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-appsvcs-tags--${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parTargetSubscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// APP SERVICE PLAN

// Create App Service Plan resource group
resource rgStorageAccountRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varStorageAccountGroupName
  location: parLocation
}

// Create App Service Plan
module modStorageAccount '../../../azresources/Modules/Microsoft.Storage/storageAccounts/az.data.storage.bicep' = {
  name: 'StorageAccountName'
  scope: resourceGroup(rgStorageAccountRg.name)
  params: {
    // Required parameters
    name: varStorageAccountLogStorageAccountName
    location: parLocation
    // Non-required parameters
    allowBlobPublicAccess: false
    storageAccountKind: parStorageAccount.storageAccountKind
    storageAccountSku: parStorageAccount.storageAccountSku
  }
}

output resourceGroupName string = parTargetResourceGroup
output tags object = modTags.outputs.tags
output storageAccountName string = varStorageAccountLogStorageAccountName
