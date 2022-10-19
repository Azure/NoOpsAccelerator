/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

/*
SUMMARY: Module Example to deploy an AKS Platform Hub/Spoke Landing Zone
DESCRIPTION: The following components will be options in this deployment
            * Hub Virtual Network (VNet)
              * Operations Artifacts (Optional)
              * Bastion Host (Optional)
              * Microsoft Defender for Cloud (Optional)
              * DDOS Standard (Optional)              
            * Spokes
              * Operations (Tier 1)
            * Logging
              * Azure Sentinel
              * Azure Log Analytics
            * Azure Firewall
            * Private DNS Zones - Details of all the Azure Private DNS zones can be found here --> [https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration)  
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
@description('Required. The values used with all resources.')
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
@description('Required. A set of key/value pairs of tags assigned to the subscription or resource.')
param parTags object

@description('Required. The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

// DEPLOYEMENT PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

@description('The current date - do not override the default value')
param dateUtcNow string = utcNow('yyyy-MM-dd HH:mm:ss')

// OPERATIONS NETWORK ARTIFACTS
// (JSON Parameter)
// -----------------------------
// "parNetworkArtifacts": {
//   "value": {
//     "enable": false,
//     "artifactsKeyVault": {
//       "keyVaultPolicies": {
//         "objectId": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx",
//         "permissions": {
//           "keys": [
//             "get",
//             "list",
//             "update"
//           ],
//           "secrets": [
//             "all"
//           ]
//         },
//         "tenantId": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx"
//       }
//     },
//     "storageAccountAccess": {
//        "enableRoleAssignmentForStorageAccount": false,
//              "principalIds": [
//                "7bc6bc45-b256-407c-9d79-bde13dfb5639"
//             ],
//              "roleDefinitionIdOrName": "Contributor"
//            }
//        }
//    }
// }
@description('Optional. Enables Operations Network Artifacts Resource Group with KV and Storage account for the ops subscriptions used in the deployment.')
param parNetworkArtifacts object

//DDOS PARAMETERS
// (JSON Parameter)
// ---------------------------
//"parDdosStandard": {
//      "value": {
//        "enable": false
//      }
//    }
@description('DDOS Standard configuration.  See readme.md for configuration settings.')
param parDdosStandard object

// HUB PARAMETERS
// (JSON Parameter)
// ---------------------------
//"parHub": {
//      "value": {
//        "subscriptionId": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx",
//        "virtualNetworkAddressPrefix": "10.0.100.0/24",
//        "subnetAddressPrefix": "10.0.100.128/27",
//        "virtualNetworkDiagnosticsLogs": [],
//        "virtualNetworkDiagnosticsMetrics": [],
//        "networkSecurityGroupRules": [],
//        "networkSecurityGroupDiagnosticsLogs":[
//          {
//            "category": "NetworkSecurityGroupEvent",
//            "enabled": true
//          },
//          {
//            "category": "NetworkSecurityGroupRuleCounter",
//            "enabled": true
//          }
//        ],
//        "subnetServiceEndpoints": [
//          {
//           "service": "Microsoft.Storage"
//         }
//        ],
//       "storageAccountAccess": {
//          "enableRoleAssignmentForStorageAccount": false,
//              "principalIds": [
//                "7bc6bc45-b256-407c-9d79-bde13dfb5639"
//             ],
//              "roleDefinitionIdOrName": "Contributor"
//            }
//        }
//      }
//    }
@description('Hub Virtual network configuration.  See azresources/hub-spoke-core/vdss/hub/readme.md')
param parHub object

// OPERATIONS SPOKE PARAMETERS
// (JSON Parameter)
// ---------------------------
//"parOperationsSpoke": {
//      "value": {
//        "subscriptionId": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx",
//        "virtualNetworkAddressPrefix": "10.0.115.0/26",
//        "subnetAddressPrefix": "10.0.115.0/27",
//        "sourceAddressPrefixes": [],
//        "virtualNetworkDiagnosticsLogs": [],
//        "virtualNetworkDiagnosticsMetrics": [],
//        "networkSecurityGroupRules": [],
//        "publicIPAddressDiagnosticsLogs": [
//          {
//            "category": "DDoSProtectionNotifications",
//            "enabled": true
//          },
//          {
//            "category": "DDoSMitigationFlowLogs",
//            "enabled": true
//          },
//          {
//            "category": "DDoSMitigationReports",
//            "enabled": true
//          }
//        ],
//        "networkSecurityGroupDiagnosticsLogs":[
//          {
//            "category": "NetworkSecurityGroupEvent",
//            "enabled": true
//          },
//          {
//            "category": "NetworkSecurityGroupRuleCounter",
//            "enabled": true
//          }
//        ],
//        "subnetServiceEndpoints": [
//          {
//            "service": "Microsoft.Storage"
//          }
//        ],
//       "storageAccountAccess": {
//          "enableRoleAssignmentForStorageAccount": false,
//              "principalIds": [
//                "7bc6bc45-b256-407c-9d79-bde13dfb5639"
//             ],
//              "roleDefinitionIdOrName": "Contributor"
//            }
//         }
//      }
//    }
@description('Operations Spoke Virtual network configuration.  See azresources/hub-spoke-core/vdms/operations/readme.md')
param parOperationsSpoke object

// FIREWALL PARAMETERS
// (JSON Parameter)
// ---------------------------
//"parAzureFirewall": {
//      "value": {
//       "enable": true,
//        "clientPublicIPAddressAvailabilityZones": [],
//        "managementPublicIPAddressAvailabilityZones": [],
//        "supernetIPAddress": "10.0.96.0/19",
//        "skuTier": "Premium",
//        "threatIntelMode": "Alert",
//        "intrusionDetectionMode": "Alert",
//        "publicIPAddressDiagnosticsLogs": [
//          {
//            "category": "DDoSProtectionNotifications",
//            "enabled": true
//          },
//          {
//            "category": "DDoSMitigationFlowLogs",
//            "enabled": true
//          },
//          {
//            "category": "DDoSMitigationReports",
//            "enabled": true
//          }
//        ],
//        "publicIPAddressDiagnosticsMetrics": [
//          {
//            "category": "AllMetrics",
//            "enabled": true
//          }
//        ],
//        "diagnosticsLogs": [
//          "AzureFirewallApplicationRule",
//          "AzureFirewallNetworkRule",
//          "AzureFirewallDnsProxy"
//        ],
//        "diagnosticsMetrics": [
//          "AllMetrics"
//        ],
//        "ruleCollectionGroups": []
//      }
//    }
@description('Required. Azure Firewall configuration. Azure Firewall is deployed in Forced Tunneling mode where a route table must be added as the next hop.')
param parAzureFirewall object

// LOGGING PARAMETERS
// (JSON Parameter)
// -----------------------------
// "parLogging": {
//   "value": {
//     "enableSentinel": "true",     When set to "true", enables Microsoft Sentinel within the Log Analytics Workspace
//     "logAnalyticsWorkspaceCappingDailyQuotaGb": -1,     The daily quota for Log Analytics Workspace logs in Gigabytes. The default is "-1" for no quota.
//     "logAnalyticsWorkspaceRetentionInDays": 30,     The number of days to retain Log Analytics Workspace logs. The default is "30"
//     "logAnalyticsWorkspaceSkuName": "PerGB2018",     [Free/Standard/Premium/PerNode/PerGB2018/Standalone] The SKU for the Log Analytics Workspace.
//     "logStorageSkuName": "Standard_GRS"      The Storage Account SKU to use for log storage. The default is "Standard_GRS".,
//     "storageAccountAccess": {
//        "enableRoleAssignmentForStorageAccount": false,
//              "principalIds": [
//                "7bc6bc45-b256-407c-9d79-bde13dfb5639"
//             ],
//              "roleDefinitionIdOrName": "Contributor"
//            }
//   }
// }
@description('Enables logging parmeters and Microsoft Sentinel within the Log Analytics Workspace created in this deployment. See azresources/hub-spoke-core/vdms/logging/readme.md')
param parLogging object

// Microsoft Defender for Cloud
// (JSON Parameter)
// -----------------------------
// "parSecurityCenter": {
//   "value": {
//       "enableDefender: true,
//       "emailSecurityContact": "anoa@microsoft.com",
//       "phoneSecurityContact": "5555555555"
//   }
// }
@description('Microsoft Defender for Cloud.  It includes email and phone.')
param parSecurityCenter object

// REMOTE ACCESS PARAMETERS

// Bastion Host (Remote Access)
// (JSON Parameter)
// -----------------------------
// "parRemoteAccess": {
//   "value": {
//     "enable": true,        
//     "bastion": {
//       "sku": "Standard",
//       "subnetAddressPrefix": "10.0.100.160/27",
//       "publicIPAddressAvailabilityZones": [],
//       "encryptionAtHost": false,
//       "linux": {
//         "enable": true,
//         "vmName": "bastion-linux",
//         "vmAdminUsername": "azureuser",
//         "disablePasswordAuthentication": false,
//         "vmAdminPasswordOrKey": "Rem0te@2020246",          
//         "vmSize": "Standard_DS1_v2",
//         "vmOsDiskCreateOption": "FromImage",
//         "vmOsDiskType": "Standard_LRS",
//         "vmImagePublisher": "Canonical",
//         "vmImageOffer": "UbuntuServer",
//         "vmImageSku": "18.04-LTS",
//         "vmImageVersion": "latest",
//         "networkInterfacePrivateIPAddressAllocationMethod": "Dynamic"
//       },
//       "windows": {
//         "enable": true,
//         "vmName": "bastion-windows",
//         "vmAdminUsername": "azureuser",
//         "vmAdminPassword": "Rem0te@2020246",
//         "vmSize": "Standard_DS1_v2",
//         "vmOsDiskCreateOption": "FromImage",
//         "vmStorageAccountType": "StandardSSD_LRS",
//         "vmImagePublisher": "MicrosoftWindowsServer",
//         "vmImageOffer": "WindowsServer",
//         "vmImageSku": "2019-datacenter",
//         "vmImageVersion": "latest",
//         "networkInterfacePrivateIPAddressAllocationMethod": "Dynamic"
//       },
//       "customScriptExtension": {
//         "install": false,
//         "script64": ""
//       }
//     }
//   }
// }
@description('When set to "true", provisions Azure Bastion Host with Jumpboxes, when specified. It defaults to "false".')
param parRemoteAccess object

// Telemetry - Azure customer usage attribution
// Reference:  https://docs.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution
var telemetry = json(loadTextContent('../../azresources/Modules/Global/telemetry.json'))
module telemetryCustomerUsageAttribution '../../azresources/Modules/Global/partnerUsageAttribution/customer-usage-attribution-subscription.bicep' = if (telemetry.customerUsageAttribution.enabled) {
  name: 'pid-${telemetry.customerUsageAttribution.modules.platforms.hubspoke1}'
  scope: subscription(parHub.subscriptionId)
}

/*
  NAMING CONVENTION
  Here we define a naming conventions for resources.
  First, we take `parRequired.orgPrefix`, `parLocation`, and `parRequired.deployEnvironment` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.
*/

