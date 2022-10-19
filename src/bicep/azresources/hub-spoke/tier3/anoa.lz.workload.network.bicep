/*
SUMMARY: Module to deploy the Workload Network (tier 3) and it's components based on the Azure Mission Landing Zone conceptual architecture 
DESCRIPTION: The following components will be options in this deployment
              Workload Virtual Network (Vnet)
              Subnets  
              Route Table
              Network Security Group
              Log Storage
              Activity Logging
              Netowrk Peering (Hub/Spoke)
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

targetScope = 'subscription'

// REQUIRED PARAMETERS

@description('Prefix value which will be prepended to all resource names. Default: anoa')
param parOrgPrefix string = 'anoa'

@description('The subscription ID for the Workload Network and resources. It defaults to the deployment subscription.')
param parWorkloadSubscriptionId string = subscription().subscriptionId

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

@minLength(3)
@maxLength(15)
@description('A suffix, 3 to 15 characters in length, to append to resource names (e.g. "dev", "test", "prod"). ')
param parDeployEnvironment string

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

@minLength(3)
@maxLength(12)
@description('Prefix value which will be the workload name. Default: workload')
param parWorkloadName string = 'workload'

@minLength(3)
@maxLength(12)
@description('Prefix value which will be the workload name. Default: wk1')
param parWorkloadShortName string = 'wk1'

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

// NETWORK ADDRESS SPACE PARAMETERS
@description('The CIDR Virtual Network Address Prefix for the Workload Virtual Network.')
param parWorkloadVirtualNetworkAddressPrefix string = '10.8.125.0/26'

@description('The CIDR Subnet Address Prefix for the default Workload subnet. It must be in the Workload Virtual Network space.')
param parWorkloadSubnetAddressPrefix string = '10.8.125.0/27'

@description('The subscription ID for the Hub Network.')
param parHubSubscriptionId string

@description('The resource group name for the Hub Network.')
param parHubResourceGroupName string

@description('The virtual network name for the Hub Network.')
param parHubVirtualNetworkName string

@description('The virtual network resource Id for the Hub Network.')
param parHubVirtualNetworkResourceId string

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param parLogStorageSkuName string = 'Standard_GRS'

// WORKLOAD NETWORK PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the Workload Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param parWorkloadVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the Workload Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param parWorkloadVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group rules to apply to the Workload Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param parWorkloadNetworkSecurityGroupRules array = []

@description('An array of Network Security Group diagnostic logs to apply to the Workload Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param parWorkloadNetworkSecurityGroupDiagnosticsLogs array = [
  'NetworkSecurityGroupEvent'
  'NetworkSecurityGroupRuleCounter'
]

@description('An array of Service Endpoints to enable for the Workload subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param parWorkloadSubnetServiceEndpoints array = [
  {
    service: 'Microsoft.Storage'
  }
]

// LOGGING PARAMETERS

@description('Log Analytics Workspace Resource Id Needed for NSG, VNet and Activity Logging')
param parLogAnalyticsWorkspaceResourceId string

@description('Log Analytics Workspace Name Needed Activity Logging')
param parLogAnalyticsWorkspaceName string

@description('Enable this setting if this network is on a different subscriptiom as the Hub. Will give conflict errors if on same sub as the Hub')
param enableActivityLogging bool = false

// ROUTE TABLE 

param parFirewallPrivateIPAddress string
@description(' An Array of Routes to be established within the hub route table.')
param parRouteTableRoutes array = [
  {
    name: 'wl-routetable'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopIpAddress: parFirewallPrivateIPAddress
      nextHopType: 'VirtualAppliance'
    }
  }
]
param parDisableBgpRoutePropagation bool = false

//DDOS PARAMETERS

@description('Switch which allows DDOS deployment to be disabled. Default: false')
param parDeployddosProtectionPlan bool = false

// STORAGE ACCOUNTS RBAC
@description('Account for access to Storage')
param parStorageAccountAccess object

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

var varNetworkSecurityGroupNamingConvention = replace(varNamingConvention, varResourceToken, 'nsg')
var varResourceGroupNamingConvention = replace(varNamingConvention, varResourceToken, 'rg')
var varStorageAccountNamingConvention = toLower('${parOrgPrefix}st${varNameToken}unique_storage_token')
var varSubnetNamingConvention = replace(varNamingConvention, varResourceToken, 'snet')
var varVirtualNetworkNamingConvention = replace(varNamingConvention, varResourceToken, 'vnet')
var varDdosNamingConvention = replace(varNamingConvention, varResourceToken, 'ddos')

// WORKLOAD NAMES

var varWorkloadName = parWorkloadName
var varWorkloadShortName = parWorkloadShortName
var varWorkloadResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varWorkloadName)
var varWorkloadLogStorageAccountShortName = replace(varStorageAccountNamingConvention, varNameToken, replace(varWorkloadShortName, '-', ''))
var varWorkloadLogStorageAccountUniqueName = replace(varWorkloadLogStorageAccountShortName, 'unique_storage_token', uniqueString(parWorkloadSubscriptionId, parLocation, parDeployEnvironment, parOrgPrefix))
var varWorkloadLogStorageAccountName = take(varWorkloadLogStorageAccountUniqueName, 23)
var varWorkloadVirtualNetworkName = replace(varVirtualNetworkNamingConvention, varNameToken, varWorkloadName)
var varWorkloadNetworkSecurityGroupName = replace(varNetworkSecurityGroupNamingConvention, varNameToken, varWorkloadName)
var varWorkloadSubnetName = replace(varSubnetNamingConvention, varNameToken, varWorkloadName)
var workloadddosName = replace(varDdosNamingConvention, varNameToken, varWorkloadName)

// ROUTETABLE VALUES
var varRouteTableName = '${varWorkloadSubnetName}-routetable'

// TAGS

@description('Workload Resource group tags')
module modTags '../../Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-${varWorkloadShortName}-tags-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    tags: parTags
  }
}

// RESOURCE GROUPS

module modWorkloadResourceGroup '../../Modules/Microsoft.Resources/resourceGroups/az.resource.groups.bicep' = {
  name: 'deploy-${varWorkloadShortName}-rg-${parDeploymentNameSuffix}'
  scope: subscription(parWorkloadSubscriptionId)
  params: {
    name: varWorkloadResourceGroupName
    location: parLocation
    tags: modTags.outputs.tags
  }
}

//STORAGE ACCOUNT

module modWorkloadLogStorage '../../Modules/Microsoft.Storage/storageAccounts/az.data.storage.bicep' = {
  name: 'deploy-${varWorkloadShortName}-logStorage-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varWorkloadResourceGroupName)
  params: {
    name: varWorkloadLogStorageAccountName
    location: parLocation
    storageAccountSku: parLogStorageSkuName
    tags: modTags.outputs.tags
    roleAssignments: (parStorageAccountAccess.enableRoleAssignmentForStorageAccount) ? [
      {
        principalIds: [
          parStorageAccountAccess.principalIds
        ]
        roleDefinitionIdOrName: parStorageAccountAccess.roleDefinitionIdOrName
      }
    ] : []
    lock: 'CanNotDelete'
  }
  dependsOn: [
    modWorkloadResourceGroup
  ]
}

// NETWORK SECURITY GROUP

module modWorkloadNetworkSecurityGroup '../../Modules/Microsoft.Network/networkSecurityGroups/az.net.network.security.group.with.diagnostics.bicep' = {
  name: 'deploy-${varWorkloadShortName}-nsg-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varWorkloadResourceGroupName)
  params: {
    name: varWorkloadNetworkSecurityGroupName
    location: parLocation
    tags: modTags.outputs.tags

    securityRules: parWorkloadNetworkSecurityGroupRules

    diagnosticWorkspaceId: parLogAnalyticsWorkspaceResourceId
    diagnosticStorageAccountId: modWorkloadLogStorage.outputs.resourceId

    diagnosticLogCategoriesToEnable: parWorkloadNetworkSecurityGroupDiagnosticsLogs
  }
}

module modWorkloadRouteTable '../../Modules/Microsoft.Network/routeTable/az.net.route.table.bicep' = {
  name: 'deploy-${varWorkloadShortName}-rt-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varWorkloadResourceGroupName)
  params: {
    name: varRouteTableName
    location: parLocation
    tags: modTags.outputs.tags

    routes: parRouteTableRoutes
    disableBgpRoutePropagation: parDisableBgpRoutePropagation
  }
  dependsOn: [
    modWorkloadResourceGroup
  ]
}

module modWorkloadVirtualNetwork '../../Modules/Microsoft.Network/virtualNetworks/az.net.virtual.network.with.diagnostics.bicep' = {
  name: 'deploy-${varWorkloadShortName}-vnet-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varWorkloadResourceGroupName)
  params: {
    name: varWorkloadVirtualNetworkName
    location: parLocation
    tags: modTags.outputs.tags

    addressPrefixes: [
      parWorkloadVirtualNetworkAddressPrefix
    ]

    subnets: [
      {
        addressPrefix: parWorkloadSubnetAddressPrefix
        name: varWorkloadSubnetName
        networkSecurityGroupId: modWorkloadNetworkSecurityGroup.outputs.resourceId
        routeTableId: modWorkloadRouteTable.outputs.resourceId
        serviceEndpoints: parWorkloadSubnetServiceEndpoints
      }
    ]
    
    diagnosticWorkspaceId: parLogAnalyticsWorkspaceResourceId
    diagnosticStorageAccountId: modWorkloadLogStorage.outputs.resourceId

    diagnosticLogCategoriesToEnable: parWorkloadVirtualNetworkDiagnosticsLogs
    diagnosticMetricsToEnable: parWorkloadVirtualNetworkDiagnosticsMetrics
    ddosProtectionPlanEnabled: parDeployddosProtectionPlan
    ddosProtectionPlanId: workloadddosName
  }
}

module spokeWorkloadSubscriptionActivityLogging '../../Modules/Microsoft.Insights/diagnosticSettings/az.insights.diagnostic.setting.bicep' = if (enableActivityLogging) {
  name: 'deploy-logs-${varWorkloadShortName}-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    name: 'log-workload-sub-activity-to-${parLogAnalyticsWorkspaceName}'
    diagnosticWorkspaceId: parLogAnalyticsWorkspaceResourceId
  }
  dependsOn: [
    modWorkloadVirtualNetwork
    modWorkloadLogStorage
  ]

}

output virtualNetworkName string = modWorkloadVirtualNetwork.outputs.name
output virtualNetworkResourceId string = modWorkloadVirtualNetwork.outputs.resourceId
output subnetNames array = modWorkloadVirtualNetwork.outputs.subnetNames
output subnetResourceIds array = modWorkloadVirtualNetwork.outputs.subnetResourceIds
output networkSecurityGroupName string = modWorkloadNetworkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string = modWorkloadNetworkSecurityGroup.outputs.resourceId
output workloadResourceGroupName string = varWorkloadResourceGroupName
output workloadLogStorageAccountName string = varWorkloadLogStorageAccountName
output workloadLogStorageAccountResourceId string = modWorkloadLogStorage.outputs.resourceId
