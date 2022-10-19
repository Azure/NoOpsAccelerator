
// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Module to deploy a Automation Account to the Target Network
DESCRIPTION: The following components will be options in this deployment
              Automation Account
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

targetScope = 'subscription'

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

// Diagnostic Storage Account Name
// (JSON Parameter)
// ---------------------------
// "parDiagnosticStorageAccountName": {
//   "value": "xxxxxxxxxxxxxxxxxx"
// }
param parDiagnosticStorageAccountName string

// Log Analytics Workspace Name
// (JSON Parameter)
// ---------------------------
// "parLogAnalyticsWorkspaceName": {
//   "value": "xxxxxxxxxxxxxx"
// }
@description('[Free/Standard/Premium/PerNode/PerGB2018/Standalone] The SKU for the Log Analytics Workspace. It defaults to "PerGB2018". See https://docs.microsoft.com/en-us/azure/azure-monitor/logs/resource-manager-workspace for valid settings.')
param parLogAnalyticsWorkspaceName string 

// Log Analytics Workspace Name
// (JSON Parameter)
// ---------------------------
// "parLockLevel": {
//   "value": "NotSpecified"
// }
@description('Optional. Specify the type of lock.')
param parLockLevel string = 'NotSpecified'

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

var varAutomationAccountName = 'AutomationAccount'
var varAutomationAccountResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varAutomationAccountName)


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

// Create AutomationAccount resource group
resource rgAutomationAccountRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varAutomationAccountResourceGroupName
  location: parLocation
}


module modAutomationAccount '../../../azresources/Modules/Microsoft.Automation/automationAccounts/az.automation.account.bicep' = {
  scope: resourceGroup(parTargetSubscriptionId, rgAutomationAccountRg.name)
  name: 'deploy-aa-${parDeploymentNameSuffix}'
  params: {
    name: '${parRequired.orgPrefix}-${parLocation}-${parRequired.deployEnvironment}-automation-aa'
    location: parLocation    
    tags: modTags.outputs.tags
    lock: parLockLevel
    diagnosticStorageAccountId: parDiagnosticStorageAccountName    
    diagnosticWorkspaceId: parLogAnalyticsWorkspaceName
  } 
}

output outAutomationAccountName string = modAutomationAccount.name
output outAutomationAccountId string = modAutomationAccount.outputs.systemAssignedPrincipalId
