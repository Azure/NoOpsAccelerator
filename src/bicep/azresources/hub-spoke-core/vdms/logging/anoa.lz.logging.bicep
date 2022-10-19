/*
SUMMARY: Module to deploy the Logging based on the Azure Mission Landing Zone conceptual architecture 
DESCRIPTION: The following components will be options in this deployment
              Log Analytics Workspace
              Log Storage
              Diagnostic Logging
AUTHOR/S: jrspinella

*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

targetScope = 'subscription'

// REQUIRED PARAMETERS

@description('Prefix value which will be prepended to all resource names. Default: org')
param parOrgPrefix string = 'anoa'

@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param parOperationsSubscriptionId string = subscription().subscriptionId

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

@description('Tags')
param parTags object

@minLength(3)
@maxLength(15)
@description('A suffix, 3 to 15 characters in length, to append to resource names (e.g. "dev", "test", "prod"). ')
param parDeployEnvironment string

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

// LOGGING PARAMETERS

@description('The daily quota for Log Analytics Workspace logs in Gigabytes. It defaults to "-1" for no quota.')
param parLogAnalyticsWorkspaceCappingDailyQuotaGb int = -1

@minValue(30)
@maxValue(730)
@description('Number of days of log retention for Log Analytics Workspace. - DEFAULT VALUE: 30')
param parLogAnalyticsWorkspaceRetentionInDays int = 30

@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
@description('[Free/Standard/Premium/PerNode/PerGB2018/Standalone] The SKU for the Log Analytics Workspace. It defaults to "PerGB2018". See https://docs.microsoft.com/en-us/azure/azure-monitor/logs/resource-manager-workspace for valid settings.')
param parLogAnalyticsWorkspaceSkuName string = 'PerGB2018'

//SENTINAL PARAMETERS

@description('Switch which allows Sentinel deployment to be disabled. Default: false')
param parDeploySentinel bool = false

// LOGGING PARAMETERS

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param parLogStorageSkuName string = 'Standard_GRS'

// STORAGE ACCOUNTS RBAC
@description('Account for access to Storage')
param parLoggingStorageAccountAccess object

/*
  NAMING CONVENTION
  Here we define a naming conventions for resources.
  First, we take `parDeployEnvironment` and `parDeployEnvironment` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.
*/

var varResourceToken = 'resource_token'
var varNameToken = 'name_token'
var namingConvention = '${toLower(parOrgPrefix)}-${toLower(parLocation)}-${toLower(parDeployEnvironment)}-${varNameToken}-${toLower(varResourceToken)}'

// RESOURCE NAME CONVENTIONS WITH ABBREVIATIONS

var varResourceGroupNamingConvention = replace(namingConvention, varResourceToken, 'rg')
var varLogAnalyticsWorkspaceNamingConvention = replace(namingConvention, varResourceToken, 'log')
var varStorageAccountNamingConvention = toLower('${parDeployEnvironment}st${varNameToken}unique_storage_token')

// LOGGING NAMES

var loggingName = 'logging'
var varLoggingResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, loggingName)
var varLoggingLogStorageAccountShortName = replace(varStorageAccountNamingConvention, varNameToken, loggingName)
var varLoggingLogStorageAccountUniqueName = replace(varLoggingLogStorageAccountShortName, 'unique_storage_token', uniqueString(parOperationsSubscriptionId, parLocation, parDeployEnvironment))
var varLoggingLogStorageAccountName = take(varLoggingLogStorageAccountUniqueName, 23)

// LOG ANALYTICS NAMES

var varLogAnalyticsWorkspaceName = replace(varLogAnalyticsWorkspaceNamingConvention, varNameToken, 'logging')