var varResourceToken = 'resource_token'
var varNameToken = 'name_token'
var varNamingConvention = '${toLower(parRequired.orgPrefix)}-${toLower(parLocation)}-${toLower(parRequired.deployEnvironment)}-${varNameToken}-${toLower(varResourceToken)}'

// RESOURCE NAME CONVENTIONS WITH ABBREVIATIONS

var varResourceGroupNamingConvention = replace(varNamingConvention, varResourceToken, 'rg')

// HUB NAMES

var varHubName = 'hub'
var varHubResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varHubName)

// OPS NAMES

var operationsName = 'operations'
var varOperationsResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, operationsName)

// TAGS

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}

@description('Resource group tags')
module modTags '../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-hubspoke-tags--${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHub.subscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// LOGGING & LOG ANALYTICS WORKSPACE

module modLogAnalyticsWorkspace '../../azresources/hub-spoke-core/vdms/logging/anoa.lz.logging.bicep' = {
  name: 'deploy-laws-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parOperationsSpoke.subscriptionId)
  params: {
    // Required Parameters
    parOrgPrefix: parRequired.orgPrefix
    parLocation: parLocation
    parDeployEnvironment: parRequired.deployEnvironment
    parTags: modTags.outputs.tags

    // Enable Sentinel
    parDeploySentinel: parLogging.enableSentinel

    // Log Analytics Parameters
    parLogAnalyticsWorkspaceSkuName: parLogging.logAnalyticsWorkspaceSkuName
    parLogAnalyticsWorkspaceRetentionInDays: parLogging.logAnalyticsWorkspaceRetentionInDays
    parLogAnalyticsWorkspaceCappingDailyQuotaGb: parLogging.logAnalyticsWorkspaceCappingDailyQuotaGb

    // RBAC for Storage Parameters
    parLoggingStorageAccountAccess: parLogging.storageAccountAccess
  }
}

