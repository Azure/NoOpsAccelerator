/* Copyright (c) Microsoft Corporation. Licensed under the MIT license. */
@description('Required. Name of the Log Analytics workspace.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Service Tier: PerGB2018, Free, Standalone, PerGB or PerNode.')
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
param serviceTier string = 'PerGB2018'

@description('Optional. List of storage accounts to be read by the workspace.')
param storageInsightsConfigs array = []

@description('Optional. List of services to be linked.')
param linkedServices array = []

@description('Conditional. List of Storage Accounts to be linked. Required if \'forceCmkForQuery\' is set to \'true\' and \'savedSearches\' is not empty.')
param linkedStorageAccounts array = []

@description('Optional. Kusto Query Language searches to save.')
param savedSearches array = []

@description('Optional. LAW data sources to configure.')
param dataSources array = []

@description('Optional. List of gallerySolutions to be created in the log analytics workspace.')
param gallerySolutions array = []

@description('Optional. Number of days data will be retained for.')
@minValue(0)
@maxValue(730)
param dataRetention int = 365

@description('Optional. The workspace daily quota for ingestion.')
@minValue(-1)
param dailyQuotaGb int = -1

@description('Optional. The network access type for accessing Log Analytics ingestion.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForIngestion string = 'Enabled'

@description('Optional. The network access type for accessing Log Analytics query.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForQuery string = 'Enabled'

@description('Optional. Set to \'true\' to use resource or workspace permissions and \'false\' (or leave empty) to require workspace permissions.')
param useResourcePermissions bool = false

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of a log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@description('Optional. Indicates whether customer managed storage is mandatory for query management.')
param forceCmkForQuery bool = true

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Tags of the resource.')
param tags object = {}


@description('Optional. The name of logs that will be streamed.')
@allowed([
  'Audit'
])
param diagnosticLogCategoriesToEnable array = [
  'Audit'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. The name of the diagnostic setting, if deployed.')
param diagnosticSettingsName string = '${name}-diagnosticSettings'

var diagnosticsLogs = [for category in diagnosticLogCategoriesToEnable: {
  category: category
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var logAnalyticsSearchVersion = 1

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  location: location
  name: name
  tags: tags
  properties: {
    features: {
      searchVersion: logAnalyticsSearchVersion
      enableLogAccessUsingOnlyResourcePermissions: useResourcePermissions
    }
    sku: {
      name: serviceTier
    }
    retentionInDays: dataRetention
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
    forceCmkForQuery: forceCmkForQuery
  }
}

resource logAnalyticsWorkspace_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if ((!empty(diagnosticStorageAccountId)) || (!empty(diagnosticWorkspaceId)) || (!empty(diagnosticEventHubAuthorizationRuleId)) || (!empty(diagnosticEventHubName))) {
  name: diagnosticSettingsName
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  scope: logAnalyticsWorkspace
}

module logAnalyticsWorkspace_storageInsightConfigs './storageInsightConfigs/az.operational.insights.storage.config.bicep' = [for (storageInsightsConfig, index) in storageInsightsConfigs: {
  name: '${uniqueString(deployment().name, location)}-LAW-StorageInsightsConfig-${index}'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.name
    containers: contains(storageInsightsConfig, 'containers') ? storageInsightsConfig.containers : []
    tables: contains(storageInsightsConfig, 'tables') ? storageInsightsConfig.tables : []
    storageAccountId: storageInsightsConfig.storageAccountId
    
  }
}]

module logAnalyticsWorkspace_linkedServices './linkedServices/az.operational.insights.linked.service.bicep' = [for (linkedService, index) in linkedServices: {
  name: '${uniqueString(deployment().name, location)}-LAW-LinkedService-${index}'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.name
    name: linkedService.name
    resourceId: contains(linkedService, 'resourceId') ? linkedService.resourceId : ''
    writeAccessResourceId: contains(linkedService, 'writeAccessResourceId') ? linkedService.writeAccessResourceId : ''
  }
}]

module logAnalyticsWorkspace_linkedStorageAccounts './linkedStorageAccounts/az.operational.insights.linked.storage.account.bicep' = [for (linkedStorageAccount, index) in linkedStorageAccounts: {
  name: '${uniqueString(deployment().name, location)}-LAW-LinkedStorageAccount-${index}'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.name
    name: linkedStorageAccount.name
    resourceId: linkedStorageAccount.resourceId
    
  }
}]

module logAnalyticsWorkspace_savedSearches './savedSearches/az.operational.insights.linked.saved.search.bicep' = [for (savedSearch, index) in savedSearches: {
  name: '${uniqueString(deployment().name, location)}-LAW-SavedSearch-${index}'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.name
    name: '${savedSearch.name}${uniqueString(deployment().name)}'    
    displayName: savedSearch.displayName
    category: savedSearch.category
    query: savedSearch.query
    functionAlias: contains(savedSearch, 'functionAlias') ? savedSearch.functionAlias : ''
    functionParameters: contains(savedSearch, 'functionParameters') ? savedSearch.functionParameters : ''
    version: contains(savedSearch, 'version') ? savedSearch.version : 2
    
  }
  dependsOn: [
    logAnalyticsWorkspace_linkedStorageAccounts
  ]
}]