// Solutions to add to workspace
var varSolutions = [
  {
    deploy: true
    name: 'AgentHealthAssessment'
    product: 'AgentHealthAssessment'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'AzureActivity'
    product: 'AzureActivity'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  {
    deploy: parDeploySentinel
    name: 'SecurityInsights'
    product: 'SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'VMInsights'
    product: 'VMInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'Security'
    product: 'Security'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'ServiceMap'
    publisher: 'Microsoft'
    product: 'ServiceMap'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'ContainerInsights'
    publisher: 'Microsoft'
    product: 'ContainerInsights'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'KeyVaultAnalytics'
    publisher: 'Microsoft'
    product: 'KeyVaultAnalytics'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'ChangeTracking'
    publisher: 'Microsoft'
    product: 'ChangeTracking'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'SQLAssessment'
    publisher: 'Microsoft'
    product: 'SQLAssessment'
    promotionCode: ''
  }
  {
    deploy: true
    name: 'Updates'
    publisher: 'Microsoft'
    product: 'Updates'
    promotionCode: ''
  }
]

// TAGS

@description('Resource group tags')
module modTags '../../../Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'Tags-logging-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parOperationsSubscriptionId)
  params: {
    onlyUpdate: true
    tags: parTags
  }
}

// RESOURCE GROUPS

@description('Logging Resource Group')
module modLoggingResourceGroup '../../../Modules/Microsoft.Resources/resourceGroups/az.resource.groups.bicep' = {
  name: 'deploy-logging-rg-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parOperationsSubscriptionId)
  params: {
    name: varLoggingResourceGroupName
    location: parLocation
    tags: modTags.outputs.tags
  }
}

// STORAGE ACCOUNT

@description('Logging Storage Account')
module modLoggingStorage '../../../Modules/Microsoft.Storage/storageAccounts/az.data.storage.bicep' = {
  name: 'deploy-logging-logStorage-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varLoggingResourceGroupName)
  params: {
    name: varLoggingLogStorageAccountName
    location: parLocation
    storageAccountSku: parLogStorageSkuName
    tags: modTags.outputs.tags
    roleAssignments: (parLoggingStorageAccountAccess.enableRoleAssignmentForStorageAccount) ? [
      {
        principalIds: [
          parLoggingStorageAccountAccess.principalIds
        ]
        principalType: parLoggingStorageAccountAccess.principalType
        roleDefinitionIdOrName: parLoggingStorageAccountAccess.roleDefinitionIdOrName
      }
    ] : []
    lock: 'CanNotDelete'
  }
  dependsOn: [
    modLoggingResourceGroup
  ]
}

// LOG ANALYTICS WORKSPACE

module modLogAnalyticsWorkspace '../../../Modules/Microsoft.OperationalInsights/workspaces/az.app.log.analytics.workspace.bicep' = {
  name: 'deploy-logging-laws-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varLoggingResourceGroupName)
  params: {
    name: varLogAnalyticsWorkspaceName
    location: parLocation
    tags: modTags.outputs.tags
    serviceTier: parLogAnalyticsWorkspaceSkuName
    dataRetention: parLogAnalyticsWorkspaceRetentionInDays
    dailyQuotaGb: parLogAnalyticsWorkspaceCappingDailyQuotaGb
    lock: 'CanNotDelete'
  }
  dependsOn: [
    modLoggingResourceGroup
  ]
}

// LOG ANALYTICS WORKSPACE SOLUTIONS

module modLogAnalyticsWorkspaceSolutions '../../../Modules/Microsoft.OperationsManagement/solutions/az.operational.insights.solutions.bicep' = [for solution in varSolutions: if (solution.deploy) {
  name: 'deploy-laws-${solution.name}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varLoggingResourceGroupName)
  params: {
    location: parLocation
    logAnalyticsWorkspaceName: modLogAnalyticsWorkspace.outputs.name
    name: solution.name
    product: solution.product
    publisher: solution.publisher    
  }
}]

// CENTRAL LOGGING

module logAnalyticsDiagnosticLogging '../../../Modules/Microsoft.Insights/diagnosticSettings/az.insights.diagnostic.setting.bicep' = {
  name: 'deploy-diagnostic-logging-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    diagnosticStorageAccountId: modLoggingStorage.outputs.resourceId
    diagnosticWorkspaceId: modLogAnalyticsWorkspace.outputs.resourceId
  }
  dependsOn: [
    modLoggingResourceGroup
    modLoggingStorage
  ]
}

output outLogAnalyticsWorkspaceName string = modLogAnalyticsWorkspace.outputs.name
output outLogAnalyticsWorkspaceResourceId string = modLogAnalyticsWorkspace.outputs.resourceId
output outLogAnalyticsWorkspaceId string = modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
output outLogAnalyticsSolutions array = varSolutions
