/* Copyright (c) Microsoft Corporation. Licensed under the MIT license. */
targetScope = 'subscription'

@description('Required. The full Azure ID of the workspace to save the data in.')
param workspaceId string

@description('Optional. Describes what kind of security agent provisioning action to take. - On or Off.')
@allowed([
  'On'
  'Off'
])
param autoProvision string = 'On'

@description('Optional. Device Security group data.')
param deviceSecurityGroupProperties object = {}

@description('Optional. Security Solution data.')
param ioTSecuritySolutionProperties object = {}

@description('Optional. The pricing tier value for VMs. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param virtualMachinesPricingTier string = 'Standard'

@description('Optional. The pricing tier value for SqlServers. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param sqlServersPricingTier string = 'Standard'

@description('Optional. The pricing tier value for AppServices. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param appServicesPricingTier string = 'Standard'

@description('Optional. The pricing tier value for StorageAccounts. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param storageAccountsPricingTier string = 'Standard'

@description('Optional. The pricing tier value for SqlServerVirtualMachines. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param sqlServerVirtualMachinesPricingTier string = 'Standard'

@description('Optional. The pricing tier value for KubernetesService. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param kubernetesServicePricingTier string = 'Standard'

@description('Optional. The pricing tier value for ContainerRegistry. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param containerRegistryPricingTier string = 'Standard'

@description('Optional. The pricing tier value for KeyVaults. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param keyVaultsPricingTier string = 'Standard'

@description('Optional. The pricing tier value for DNS. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param dnsPricingTier string = 'Standard'

@description('Optional. The pricing tier value for ARM. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param armPricingTier string = 'Standard'

@description('Optional. The pricing tier value for OpenSourceRelationalDatabases. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param openSourceRelationalDatabasesTier string = 'Standard'

@description('Optional. The pricing tier value for containers. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param containersTier string = 'Standard'

@description('Optional. The pricing tier value for CosmosDbs. Azure Security Center is provided in two pricing tiers: free and standard, with the standard tier available with a trial period. The standard tier offers advanced security capabilities, while the free tier offers basic security features. - Free or Standard.')
@allowed([
  'Free'
  'Standard'
])
param cosmosDbsTier string = 'Standard'

@description('Optional. Security contact data.')
param securityContactProperties object = {}

var pricings = (environment().name == 'AzureCloud') ? [
  {
    name: 'VirtualMachines'
    pricingTier: virtualMachinesPricingTier
  }
  {
    name: 'SqlServers'
    pricingTier: sqlServersPricingTier
  }
  {
    name: 'AppServices'
    pricingTier: appServicesPricingTier
  }
  {
    name: 'StorageAccounts'
    pricingTier: storageAccountsPricingTier
  }
  {
    name: 'SqlServerVirtualMachines'
    pricingTier: sqlServerVirtualMachinesPricingTier
  }
  {
    name: 'KubernetesService'
    pricingTier: kubernetesServicePricingTier
  }
  {
    name: 'ContainerRegistry'
    pricingTier: containerRegistryPricingTier
  }
  {
    name: 'KeyVaults'
    pricingTier: keyVaultsPricingTier
  }
  {
    name: 'Dns'
    pricingTier: dnsPricingTier
  }
  {
    name: 'Arm'
    pricingTier: armPricingTier
  }
  {
    name: 'OpenSourceRelationalDatabases'
    pricingTier: openSourceRelationalDatabasesTier
  }
  {
    name: 'Containers'
    pricingTier: containersTier
  }
  {
    name: 'CosmosDbs'
    pricingTier: cosmosDbsTier
  }
] : (environment().name == 'AzureUSGovernment') ? [
  {
    name: 'Arm'
    pricingTier: armPricingTier
  }
  {
    name: 'ContainerRegistry'
    pricingTier: containerRegistryPricingTier
  }
  {
    name: 'Containers'
    pricingTier: containersTier
  }
  {
    name: 'Dns'
    pricingTier: dnsPricingTier
  }
  {
    name: 'KubernetesService'
    pricingTier: kubernetesServicePricingTier
  }
  {
    name: 'OpenSourceRelationalDatabases'
    pricingTier: openSourceRelationalDatabasesTier
  }
  {
    name: 'StorageAccounts'
    pricingTier: storageAccountsPricingTier
  }
  {
    name: 'SqlServerVirtualMachines'
    pricingTier: sqlServerVirtualMachinesPricingTier
  }
  {
    name: 'VirtualMachines'
    pricingTier: virtualMachinesPricingTier
  }
  {
    name: 'SqlServers'
    pricingTier: sqlServersPricingTier
  }
] : []



resource pricingTiers 'Microsoft.Security/pricings@2018-06-01' = [for (pricing, index) in pricings: {
  name: pricing.name
  properties: {
    pricingTier: pricing.pricingTier
  }
}]

resource autoProvisioningSettings 'Microsoft.Security/autoProvisioningSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    autoProvision: autoProvision
  }
}

resource deviceSecurityGroups 'Microsoft.Security/deviceSecurityGroups@2019-08-01' = if (!empty(deviceSecurityGroupProperties)) {
  name: 'deviceSecurityGroups'
  properties: {
    thresholdRules: deviceSecurityGroupProperties.thresholdRules
    timeWindowRules: deviceSecurityGroupProperties.timeWindowRules
    allowlistRules: deviceSecurityGroupProperties.allowlistRules
    denylistRules: deviceSecurityGroupProperties.denylistRules
  }
}

module iotSecuritySolutions './includes/iotSecuritySolutions.bicep' = if (!empty(ioTSecuritySolutionProperties)) {
  name: '${uniqueString(deployment().name)}-ASC-IotSecuritySolutions'
  scope: resourceGroup(empty(ioTSecuritySolutionProperties) ? 'dummy' : ioTSecuritySolutionProperties.resourceGroup)
  params: {
    ioTSecuritySolutionProperties: ioTSecuritySolutionProperties
  }
}

resource securityContacts 'Microsoft.Security/securityContacts@2017-08-01-preview' = if (!empty(securityContactProperties)) {
  name: 'securityContacts'
  properties: {
    email: securityContactProperties.email
    phone: securityContactProperties.phone
    alertNotifications: securityContactProperties.alertNotifications
    alertsToAdmins: securityContactProperties.alertsToAdmins
  }
}

resource workspaceSettings 'Microsoft.Security/workspaceSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    workspaceId: workspaceId
    scope: subscription().id
  }
  dependsOn: [
    autoProvisioningSettings
  ]
}

@description('The resource ID of the used log analytics workspace.')
output workspaceId string = workspaceId

@description('The name of the security center.')
output name string = 'Security'
