/*
SUMMARY: Module to deploy a Bastion Host with Windows/Linux Jump Boxes to the Hub Network
DESCRIPTION: The following components will be options in this deployment
              Bastion Host
              Windows VM
              Lunix VM
AUTHOR/S: jspinella

*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

targetScope = 'subscription'

// REQUIRED PARAMETERS

@description('Prefix value which will be prepended to all resource names. Default: anoa')
param parOrgPrefix string = 'anoa'

@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param parHubSubscriptionId string = subscription().subscriptionId

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

@description('Tags')
param parTags object

@minLength(3)
@maxLength(15)
@description('A suffix, 3 to 15 characters in length, to append to resource names (e.g. "dev", "test", "prod", "platforms"). It defaults to "platforms".')
param parDeployEnvironment string = 'platforms'

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

@description('When deploying a Bastion host, this switch will add bastion secrets to the key vault.')
#disable-next-line secure-secrets-in-params
param parEnableBastionSecrets bool = false

// ARTIFACTS PARAMETERS
@description('The Artifacts Key Vault Access Policies')
param parArtifactsKeyVaultPolicies object

// LOGGING PARAMETERS

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param parLogStorageSkuName string = 'Standard_GRS'

// STORAGE ACCOUNTS RBAC
@description('Account for access to Storage')
param parArtifactsStorageAccountAccess object

// RESOURCE LOCKS
@description('Switch which allows enable resource locks on all resources. Default: true')
param parEnableResourceLocks bool = true

// VM KEYS
@secure()
param parLinuxVmAdminPasswordOrKey string

@secure()
@minLength(12)
param parWindowsVmAdminPassword string

/*
  NAMING CONVENTION
  Here we define a naming conventions for resources.
  First, we take `parDeployEnvironment` and `parDeployEnvironment` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.
*/

var varResourceToken = 'resource_token'
var varNameToken = 'name_token'
var varNamingConvention = '${toLower(parOrgPrefix)}-${toLower(parLocation)}-${toLower(parDeployEnvironment)}-${varNameToken}-${toLower(varResourceToken)}'

// RESOURCE NAME CONVENTIONS WITH ABBREVIATIONS

var varResourceGroupNamingConvention = replace(varNamingConvention, varResourceToken, 'rg')
var varStorageAccountNamingConvention = toLower('${parOrgPrefix}st${varNameToken}unique_storage_token')
var varKeyVaultNamingConvention = toLower('${parOrgPrefix}kv${varNameToken}unique_kv_token')

// PREREQ NAMES
var varPreReqName = 'artifacts'
var varPreReqShortName = 'afts'
var varPreReqResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varPreReqName)

// PREREQ NAMES - STORAGE ACCOUNT
var varPreReqLogStorageAccountShortName = replace(varStorageAccountNamingConvention, varNameToken, varPreReqShortName)
var varPreReqLogStorageAccountUniqueName = replace(varPreReqLogStorageAccountShortName, 'unique_storage_token', uniqueString(parOrgPrefix, parLocation, parDeployEnvironment, parHubSubscriptionId))
var varPreReqLogStorageAccountName = take(varPreReqLogStorageAccountUniqueName, 23)

// PREREQ NAMES - KEY VAULT
var varPreReqKeyVaultShortName = replace(varKeyVaultNamingConvention, varNameToken, varPreReqShortName)
var varPreReqKeyVaultUniqueName = replace(varPreReqKeyVaultShortName, 'unique_kv_token', uniqueString(parOrgPrefix, parLocation, parDeployEnvironment, parHubSubscriptionId))
var varPreReqKeyVaultName = take(varPreReqKeyVaultUniqueName, 23)

// TAGS

@description('Resource group tags')
module modTags '../../../Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: '${varPreReqShortName}-tags-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHubSubscriptionId)
  params: {
    onlyUpdate: true
    tags: parTags
  }
}

// RESOURCE GROUPS

module modAftsResourceGroup '../../../Modules/Microsoft.Resources/resourceGroups/az.resource.groups.bicep' = {
  name: 'deploy-rg-${varPreReqShortName}-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHubSubscriptionId)
  params: {
    name: varPreReqResourceGroupName
    location: parLocation
    tags: modTags.outputs.tags
  }
}

// PREQREQS - VDMS

@description('Logging Storage Account')
module modAftsStorageAccount '../../../Modules/Microsoft.Storage/storageAccounts/az.data.storage.bicep' = {
  name: 'deploy-${varPreReqShortName}-Storage-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parHubSubscriptionId, varPreReqResourceGroupName)
  params: {
    name: varPreReqLogStorageAccountName
    location: parLocation
    storageAccountSku: parLogStorageSkuName
    tags: modTags.outputs.tags
    roleAssignments: (parArtifactsStorageAccountAccess.enableRoleAssignmentForStorageAccount) ? [
      {
        principalIds: parArtifactsStorageAccountAccess.principalIds  
        roleDefinitionIdOrName: parArtifactsStorageAccountAccess.roleDefinitionIdOrName
      }
    ] : []
    lock: parEnableResourceLocks ? 'CanNotDelete' : '' 
  }
  dependsOn: [
    modAftsResourceGroup
  ]
}

module modAftsKeyVault '../../../Modules/Microsoft.KeyVault/vaults/az.sec.key.vault.bicep' = {
  name: 'deploy-${varPreReqShortName}-KV-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parHubSubscriptionId, varPreReqResourceGroupName)
  params: {
    name: varPreReqKeyVaultName
    location: parLocation
    tags: modTags.outputs.tags
    accessPolicies: [
      {
        objectId: parArtifactsKeyVaultPolicies.objectId
        permissions: {
          keys: parArtifactsKeyVaultPolicies.permissions.keys
          secrets: parArtifactsKeyVaultPolicies.permissions.secrets
        }
        tenantId: parArtifactsKeyVaultPolicies.tenantId
      }
    ]
    secrets: (parEnableBastionSecrets) ? {
      secureList: [
        {
          attributesExp: 1702648632
          attributesNbf: 10000
          contentType: 'Microsoft.Compute/virtualMachines'
          name: 'LinuxVmAdminPasswordOrKey'
          value: parLinuxVmAdminPasswordOrKey
        }
        {
          attributesExp: 1702648632
          attributesNbf: 10000
          contentType: 'Microsoft.Compute/virtualMachines'
          name: 'WindowsVmAdminPassword'
          value: parWindowsVmAdminPassword
        }
      ]
      softDeleteRetentionInDays: 7
    } : {}
    enableVaultForDeployment: true
    enableVaultForDiskEncryption: true
    enableVaultForTemplateDeployment: true
    lock: parEnableResourceLocks ? 'CanNotDelete' : '' 
  }
  dependsOn: [
    modAftsResourceGroup
  ]
}

output prereqStorageResourceId string = modAftsStorageAccount.outputs.resourceId
output prereqKeyVaultResourceId string = modAftsKeyVault.outputs.resourceId