// ARTIFACTS

module modArtifacts '../../azresources/hub-spoke-core/vdss/networkArtifacts/anoa.lz.artifacts.bicep' = if (parNetworkArtifacts.enable) {
  name: 'deploy-hub-artifacts-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHub.subscriptionId)
  params: {
    // Required Parameters
    parOrgPrefix: parRequired.orgPrefix
    parLocation: parLocation
    parDeployEnvironment: parRequired.deployEnvironment
    parTags: modTags.outputs.tags

    // Artifact Key Vault Parameters
    parArtifactsKeyVaultPolicies: parNetworkArtifacts.artifactsKeyVault.keyVaultPolicies

    // RBAC for Storage Parameters
    parArtifactsStorageAccountAccess: parNetworkArtifacts.storageAccountAccess

    // Bastion Secrets Parameters
    parEnableBastionSecrets: parRemoteAccess.enable
    parLinuxVmAdminPasswordOrKey: parRemoteAccess.bastion.linux.vmAdminPasswordOrKey
    parWindowsVmAdminPassword: parRemoteAccess.bastion.windows.vmAdminPassword
  }
}

//POLICY

// HUB AND SPOKE NETWORKS

// HUB

module modHubNetwork '../../azresources/hub-spoke-core/vdss/hub/anoa.lz.hub.network.bicep' = {
  name: 'deploy-hub-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHub.subscriptionId)
  params: {
    // Required Parameters
    parOrgPrefix: parRequired.orgPrefix
    parLocation: parLocation
    parDeployEnvironment: parRequired.deployEnvironment
    parTags: modTags.outputs.tags

    // Enable DDOS Protection Plan
    parDeployddosProtectionPlan: parDdosStandard.enable

    // Hub Network Parameters
    parHubVirtualNetworkAddressPrefix: parHub.virtualNetworkAddressPrefix
    parHubSubnetAddressPrefix: parHub.subnetAddressPrefix
    parHubNetworkSecurityGroupDiagnosticsLogs: parHub.networkSecurityGroupDiagnosticsLogs
    parHubNetworkSecurityGroupRules: parHub.networkSecurityGroupRules
    parHubSubnetServiceEndpoints: parHub.subnetServiceEndpoints
    parHubVirtualNetworkDiagnosticsLogs: parHub.virtualNetworkDiagnosticsLogs
    parHubVirtualNetworkDiagnosticsMetrics: parHub.virtualNetworkDiagnosticsMetrics
    parHubSubnets: parHub.subnets

    // Enable Azure FireWall
    parAzureFirewallEnabled: parAzureFirewall.enable
    parDisableBgpRoutePropagation: false
 
    // Hub Firewall Parameters
    parFirewallSupernetIPAddress: parAzureFirewall.supernetIPAddress
    parFirewallSkuTier: parAzureFirewall.skuTier
    parFirewallThreatIntelMode: parAzureFirewall.threatIntelMode
    parFirewallIntrusionDetectionMode: parAzureFirewall.intrusionDetectionMode
    parFirewallClientPublicIPAddressAvailabilityZones: parAzureFirewall.clientPublicIPAddressAvailabilityZones
    parFirewallDiagnosticsLogs: parAzureFirewall.diagnosticsLogs
    parFirewallDiagnosticsMetrics: parAzureFirewall.diagnosticsMetrics
    parFirewallManagementPublicIPAddressAvailabilityZones: parAzureFirewall.managementPublicIPAddressAvailabilityZones
    parPublicIPAddressDiagnosticsLogs: parAzureFirewall.publicIPAddressDiagnosticsLogs
    parPublicIPAddressDiagnosticsMetrics: parAzureFirewall.publicIPAddressDiagnosticsMetrics

    // RBAC for Storage Parameters
    parHubStorageAccountAccess: parHub.storageAccountAccess

    // Log Analytics Parameters
    parLogAnalyticsWorkspaceResourceId: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceResourceId
    parLogAnalyticsWorkspaceName: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceName

  }
}

