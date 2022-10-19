// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.

// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Module Example to deploy the Databricks Workspace.
DESCRIPTION: The following components will be options in this deployment
              * Databricks Workspace
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

// DATA BRICKS WORKSPACE PARAMETERS

@description('Defines the Databricks Workspace.')
param parDataBricksWorkspace object 

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

// SERVICE HEALTH NAMES

var varDatabricksWorkspaceName = 'databricks'
var varDatabricksWorkspaceResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varDatabricksWorkspaceName)

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}


@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-databricks-tags-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parTargetSubscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// AZURE DATA BRICKS WORKSPACE

// Create Databricks Workspace resource group
resource rgDatabricks 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varDatabricksWorkspaceResourceGroupName
  location: parLocation
}

// Create Databricks Workspace
module modDatabricks '../../../azresources/Modules/Microsoft.Databricks/workspaces/az.data.bricks.bicep' = {
  scope: resourceGroup(parTargetSubscriptionId, rgDatabricks.name)
  name: 'deploy-databricks-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    // Required parameters
    name: parDataBricksWorkspace.name
    location: parLocation
    // Non-required parameters
    lock: parDataBricksWorkspace.enableResourceLock ? 'CanNotDelete' : ''  
  }
}

output databricksResourceId string = modDatabricks.outputs.resourceId 