module logAnalyticsWorkspace_dataSources './dataSources/az.operational.insights.linked.data.source.bicep' = [for (dataSource, index) in dataSources: {
  name: '${uniqueString(deployment().name, location)}-LAW-DataSource-${index}'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.name
    name: dataSource.name
    kind: dataSource.kind
    linkedResourceId: contains(dataSource, 'linkedResourceId') ? dataSource.linkedResourceId : ''
    eventLogName: contains(dataSource, 'eventLogName') ? dataSource.eventLogName : ''
    eventTypes: contains(dataSource, 'eventTypes') ? dataSource.eventTypes : []
    objectName: contains(dataSource, 'objectName') ? dataSource.objectName : ''
    instanceName: contains(dataSource, 'instanceName') ? dataSource.instanceName : ''
    intervalSeconds: contains(dataSource, 'intervalSeconds') ? dataSource.intervalSeconds : 60
    counterName: contains(dataSource, 'counterName') ? dataSource.counterName : ''
    state: contains(dataSource, 'state') ? dataSource.state : ''
    syslogName: contains(dataSource, 'syslogName') ? dataSource.syslogName : ''
    syslogSeverities: contains(dataSource, 'syslogSeverities') ? dataSource.syslogSeverities : []
    performanceCounters: contains(dataSource, 'performanceCounters') ? dataSource.performanceCounters : []
  }
}]

module logAnalyticsWorkspace_solutions '../../Microsoft.OperationsManagement/solutions/az.operational.insights.solutions.bicep' = [for (gallerySolution, index) in gallerySolutions: if (!empty(gallerySolutions)) {
  name: '${uniqueString(deployment().name, location)}-LAW-Solution-${index}'
  params: {
    name: gallerySolution.name
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.name
    product: contains(gallerySolution, 'product') ? gallerySolution.product : 'OMSGallery'
    publisher: contains(gallerySolution, 'publisher') ? gallerySolution.publisher : 'Microsoft'
  }
}]

resource logAnalyticsWorkspace_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock)) {
  name: '${logAnalyticsWorkspace.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: logAnalyticsWorkspace
}

module logAnalyticsWorkspace_roleAssignments './rbac/roleAssignments.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-LAW-Rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    resourceId: logAnalyticsWorkspace.id
  }
}]

@description('The resource ID of the deployed log analytics workspace.')
output resourceId string = logAnalyticsWorkspace.id

@description('The resource group of the deployed log analytics workspace.')
output resourceGroupName string = resourceGroup().name

@description('The name of the deployed log analytics workspace.')
output name string = logAnalyticsWorkspace.name

@description('The ID associated with the workspace.')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.properties.customerId

@description('The location the resource was deployed into.')
output location string = logAnalyticsWorkspace.location
