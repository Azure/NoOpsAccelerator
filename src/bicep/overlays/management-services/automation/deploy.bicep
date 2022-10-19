
// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Module to deploy a Automation Account to the Ops Network
DESCRIPTION: The following components will be options in this deployment
              Automation Account
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

targetScope = 'subscription'

// REQUIRED PARAMETERS

@description('Prefix value which will be prepended to all resource names. Default: org')
param parOrgPrefix string = 'org'

@minLength(3)
@maxLength(15)
@description('A suffix, 3 to 15 characters in length, to append to resource names (e.g. "dev", "test", "prod"). ')
param parDeployEnvironment string

@description('The ANOA template version')
@minLength(3)
param parTemplateVersion string = '1.0'

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

//
@description('The subscription ID for the Automation Account. It defaults to the deployment subscription.')
param parOperationsSubscriptionId string = subscription().subscriptionId

@description('The resource group ID for the Automation Account. It defaults to the deployment subscription.')
param parOperationsResourceGroupName string = ''

param parDiagnosticStorageAccountName string
//

@description('[Free/Standard/Premium/PerNode/PerGB2018/Standalone] The SKU for the Log Analytics Workspace. It defaults to "PerGB2018". See https://docs.microsoft.com/en-us/azure/azure-monitor/logs/resource-manager-workspace for valid settings.')
param parLogAnalyticsWorkspaceName string 

//

@description('Optional. Specify the type of lock.')
param parLockLevel string = 'NotSpecified'

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()


//=== TAGS === 

@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'Automation-Acct-Tags-${parDeploymentNameSuffix}'
 params: {  
    onlyUpdate: true
    subscriptionId: parOperationsSubscriptionId
    tags: {
      applicationName: 'automationAccount'
      organizationName: parOrgPrefix
      hostName: parDeployEnvironment
      regionName: parLocation
      templateVersion: parTemplateVersion
    }
  }
}

module automationAccountResourceGroup '../../../azresources/Modules/Microsoft.Resources/resourceGroups/az.resource.groups.bicep' = {
  name: 'deploy-rg-aa-${parDeploymentNameSuffix}'
  scope: subscription(parOperationsSubscriptionId)
  params: {
    name: '${parOrgPrefix}-${parLocation}-${parDeployEnvironment}-automation-rg'
    location: parLocation
    tags: modTags.outputs.tags
  }
}

module modAutomationAccount '../../../azresources/Modules/Microsoft.Automation/automationAccounts/az.automation.account.bicep' = {
  scope: resourceGroup(parOperationsSubscriptionId, '${parOrgPrefix}-${parLocation}-${parDeployEnvironment}-automation-rg')
  name: 'deploy-aa-${parDeploymentNameSuffix}'
  params: {
    name: '${parOrgPrefix}-${parLocation}-${parDeployEnvironment}-automation-aa'
    location: parLocation    
    tags: modTags.outputs.tags
    lock: parLockLevel
    diagnosticStorageAccountId: parDiagnosticStorageAccountName    
    diagnosticWorkspaceId: parLogAnalyticsWorkspaceName
  } 
  dependsOn: [
    automationAccountResourceGroup
  ]
}

output outAutomationAccountName string = modAutomationAccount.name
output outAutomationAccountId string = modAutomationAccount.outputs.systemAssignedPrincipalId