// TIER 1 - OPERATIONS

module modOperationsNetwork '../../azresources/hub-spoke-core/vdms/operations/anoa.lz.ops.network.bicep' = {
  name: 'deploy-vnet-spoke-ops-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parOperationsSpoke.subscriptionId)
  params: {
    // Required Parameters
    parOrgPrefix: parRequired.orgPrefix
    parLocation: parLocation
    parDeployEnvironment: parRequired.deployEnvironment
    parTags: modTags.outputs.tags

    // Operations Network Parameters
    parOperationsNetworkSecurityGroupDiagnosticsLogs: parOperationsSpoke.networkSecurityGroupDiagnosticsLogs
    parOperationsSubnetAddressPrefix: parOperationsSpoke.subnetAddressPrefix
    parOperationsNetworkSecurityGroupRules: parOperationsSpoke.networkSecurityGroupRules
    parOperationsSubnetServiceEndpoints: parOperationsSpoke.subnetServiceEndpoints
    parOperationsVirtualNetworkAddressPrefix: parOperationsSpoke.virtualNetworkAddressPrefix
    parOperationsVirtualNetworkDiagnosticsLogs: parOperationsSpoke.virtualNetworkDiagnosticsLogs
    parOperationsVirtualNetworkDiagnosticsMetrics: parOperationsSpoke.virtualNetworkDiagnosticsMetrics
    parFirewallPrivateIPAddress: modHubNetwork.outputs.firewallPrivateIPAddress
    parDisableBgpRoutePropagation: true

    // Log Storage Sku Parameters
    parLogStorageSkuName: parLogging.logStorageSkuName

    // RBAC for Storage Parameters
    parOperationsStorageAccountAccess: parOperationsSpoke.storageAccountAccess

    // Log Analytics Parameters
    parLogAnalyticsWorkspaceResourceId: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceResourceId
    parLogAnalyticsWorkspaceName: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceName
  }
}

