// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

targetScope = 'subscription'

@description('Location for the deployment.')
param parLocation string = deployment().location

param parDeploymentScriptIdentityId string
param parDeploymentScriptResourceGroupName string

param parSubscriptionId string = subscription().subscriptionId

param parFirewallEnabled bool = true
param parFirewallEnableStorage bool = false
param parFirewallStoragePrincipalId string = ''

param parHubEnableStorage bool = false
param parHubStoragePrincipalId string = ''
param parHubEnablePrivateDnsZones bool = false

param parOpsEnableStorage bool = false
param parOpsStoragePrincipalId string = ''

param parSentinelEnabled bool = false
param parLoggingEnableStorage bool = false
param parLoggingStoragePrincipalId string = ''

param parNetworkArtifactsEnabled bool = false
param parNetworkArtifactsObjectId string = ''
param parNetworkArtifactsTenantId string = ''
param parNetworkArtifactsEnableStorage bool = false
param parNetworkArtifactsStoragePrincipalId string = ''

param parEnableRemoteAccess bool = false
param parEnableRemoteAccessLinux bool = false
param parEnableRemoteAccessWindows bool = false

param parEnableDefender bool = false
param parEnableResourceLocks bool = false

param parTestRunnerCleanupAfterDeployment bool = true
param parTestRunnerId string = 'hub1spoke${uniqueString(utcNow())}'

var rgHub = 'anoa-${parLocation}-testrunner-hub-rg' // Resource group for hub resources
var rgOps = 'anoa-${parLocation}-testrunner-operations-rg' // Resource group for operations resources
var rgLogging = 'anoa-${parLocation}-testrunner-logging-rg' // Resource group for spoke resources
//var rgNetworkArtifacts = 'anoa-${parLocation}-testrunner-networkartifacts-rg' // Resource group for network artifacts resources
var rgPdz = 'anoa-${parLocation}-testrunner-hub-pdz-rg' // Resource group for private DNS zones resources

var parTagProjectName = '${parTestRunnerId}ProjectName'

