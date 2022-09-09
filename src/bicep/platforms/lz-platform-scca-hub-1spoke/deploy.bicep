/*
SUMMARY: Module Example to deploy an AKS Platform Hub/Spoke Landing Zone
DESCRIPTION: The following components will be options in this deployment
            * Hub Virtual Network (VNet)
              * Operations Artifacts (Optional)
              * Bastion Host (Optional)
              * Microsoft Defender for Cloud (Optional)              
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

/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

/*
  PARAMETERS
  Here are all the parameters a user can override.
  These are the required parameters that Network does not provide a default for:    
    - parDeployEnvironment
*/

targetScope = 'managementGroup' //Deploying at Subscription scope to allow resource groups to be created and resources in one deployment

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

// SUBSCRIPTIONS PARAMETERS

@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param parHubSubscriptionId string

@description('The subscription ID for the Operations Network and resources. It defaults to the deployment subscription.')
param parOperationsSubscriptionId string

// OPERATIONS NETWORK ARTIFACTS
// Example (JSON)
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
//     }
//   }
// }
@description('Enables Operations Network Artifacts Resource Group with KV and Storage account for the ops subscriptions used in the deployment.')
param parNetworkArtifacts object

//DDOS PARAMETERS

@description('Enables DDOS deployment on the Hub Network.')
param parDdosStandard object


// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

@description('The current date - do not override the default value')
param dateUtcNow string = utcNow('yyyy-MM-dd HH:mm:ss')

// NETWORK ADDRESS SPACE PARAMETERS

@description('The CIDR Virtual Network Address Prefix for the Hub Virtual Network.')
param parHubVirtualNetworkAddressPrefix string = '10.0.100.0/24'

@description('The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.')
param parHubSubnetAddressPrefix string = '10.0.100.128/27'

@description('The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.')
param parFirewallClientSubnetAddressPrefix string = '10.0.100.0/26'

@description('The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.')
param parFirewallManagementSubnetAddressPrefix string = '10.0.100.64/26'

@description('The CIDR Virtual Network Address Prefix for the Operations Virtual Network.')
param parOperationsVirtualNetworkAddressPrefix string = '10.0.115.0/26'

@description('The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.')
param parOperationsSubnetAddressPrefix string = '10.0.115.0/27'

// FIREWALL PARAMETERS

@description('Switch which allows Azure Firewall deployment to be disabled. Default: true')
param parAzureFirewallEnabled bool = true

@description('Azure Firewall Tier associated with the Firewall to deploy. Default: Standard ')
@allowed([
  'Standard'
  'Premium'
])
param parFirewallSkuTier string

@description('Supernet CIDR address for the entire network of vnets, this address allows for communication between spokes. Recommended to use a Supernet calculator if modifying vnet addresses')
param parFirewallSupernetIPAddress string = '10.0.96.0/19'

@allowed([
  'Alert'
  'Deny'
  'Off'
])
param parFirewallThreatIntelMode string

@allowed([
  'Alert'
  'Deny'
  'Off'
])
@description('[Alert/Deny/Off] The Azure Firewall Intrusion Detection mode. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".')
param parFirewallIntrusionDetectionMode string = 'Alert'

@description('An array of Firewall Diagnostic Logs categories to collect. See "https://docs.microsoft.com/en-us/azure/firewall/firewall-diagnostics#enable-diagnostic-logging-through-the-azure-portal" for valid values.')
param parFirewallDiagnosticsLogs array = [
  'AzureFirewallApplicationRule'
  'AzureFirewallNetworkRule'
  'AzureFirewallDnsProxy'
]

@description('An array of Firewall Diagnostic Metrics categories to collect. See "https://docs.microsoft.com/en-us/azure/firewall/firewall-diagnostics#enable-diagnostic-logging-through-the-azure-portal" for valid values.')
param parFirewallDiagnosticsMetrics array = [
  'AllMetrics'   
]

@description('Subnet name for the Firewall Default is "AzureFirewallSubnet"')
param parFirewallClientSubnetName string = 'AzureFirewallSubnet'