// VIRTUAL NETWORK PEERINGS

module modHubVirtualNetworkPeerings '../../azresources/hub-spoke-core/peering/hub/anoa.lz.hub.network.peerings.bicep' = {
  name: 'deploy-vnet-peerings-hub-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parHub.subscriptionId, varHubResourceGroupName)
  params: {
    parHubVirtualNetworkName: modHubNetwork.outputs.virtualNetworkName
    parSpokes: [
      {
        name: 'operations'
        virtualNetworkName: modOperationsNetwork.outputs.virtualNetworkName
        virtualNetworkResourceId: modOperationsNetwork.outputs.virtualNetworkResourceId
      }
    ]
  }
}

module modSpokeOpsToHubVirtualNetworkPeerings '../../azresources/hub-spoke-core/peering/spoke/anoa.lz.spoke.network.peering.bicep' = {
  name: 'deploy-vnet-spoke-peerings-ops-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parOperationsSpoke.subscriptionId, varOperationsResourceGroupName)
  params: {
    parSpokeName: 'operations'
    parSpokeResourceGroupName: varOperationsResourceGroupName
    parSpokeVirtualNetworkName: modOperationsNetwork.outputs.virtualNetworkName

    // Hub Paramters
    parHubVirtualNetworkName: modHubNetwork.outputs.virtualNetworkName
    parHubVirtualNetworkResourceId: modHubNetwork.outputs.virtualNetworkResourceId
  }
}

