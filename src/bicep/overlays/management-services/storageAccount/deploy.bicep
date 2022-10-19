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

// APP SERVICE PARAMETERS

@description('Defines the App Service Plan.')
param parAppServicePlan object 

// SUBSCRIPTIONS PARAMETERS

@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param parTargetSubscriptionId string = subscription().subscriptionId

@description('The name of the resource group in which the key vault will be deployed. If unchanged or not specified, the NoOps Accelerator shared services resource group is used.')
param parTargetResourceGroup string

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

// APP SERVICE PLAN NAMES

var varAppServicePlanName = 'AppSvcsPlan'
var varServiceHealtResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varAppServicePlanName)

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
resource rgAppServicePlanRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varServiceHealtResourceGroupName
  location: parLocation
}

// Create App Service Plan
module appServicePlan '../../../azresources/Modules/Microsoft.Web/serverfarms/az.app.service.plan.bicep' = {
  name: 'appServicePlanName'
  scope: resourceGroup(parTargetSubscriptionId, rgAppServicePlanRg.name)
  params: {    
    location: parLocation    
    appServicePlanName: varAppServicePlanName
    appServicePlanSku:  parAppServicePlan.appServicePlanSku         
  }
}

output appServicePlanName string = varAppServicePlanName
output resourceGroupName string = parTargetResourceGroup
output tags object = modTags.outputs.tags