@description('An array of Service Endpoints to enable for the Azure Firewall Client Subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param parFirewallClientSubnetServiceEndpoints array = []

@description('An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.')
param parFirewallClientPublicIPAddressAvailabilityZones array = []

@description('Subnet name for the Firewall Default is "AzureFirewallManagementSubnet"')
param parFirewallManagementSubnetName string = 'AzureFirewallManagementSubnet'

@description('An array of Service Endpoints to enable for the Azure Firewall Management Subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param parFirewallManagementSubnetServiceEndpoints array = []

@description('An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku for valid settings.')
param parFirewallManagementPublicIPAddressAvailabilityZones array = []

@description('An array of Azure Firewall Application Policy Rules.')
param parApplicationRuleCollections array = []

@description('An array of Azure Firewall Policy Rules.')
param parNetworkRuleCollections array = []

@description('An array of Public IP Address Diagnostic Logs for the Azure Firewall. See https://docs.microsoft.com/en-us/azure/ddos-protection/diagnostic-logging?tabs=DDoSProtectionNotifications#configure-ddos-diagnostic-logs for valid settings.')
param parPublicIPAddressDiagnosticsLogs array = [
  'DDoSProtectionNotifications'
  'DDoSMitigationFlowLogs'
  'DDoSMitigationReports'
]

@description('An array of Public IP Address Diagnostic Metrics for the Azure Firewall. See https://docs.microsoft.com/en-us/azure/ddos-protection/diagnostic-logging?tabs=DDoSProtectionNotifications for valid settings.')
param parPublicIPAddressDiagnosticsMetrics array = [
  'AllMetrics'
]

// HUB NETWORK PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param parHubVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param parHubVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group Rules to apply to the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param parHubNetworkSecurityGroupRules array = []

@description('An array of Network Security Group diagnostic logs to apply to the Hub Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param parHubNetworkSecurityGroupDiagnosticsLogs array = [
  'NetworkSecurityGroupEvent'
  'NetworkSecurityGroupRuleCounter'
]

@description('An array of Service Endpoints to enable for the Hub subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param parHubSubnetServiceEndpoints array = [
  {
    service: 'Microsoft.Storage'
  }
]

// OPERATIONS NETWORK PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param parOperationsVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param parOperationsVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group rules to apply to the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param parOperationsNetworkSecurityGroupRules array = []

@description('Array of Subnet Address Prefix for the default Operations network. These will be Spoke Subnet Address Prefixes, if exists.')
param parOperationsSourceAddressPrefixes array = []

@description('An array of Network Security Group diagnostic logs to apply to the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param parOperationsNetworkSecurityGroupDiagnosticsLogs array = [
  'NetworkSecurityGroupEvent'
  'NetworkSecurityGroupRuleCounter'
]

@description('An array of Service Endpoints to enable for the Operations subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param parOperationsSubnetServiceEndpoints array = [
  {
    service: 'Microsoft.Storage'
  }
]

// LOGGING PARAMETERS
// Logging
// Example (JSON)
// -----------------------------
// "parLogging": {
//   "value": {
//     "enableSentinel": "true",     When set to "true", enables Microsoft Sentinel within the Log Analytics Workspace
//     "logAnalyticsWorkspaceCappingDailyQuotaGb": -1,     The daily quota for Log Analytics Workspace logs in Gigabytes. The default is "-1" for no quota.
//     "logAnalyticsWorkspaceRetentionInDays": 30,     The number of days to retain Log Analytics Workspace logs. The default is "30"
//     "logAnalyticsWorkspaceSkuName": "PerGB2018",     [Free/Standard/Premium/PerNode/PerGB2018/Standalone] The SKU for the Log Analytics Workspace.
//     "logStorageSkuName": "Standard_GRS"      The Storage Account SKU to use for log storage. The default is "Standard_GRS".
//   }
// }
@description('Enables logging parmeters and Microsoft Sentinel within the Log Analytics Workspace created in this deployment.')
param parLogging object

// STORAGE ACCOUNTS RBAC

// Storage Account RBAC
// Example (JSON)
// -----------------------------
// "parStorageAccountAccess": {
//   "value": {
//     "enableRoleAssignmentForStorageAccount": true,
//     "principalIds": [
//       "xxxxxx-xxxxx-xxxxx-xxxx-xxxxxxx"
//     ],
//     "roleDefinitionIdOrName": "Group"
//   }
// },  
@description('Account for access to Storage')
param parStorageAccountAccess object

// MICROSOFT DEFENDER PARAMETERS

// Microsoft Defender for Cloud
// Example (JSON)
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
// Example (JSON)
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
@description('When set to "true", provisions Azure Bastion Host. It defaults to "false".')
param parRemoteAccess object

// Telemetry - Azure customer usage attribution
// Reference:  https://docs.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution
var telemetry = json(loadTextContent('../../azresources/Modules/Global/telemetry.json'))
module telemetryCustomerUsageAttribution '../../azresources/Modules/Global/partnerUsageAttribution/customer-usage-attribution-subscription.bicep' = if (telemetry.customerUsageAttribution.enabled) {
  name: 'pid-${telemetry.customerUsageAttribution.modules.platforms.hubspoke1}-${uniqueString(parLocation)}'
  scope: subscription(parHubSubscriptionId)
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
  scope: subscription(parHubSubscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// LOGGING & LOG ANALYTICS WORKSPACE

module modLogAnalyticsWorkspace '../../azresources/hub-spoke/vdms/logging/anoa.lz.logging.bicep' = {
  name: 'deploy-laws-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parOperationsSubscriptionId)
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
    parStorageAccountAccess: parStorageAccountAccess
  }
}

// ARTIFACTS

module modArtifacts '../../azresources/hub-spoke/vdss/networkArtifacts/anoa.lz.artifacts.bicep' = if (parNetworkArtifacts.enable) {
  name: 'deploy-hub-artifacts-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHubSubscriptionId)
  params: {
    // Required Parameters
    parOrgPrefix: parRequired.orgPrefix
    parLocation: parLocation
    parDeployEnvironment: parRequired.deployEnvironment
    parTags: modTags.outputs.tags

    // Artifact Key Vault Parameters
    parArtifactsKeyVaultPolicies: parNetworkArtifacts.artifactsKeyVault.keyVaultPolicies

    // RBAC for Storage Parameters
    parStorageAccountAccess: parStorageAccountAccess

    // Bastion Secrets Parameters
    parEnableBastionSecrets: parRemoteAccess.enable
    parLinuxVmAdminPasswordOrKey: parRemoteAccess.bastion.linux.vmAdminPasswordOrKey
    parWindowsVmAdminPassword: parRemoteAccess.bastion.windows.vmAdminPassword
  }
}

//POLICY


// HUB AND SPOKE NETWORKS

// HUB

module modHubNetwork '../../azresources/hub-spoke/vdss/hub/anoa.lz.hub.network.bicep' = {
  name: 'deploy-hub-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHubSubscriptionId)
  params: {
    // Required Parameters
    parOrgPrefix: parRequired.orgPrefix
    parLocation: parLocation
    parDeployEnvironment: parRequired.deployEnvironment
    parTags: modTags.outputs.tags
    
    // Enable DDOS Protection Plan
    parDeployddosProtectionPlan: parDdosStandard.enable

    // Hub Network Parameters
    parHubVirtualNetworkAddressPrefix: parHubVirtualNetworkAddressPrefix
    parHubSubnetAddressPrefix: parHubSubnetAddressPrefix
    parHubNetworkSecurityGroupDiagnosticsLogs: parHubNetworkSecurityGroupDiagnosticsLogs
    parHubNetworkSecurityGroupRules: parHubNetworkSecurityGroupRules
    parHubSubnetServiceEndpoints: parHubSubnetServiceEndpoints
    parHubVirtualNetworkDiagnosticsLogs: parHubVirtualNetworkDiagnosticsLogs
    parHubVirtualNetworkDiagnosticsMetrics: parHubVirtualNetworkDiagnosticsMetrics
    parPublicIPAddressDiagnosticsLogs: parPublicIPAddressDiagnosticsLogs
    parPublicIPAddressDiagnosticsMetrics: parPublicIPAddressDiagnosticsMetrics

    // Enable Azure FireWall
    parAzureFirewallEnabled: parAzureFirewallEnabled
    parFirewallClientSubnetAddressPrefix: parFirewallClientSubnetAddressPrefix
    parFirewallManagementSubnetAddressPrefix: parFirewallManagementSubnetAddressPrefix
    parDisableBgpRoutePropagation: false

    // Hub Firewall Parameters
    parFirewallSupernetIPAddress: parFirewallSupernetIPAddress
    parFirewallSkuTier: parFirewallSkuTier
    parFirewallThreatIntelMode: parFirewallThreatIntelMode
    parFirewallIntrusionDetectionMode: parFirewallIntrusionDetectionMode
    parFirewallClientPublicIPAddressAvailabilityZones: parFirewallClientPublicIPAddressAvailabilityZones
    parFirewallClientSubnetName: parFirewallClientSubnetName
    parFirewallClientSubnetServiceEndpoints: parFirewallClientSubnetServiceEndpoints
    parFirewallDiagnosticsLogs: parFirewallDiagnosticsLogs
    parFirewallDiagnosticsMetrics: parFirewallDiagnosticsMetrics
    parFirewallManagementPublicIPAddressAvailabilityZones: parFirewallManagementPublicIPAddressAvailabilityZones
    parFirewallManagementSubnetName: parFirewallManagementSubnetName
    parFirewallManagementSubnetServiceEndpoints: parFirewallManagementSubnetServiceEndpoints
    parApplicationRuleCollections: parApplicationRuleCollections
    parNetworkRuleCollections: parNetworkRuleCollections

    // RBAC for Storage Parameters
    parStorageAccountAccess: parStorageAccountAccess

    // Log Analytics Parameters
    parLogAnalyticsWorkspaceResourceId: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceResourceId
    parLogAnalyticsWorkspaceName: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceName

  }
}

// TIER 1 - OPERATIONS

module modOperationsNetwork '../../azresources/hub-spoke/vdms/operations/anoa.lz.ops.network.bicep' = {
  name: 'deploy-vnet-spoke-ops-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parOperationsSubscriptionId)
  params: {
    // Required Parameters
    parOrgPrefix: parRequired.orgPrefix
    parLocation: parLocation
    parDeployEnvironment: parRequired.deployEnvironment
    parTags: modTags.outputs.tags

    // Operations Network Parameters
    parOperationsNetworkSecurityGroupDiagnosticsLogs: parOperationsNetworkSecurityGroupDiagnosticsLogs
    parOperationsSubnetAddressPrefix: parOperationsSubnetAddressPrefix
    parOperationsSourceAddressPrefixes: parOperationsSourceAddressPrefixes
    parOperationsNetworkSecurityGroupRules: parOperationsNetworkSecurityGroupRules
    parOperationsSubnetServiceEndpoints: parOperationsSubnetServiceEndpoints
    parOperationsVirtualNetworkAddressPrefix: parOperationsVirtualNetworkAddressPrefix
    parOperationsVirtualNetworkDiagnosticsLogs: parOperationsVirtualNetworkDiagnosticsLogs
    parOperationsVirtualNetworkDiagnosticsMetrics: parOperationsVirtualNetworkDiagnosticsMetrics
    parFirewallPrivateIPAddress: modHubNetwork.outputs.firewallPrivateIPAddress
    parDisableBgpRoutePropagation: true

    // Log Storage Sku Parameters
    parLogStorageSkuName: parLogging.logStorageSkuName

    // RBAC for Storage Parameters
    parStorageAccountAccess: parStorageAccountAccess

    // Log Analytics Parameters
    parLogAnalyticsWorkspaceResourceId: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceResourceId
    parLogAnalyticsWorkspaceName: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceName
  }
}

// VIRTUAL NETWORK PEERINGS

module modHubVirtualNetworkPeerings '../../azresources/hub-spoke/peering/hub/anoa.lz.hub.network.peerings.bicep' = {
  name: 'deploy-vnet-peerings-hub-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parHubSubscriptionId, varHubResourceGroupName)
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

module modSpokeOpsToHubVirtualNetworkPeerings '../../azresources/hub-spoke/peering/spoke/anoa.lz.spoke.network.peering.bicep' = {
  name: 'deploy-vnet-spoke-peerings-ops-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parOperationsSubscriptionId, varOperationsResourceGroupName)
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

module modRemoteAccess '../../overlays/management-services/bastion/anoa.lz.mgmt.svcs.remote.access.bicep' = if (parRemoteAccess.enable) {
  name: 'deploy-remote-access-hub-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parHubSubscriptionId, varHubResourceGroupName)
  params: {
    // Required Parameters
    parOrgPrefix: parRequired.orgPrefix
    parLocation: parLocation
    parDeployEnvironment: parRequired.deployEnvironment
    parTags: modTags.outputs.tags

    // Hub Virtual Network Parameters    
    parHubVirtualNetworkName: modHubNetwork.outputs.virtualNetworkName
    parHubSubnetResourceId: modHubNetwork.outputs.subnetResourceId
    parHubNetworkSecurityGroupResourceId: modHubNetwork.outputs.networkSecurityGroupResourceId

    // Bastion Host Parameters   
    parBastionHostSku: parRemoteAccess.bastion.sku    
    parBastionHostSubnetAddressPrefix: parRemoteAccess.bastion.subnetAddressPrefix
    parEncryptionAtHost: parRemoteAccess.bastion.encryptionAtHost

    // Linux Parameters
    parEnableLinux:  parRemoteAccess.bastion.linux.enable
    parLinuxVmName: parRemoteAccess.bastion.linux.vmName
    parLinuxVmSize: parRemoteAccess.bastion.linux.vmSize
    parLinuxVmOsDiskCreateOption: parRemoteAccess.bastion.linux.vmOsDiskCreateOption
    parLinuxVmOsDiskType: parRemoteAccess.bastion.linux.vmOsDiskType
    parLinuxVmImagePublisher: parRemoteAccess.bastion.linux.vmImagePublisher
    parLinuxVmImageOffer: parRemoteAccess.bastion.linux.vmImageOffer
    parLinuxVmImageSku: parRemoteAccess.bastion.linux.vmImageSku
    parLinuxVmImageVersion: parRemoteAccess.bastion.linux.vmImageVersion
    parLinuxVmAdminUsername: parRemoteAccess.bastion.linux.vmAdminUsername
    parLinuxVmAdminPasswordOrKey: parRemoteAccess.bastion.linux.vmAdminPasswordOrKey
    parLinuxNetworkInterfacePrivateIPAddressAllocationMethod: parRemoteAccess.bastion.linux.networkInterfacePrivateIPAddressAllocationMethod
    parDisableLinuxVmPasswordAuthentication: parRemoteAccess.bastion.linux.disablePasswordAuthentication
    
    // Windows Parameters 
    parEnableWindows: parRemoteAccess.bastion.windows.enable
    parWindowsVmName: parRemoteAccess.bastion.windows.vmName
    parWindowsVmSize: parRemoteAccess.bastion.windows.vmSize
    parWindowsVmAdminUsername: parRemoteAccess.bastion.windows.vmAdminUsername
    parWindowsVmAdminPassword: parRemoteAccess.bastion.windows.vmAdminPassword
    parWindowsVmPublisher: parRemoteAccess.bastion.windows.vmImagePublisher
    parWindowsVmOffer: parRemoteAccess.bastion.windows.vmImageOffer
    parWindowsVmSku: parRemoteAccess.bastion.windows.vmImageSku
    parWindowsVmVersion: parRemoteAccess.bastion.windows.vmImageVersion
    parWindowsVmCreateOption: parRemoteAccess.bastion.windows.vmOsDiskCreateOption
    parWindowsVmStorageAccountType: parRemoteAccess.bastion.windows.vmStorageAccountType
    parWindowsNetworkInterfacePrivateIPAddressAllocationMethod: parRemoteAccess.bastion.windows.networkInterfacePrivateIPAddressAllocationMethod

    // Log Analytics Parameters
    parLogAnalyticsWorkspaceId: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceResourceId    
  }
}

module modVMExt '../../azresources/Modules/Microsoft.Compute/virtualmachines/extensions/az.com.virtual.machine.extensions.bicep' = if (parRemoteAccess.enable && parRemoteAccess.bastion.customScriptExtension.install) {
  name: 'deploy-vmext-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parHubSubscriptionId, varHubResourceGroupName)
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

module modDefender '../../overlays/management-services/defender/anoa.lz.mgmt.svcs.defender.bicep' = if (parSecurityCenter.enableDefender) {
  name: 'deploy-defender-hub-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHubSubscriptionId)
  params: {
    parLocation: parLocation
    parLogAnalyticsWorkspaceResourceId: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceResourceId
    parEmailSecurityContact: parSecurityCenter.emailSecurityContact
    parPhoneSecurityContact: parSecurityCenter.phoneSecurityContact
  }
}

// MICROSOFT DEFENDER FOR CLOUD FOR SPOKES

module spokeOpsDefender '../../overlays/management-services/defender/anoa.lz.mgmt.svcs.defender.bicep' = if (parSecurityCenter.enableDefender && parOperationsSubscriptionId != parHubSubscriptionId) {
  name: 'deploy-defender-ops-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parOperationsSubscriptionId)
  params: {
    parLocation: parLocation
    parLogAnalyticsWorkspaceResourceId: modLogAnalyticsWorkspace.outputs.outLogAnalyticsWorkspaceResourceId
    parEmailSecurityContact: parSecurityCenter.emailSecurityContact
    parPhoneSecurityContact: parSecurityCenter.phoneSecurityContact
  }
}

// OUTPUTS

output networkResourcePrefix string = parRequired.deployEnvironment

output firewallPrivateIPAddress string = modHubNetwork.outputs.firewallPrivateIPAddress

output hub object = {
  subscriptionId: parHubSubscriptionId
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
