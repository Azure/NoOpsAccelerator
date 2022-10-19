// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

@description('Required. Name of your Azure container registry.')
@minLength(5)
@maxLength(50)
param name string

@description('Optional. Enable admin user that have push / pull permission to the registry.')
param acrAdminUserEnabled bool = false

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Tier of your Azure container registry.')
@allowed([
  'Basic'
  'Premium'
  'Standard'
])
param acrSku string = 'Basic'

@allowed([
  'disabled'
  'enabled'
])
@description('Optional. The value that indicates whether the export policy is enabled or not.')
param exportPolicyStatus string = 'disabled'

@allowed([
  'disabled'
  'enabled'
])
@description('Optional. The value that indicates whether the quarantine policy is enabled or not.')
param quarantinePolicyStatus string = 'disabled'

@allowed([
  'disabled'
  'enabled'
])
@description('Optional. The value that indicates whether the trust policy is enabled or not.')
param trustPolicyStatus string = 'disabled'

@allowed([
  'disabled'
  'enabled'
])
@description('Optional. The value that indicates whether the retention policy is enabled or not.')
param retentionPolicyStatus string = 'enabled'

@description('Optional. The number of days to retain an untagged manifest after which it gets purged.')
param retentionPolicyDays int = 15

@description('Optional. Enable a single data endpoint per region for serving data. Not relevant in case of disabled public access.')
param dataEndpointEnabled bool = false

@description('Optional. Whether or not public network access is allowed for this resource. For security reasons it should be disabled. If not specified, it will be disabled by default if private endpoints are set.')
@allowed([
  ''
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = ''

@description('Optional. Whether to allow trusted Azure services to access a network restricted registry. Not relevant in case of public access. - AzureServices or None.')
param networkRuleBypassOptions string = 'AzureServices'

@allowed([
  'Allow'
  'Deny'
])
@description('Optional. The default action of allow or deny when no other rules match.')
param networkRuleSetDefaultAction string = 'Deny'

@description('Optional. The IP ACL rules.')
param networkRuleSetIpRules array = []

@allowed([
  'Disabled'
  'Enabled'
])
@description('Optional. Whether or not zone redundancy is enabled for this container registry.')
param zoneRedundancy string = 'Disabled'

@description('Optional. All replications to create.')
param replications array = []

@description('Optional. All webhooks to create.')
param webhooks array = []

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. Tags of the resource.')
param tags object = {}


@description('Optional. The name of logs that will be streamed.')
@allowed([
  'ContainerRegistryRepositoryEvents'
  'ContainerRegistryLoginEvents'
])
param diagnosticLogCategoriesToEnable array = [
  'ContainerRegistryRepositoryEvents'
  'ContainerRegistryLoginEvents'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@description('Optional. The name of the diagnostic setting, if deployed.')
param diagnosticSettingsName string = '${name}-diagnosticSettings'

@description('Optional. The resource ID of a key vault to reference a customer managed key for encryption from. Note, CMK requires the \'acrSku\' to be \'Premium\'.')
param cMKKeyVaultResourceId string = ''

@description('Optional. The name of the customer managed key to use for encryption. Note, CMK requires the \'acrSku\' to be \'Premium\'.')
param cMKKeyName string = ''

@description('Optional. The version of the customer managed key to reference for encryption. If not provided, the latest key version is used.')
param cMKKeyVersion string = ''

@description('Conditional. User assigned identity to use when fetching the customer managed key. Note, CMK requires the \'acrSku\' to be \'Premium\'. Required if \'cMKKeyName\' is not empty.')
param cMKUserAssignedIdentityResourceId string = ''

@description('The resource group name for the existing virtual network.')
param virtualNetworkRG string

@description('The name for the existing virtual network.')
param virtualNetworkName string

@description('The name for the existing subnet.')
param subnetName string

@description('The name for the private endpoint.')
param privateEndpointName string

@description('Deployment id to associate sub-deployments.')
param deploymentid string = substring(uniqueString(utcNow()),0,6)

var privateEndpoints = [
  {
    location: location
    service: 'registry'
    name: privateEndpointName
    subnetResourceId: subnet.id
  }
]

resource virtualNetwork 'Microsoft.Network/virtualnetworks@2015-05-01-preview' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkRG)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: subnetName
  parent: virtualNetwork
}

module registry 'az.container.registry.bicep' = {
  name: 'deploy-${name}-${deploymentid}'  
  params: {
    name: name
    acrAdminUserEnabled: acrAdminUserEnabled
    acrSku: acrSku
    cMKKeyName: cMKKeyName
    cMKKeyVaultResourceId: cMKKeyVaultResourceId
    cMKKeyVersion: cMKKeyVersion
    cMKUserAssignedIdentityResourceId: cMKUserAssignedIdentityResourceId
    dataEndpointEnabled: dataEndpointEnabled
    diagnosticEventHubAuthorizationRuleId: diagnosticEventHubAuthorizationRuleId
    diagnosticEventHubName: diagnosticEventHubName
    diagnosticLogCategoriesToEnable: diagnosticLogCategoriesToEnable
    diagnosticLogsRetentionInDays: diagnosticLogsRetentionInDays
    diagnosticMetricsToEnable: diagnosticMetricsToEnable
    diagnosticSettingsName: diagnosticSettingsName
    diagnosticStorageAccountId: diagnosticStorageAccountId
    diagnosticWorkspaceId: diagnosticWorkspaceId
    exportPolicyStatus: exportPolicyStatus
    location: location
    lock: lock
    networkRuleBypassOptions: networkRuleBypassOptions
    networkRuleSetDefaultAction: networkRuleSetDefaultAction
    networkRuleSetIpRules: networkRuleSetIpRules
    privateEndpoints: privateEndpoints
    publicNetworkAccess: publicNetworkAccess
    quarantinePolicyStatus: quarantinePolicyStatus
    replications: replications
    retentionPolicyDays: retentionPolicyDays
    retentionPolicyStatus: retentionPolicyStatus
    roleAssignments: roleAssignments
    systemAssignedIdentity: systemAssignedIdentity
    tags: tags
    trustPolicyStatus: trustPolicyStatus
    userAssignedIdentities: userAssignedIdentities
    webhooks: webhooks
    zoneRedundancy: zoneRedundancy
  }
}

@description('The Name of the Azure container registry.')
output name string = registry.outputs.name

@description('The reference to the Azure container registry.')
output loginServer string = registry.outputs.loginServer

@description('The name of the Azure container registry.')
output resourceGroupName string = resourceGroup().name

@description('The resource ID of the Azure container registry.')
output resourceId string = registry.outputs.resourceId

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = registry.outputs.systemAssignedPrincipalId

@description('The location the resource was deployed into.')
output location string = registry.outputs.location