module test '../../../../platforms/lz-platform-scca-hub-1spoke/deploy.bicep' = {
  name: 'execute-test-${parTestRunnerId}'
  scope: subscription()
  params: {
    parLocation: parLocation
    parRequired: {
      orgPrefix: 'anoa'
      deployEnvironment: 'testrunner'
    }

    parTags: {
      projectName: parTagProjectName
    }

    parSecurityCenter: {
      enableDefender: parEnableDefender
      alertNotifications: 'Off'
      alertsToAdminsNotifications: 'Off'
      emailSecurityContact: 'anoa@microsoft.com'
      phoneSecurityContact: '5555555555'
    }

    parDdosStandard: {
      enable: false
    }

    parNetworkArtifacts: {
      enable: parNetworkArtifactsEnabled
      enableResourceLocks: parEnableResourceLocks
      artifactsKeyVault: {
        keyVaultPolicies: {
          objectId: parNetworkArtifactsObjectId
          permissions: {
            keys: [
              'get'
              'list'
              'update'
            ]
            secrets: [
              'all'
            ]
          }
          tenantId: parNetworkArtifactsTenantId
        }
      }
      storageAccountAccess: {
        enableRoleAssignmentForStorageAccount: parNetworkArtifactsEnableStorage
        principalIds: [
          parNetworkArtifactsStoragePrincipalId
        ]
        roleDefinitionIdOrName: 'Contributor'
      }
    }

    parLogging: {
      enableSentinel: parSentinelEnabled
      logAnalyticsWorkspaceCappingDailyQuotaGb: -1
      logAnalyticsWorkspaceRetentionInDays: 30
      logAnalyticsWorkspaceSkuName: 'PerGB2018'
      logStorageSkuName: 'Standard_GRS'
      enableResourceLocks: parEnableResourceLocks
      storageAccountAccess: {
        enableRoleAssignmentForStorageAccount: parLoggingEnableStorage
        principalIds: [
          parLoggingStoragePrincipalId
        ]
        roleDefinitionIdOrName: 'Contributor'
      }
    }

    parHub: {
      subscriptionId: parSubscriptionId
      virtualNetworkAddressPrefix: '10.0.100.0/24'
      subnetAddressPrefix: '10.0.100.128/27'
      peerToSpokeVirtualNetwork: true
      enablePrivateDnsZones: parHubEnablePrivateDnsZones
      enableResourceLocks: parEnableResourceLocks
      subnets: [
        {
          name: 'AzureFirewallSubnet'
          addressPrefix: '10.0.100.0/26'
          serviceEndpoints: []
        }
        {
          name: 'AzureFirewallManagementSubnet'
          addressPrefix: '10.0.100.64/26'
          serviceEndpoints: []
        }
      ]
      virtualNetworkDiagnosticsLogs: []
      virtualNetworkDiagnosticsMetrics: []
      networkSecurityGroupRules: []
      networkSecurityGroupDiagnosticsLogs: [
        'NetworkSecurityGroupEvent'
        'NetworkSecurityGroupRuleCounter'
      ]
      subnetServiceEndpoints: [
        {
          service: 'Microsoft.Storage'
        }
      ]
      storageAccountAccess: {
        enableRoleAssignmentForStorageAccount: parHubEnableStorage
        principalIds: [
          parHubStoragePrincipalId
        ]
        roleDefinitionIdOrName: 'Contributor'
      }
    }

    parOperationsSpoke: {
      subscriptionId: parSubscriptionId
      virtualNetworkAddressPrefix: '10.0.115.0/26'
      subnetAddressPrefix: '10.0.115.0/27'
      peerToHubVirtualNetwork: true
      useRemoteGateway: false
      allowVirtualNetworkAccess: true
      enableResourceLocks: parEnableResourceLocks
      virtualNetworkDiagnosticsLogs: []
      virtualNetworkDiagnosticsMetrics: []
      networkSecurityGroupRules: []
      publicIPAddressDiagnosticsLogs: [
        'DDoSProtectionNotifications'
        'DDoSMitigationFlowLogs'
        'DDoSMitigationReports'
      ]
      networkSecurityGroupDiagnosticsLogs: [
        'NetworkSecurityGroupEvent'
        'NetworkSecurityGroupRuleCounter'
      ]
      subnetServiceEndpoints: [
        {
          service: 'Microsoft.Storage'
        }
      ]
      storageAccountAccess: {
        enableRoleAssignmentForStorageAccount: parOpsEnableStorage
        principalIds: [
          parOpsStoragePrincipalId
        ]
        roleDefinitionIdOrName: 'Contributor'
      }
    }

    parAzureFirewall: {
      enable: parFirewallEnabled
      disableBgpRoutePropagation: false
      clientPublicIPAddressAvailabilityZones: []
      managementPublicIPAddressAvailabilityZones: []
      supernetIPAddress: '10.0.96.0/19'
      skuTier: 'Premium'
      threatIntelMode: 'Alert'
      intrusionDetectionMode: 'Alert'
      publicIPAddressDiagnosticsLogs: [
        'DDoSProtectionNotifications'
        'DDoSMitigationFlowLogs'
        'DDoSMitigationReports'
      ]
      publicIPAddressDiagnosticsMetrics: [
        'AllMetrics'
      ]
      diagnosticsLogs: [
        'AzureFirewallApplicationRule'
        'AzureFirewallNetworkRule'
        'AzureFirewallDnsProxy'
      ]
      diagnosticsMetrics: [
        'AllMetrics'
      ]
      storageAccountAccess: {
        enableRoleAssignmentForStorageAccount: parFirewallEnableStorage
        principalIds: [
          parFirewallStoragePrincipalId
        ]
        roleDefinitionIdOrName: 'Contributor'
      }
    }

    parRemoteAccess: {
      enable: parEnableRemoteAccess
      bastion: {
        sku: 'Standard'
        subnetAddressPrefix: '10.0.100.160/26'
        publicIPAddressAvailabilityZones: []
        encryptionAtHost: false
        linux: {
          enable: parEnableRemoteAccessLinux
          vmName: 'bastion-linux'
          vmAdminUsername: 'azureuser'
          disablePasswordAuthentication: false
          vmAdminPasswordOrKey: 'Rem0te@2020246'
          vmSize: 'Standard_DS1_v2'
          vmOsDiskCreateOption: 'FromImage'
          vmOsDiskType: 'Standard_LRS'
          vmImagePublisher: 'Canonical'
          vmImageOffer: 'UbuntuServer'
          vmImageSku: '18.04-LTS'
          vmImageVersion: 'latest'
          networkInterfacePrivateIPAddressAllocationMethod: 'Dynamic'
        }
        windows: {
          enable: parEnableRemoteAccessWindows
          vmName: 'bastion-windows'
          vmAdminUsername: 'azureuser'
          vmAdminPassword: 'Rem0te@2020246'
          vmSize: 'Standard_DS1_v2'
          vmOsDiskCreateOption: 'FromImage'
          vmStorageAccountType: 'StandardSSD_LRS'
          vmImagePublisher: 'MicrosoftWindowsServer'
          vmImageOffer: 'WindowsServer'
          vmImageSku: '2019-datacenter'
          vmImageVersion: 'latest'
          networkInterfacePrivateIPAddressAllocationMethod: 'Dynamic'
        }
        customScriptExtension: {
          install: false
          script64: ''
        }
      }
    }
  }
}

/*
  Clean up script will:
    - Delete the private endpoints in the Storage resource group
    - Delete all resource groups created by the platform

var cleanUpScript = '''
  az account set -s {0}
  az network private-endpoint list -g {6} --query "[].id" -o json | jq -r '. | join(" ")' | xargs -t az network private-endpoint delete --ids 
  az group delete --name NetworkWatcherRG --yes --no-wait
  
'''
*/
module testCleanup '../../../../azresources/Modules/Microsoft.Resources/deploymentScripts/az.resources.deployment.scripts.bicep' = if (parTestRunnerCleanupAfterDeployment) {
  dependsOn: [
    test
  ]

  scope: resourceGroup(parDeploymentScriptResourceGroupName)
  name: 'execute-cleanup-test-${parTestRunnerId}'
  params: {
    location: parLocation
    timeout: 'PT6H'
    name: 'cleanup-test-${parTestRunnerId}'
    primaryScriptUri: 'https://raw.githubusercontent.com/Azure/Enterprise-Scale/main/azopsreference/azopsreference/scripts/cleanup.sh'
    userAssignedIdentities: {
      '${parDeploymentScriptIdentityId}': {}
    }
  }
}