// POLICY ASSIGNMENTS

// REMOTE ACCESS

module modRemoteAccess '../../overlays/management-services/bastion/deploy.bicep' = if (parRemoteAccess.enable) {
  name: 'deploy-remote-access-hub-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parHub.subscriptionId, varHubResourceGroupName)
  params: {
    // Required Parameters
    parRequired: parRequired
    parLocation: parLocation
    parTags: modTags.outputs.tags

    // Hub Virtual Network Parameters    
    parHubVirtualNetworkName: modHubNetwork.outputs.virtualNetworkName
    parHubSubnetResourceId: modHubNetwork.outputs.subnetResourceId
    parHubNetworkSecurityGroupResourceId: modHubNetwork.outputs.networkSecurityGroupResourceId

    // Bastion Host Parameters   
    parRemoteAccess: parRemoteAccess

    // Log Analytics Parameters
    parLogAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceResourceId
  }
}

module modVMExt '../../azresources/Modules/Microsoft.Compute/virtualmachines/extensions/az.com.virtual.machine.extensions.bicep' = if (parRemoteAccess.enable && parRemoteAccess.bastion.customScriptExtension.install) {
  name: 'deploy-vmext-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parHub.subscriptionId, varHubResourceGroupName)
  params: {
    location: parLocation
    type: 'CustomScript'
    name: 'Script Definition'
    publisher: 'Microsoft.Azure.Extensions'
    enableAutomaticUpgrade: true
    autoUpgradeMinorVersion: true
    typeHandlerVersion: '2.1'
    virtualMachineName: modRemoteAccess.outputs.linuxVMName
    protectedSettings: {
      script: parRemoteAccess.bastion.customScriptExtension.script64
    }
  }
}

// MICROSOFT DEFENDER FOR CLOUD FOR HUB

module modDefender '../../overlays/management-services/defender/deploy.bicep' = if (parSecurityCenter.enableDefender) {
  name: 'deploy-defender-hub-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHub.subscriptionId)
  params: {
    parLocation: parLocation
    parLogAnalyticsWorkspaceResourceId: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceResourceId
    parSecurityCenter: parSecurityCenter
  }
}

// MICROSOFT DEFENDER FOR CLOUD FOR SPOKES

module spokeOpsDefender '../../overlays/management-services/defender/deploy.bicep' = if (parSecurityCenter.enableDefender && parOperationsSpoke.subscriptionId != parHub.subscriptionId) {
  name: 'deploy-defender-ops-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parOperationsSpoke.subscriptionId)
  params: {
    parLocation: parLocation
    parLogAnalyticsWorkspaceResourceId: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceResourceId
    parSecurityCenter: parSecurityCenter
  }
}

// OUTPUTS

output deployEnvironment string = parRequired.deployEnvironment

output firewallPrivateIPAddress string = modHubNetwork.outputs.firewallPrivateIPAddress
output firewallPolicyName string = modHubNetwork.outputs.firewallPolicyName

output hub object = {
  subscriptionId: parHub.subscriptionId
  resourceGroupName: modHubNetwork.outputs.resourceGroupName
  resourceGroupResourceId: modHubNetwork.outputs.resourceGroupResourceId
  virtualNetworkName: modHubNetwork.outputs.virtualNetworkName
  virtualNetworkResourceId: modHubNetwork.outputs.virtualNetworkResourceId
  subnetName: modHubNetwork.outputs.subnetName
  subnetResourceId: modHubNetwork.outputs.subnetResourceId
  subnetAddressPrefix: modHubNetwork.outputs.subnetAddressPrefix
  networkSecurityGroupName: modHubNetwork.outputs.networkSecurityGroupName
  networkSecurityGroupResourceId: modHubNetwork.outputs.networkSecurityGroupResourceId
}

output logAnalyticsWorkspaceName string = modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceName

output logAnalyticsWorkspaceResourceId string = modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceId

output diagnosticStorageAccountName string = modOperationsNetwork.outputs.operationsLogStorageAccountName
