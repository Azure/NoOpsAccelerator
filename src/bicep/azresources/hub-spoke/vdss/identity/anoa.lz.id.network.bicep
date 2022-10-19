/*
SUMMARY: Module to deploy the Shared Services Network and it's components based on the Azure Mission Landing Zone conceptual architecture 
DESCRIPTION: The following components will be options in this deployment
              Shared Services Virtual Network (Vnet)
              Subnets  
              Route Table
              Network Security Group
              Log Storage
              Activity Logging              
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

@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param parIdentitySubscriptionId string = subscription().subscriptionId

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

// NETWORK ADDRESS SPACE PARAMETERS
@description('The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.')
param parIdentityVirtualNetworkAddressPrefix string = '10.0.120.0/26'

@description('The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.')
param parIdentitySubnetAddressPrefix string = '10.0.120.0/27'

// SHARED SERVICES NETWORK PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param parIdentityVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param parIdentityVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group rules to apply to the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param parIdentityNetworkSecurityGroupRules array = [
  {
    name: 'Allow-Traffic-From-Spokes'
    properties: {
      access: 'Allow'
      description: 'Allow traffic from spokes'
      destinationAddressPrefix: parIdentityVirtualNetworkAddressPrefix
      destinationPortRanges: [
        '22'
        '80'
        '443'
        '3389'
      ]
      direction: 'Inbound'
      priority: 200
      protocol: '*'
      sourceAddressPrefixes: [
        '10.0.110.0/27'
        '10.0.115.0/27'
      ]
      sourcePortRange: '*'
    }
    type: 'string'
  }
]

@description('An array of Network Security Group diagnostic logs to apply to the Identity Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param parIdentityNetworkSecurityGroupDiagnosticsLogs array = [
  'NetworkSecurityGroupEvent'
  'NetworkSecurityGroupRuleCounter'

]

@description('An array of Service Endpoints to enable for the Identity subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param parIdentitySubnetServiceEndpoints array = [
  {
    service: 'Microsoft.Storage'
  }
]

// ROUTE TABLE 

param parFirewallPrivateIPAddress string
param parRouteTableRouteAddressPrefix string = '0.0.0.0/0'
param parRouteTableRouteNextHopIpAddress string = parFirewallPrivateIPAddress
param parRouteTableRouteNextHopType string = 'VirtualAppliance'
param parDisableBgpRoutePropagation bool

//DDOS PARAMETERS

@description('Switch which allows DDOS deployment to be disabled. Default: false')
param parDeployddosProtectionPlan bool = false

// LOGGING PARAMETERS

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param parLogStorageSkuName string = 'Standard_GRS'

@description('Log Analytics Workspace Resource Id Needed for NSG, VNet and Activity Logging')
param parLogAnalyticsWorkspaceResourceId string

@description('Log Analytics Workspace Name Needed Activity Logging')
param parLogAnalyticsWorkspaceName string

@description('Enable this setting if this network is on a different subscriptiom from the Hub and every other spoke. Will give conflict errors if on same sub as the Hub or any other spoke')
param enableActivityLogging bool = false

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

// SHARED SERVICES NAMES

var varIdentityName = 'identity'
var varIdentityShortName = 'identity'
var varIdentityResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varIdentityName)
var varIdentityLogStorageAccountShortName = replace(varStorageAccountNamingConvention, varNameToken, varIdentityShortName)
var varIdentityLogStorageAccountUniqueName = replace(varIdentityLogStorageAccountShortName, 'unique_storage_token', uniqueString(parIdentitySubscriptionId, parLocation, parDeployEnvironment, parOrgPrefix))
var varIdentityLogStorageAccountName = take(varIdentityLogStorageAccountUniqueName, 23)
var varIdentityVirtualNetworkName = replace(varVirtualNetworkNamingConvention, varNameToken, varIdentityName)
var varIdentityNetworkSecurityGroupName = replace(varNetworkSecurityGroupNamingConvention, varNameToken, varIdentityName)
var varIdentitySubnetName = replace(varSubnetNamingConvention, varNameToken, varIdentityName)
var idddosName = replace(varDdosNamingConvention, varNameToken, varIdentityName)

// ROUTETABLE VALUES
var varRouteTableName = '${varIdentitySubnetName}-routetable'

// TAGS

@description('Resource group tags')
module modTags '../../../Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-${varIdentityShortName}-tags--${parLocation}-${parDeploymentNameSuffix}'
  params: {
    tags: parTags
  }
}

// RESOURCE GROUPS

module modIdentityResourceGroup '../../../Modules/Microsoft.Resources/resourceGroups/az.resource.groups.bicep' = {
  name: 'deploy-${varIdentityShortName}-rg-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parIdentitySubscriptionId)
  params: {
    name: varIdentityResourceGroupName
    location: parLocation
    tags: modTags.outputs.tags
  }
}

module modIdentityLogStorage '../../../Modules/Microsoft.Storage/storageAccounts/az.data.storage.bicep' = {
  name: 'deploy-${varIdentityShortName}-logStorage-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varIdentityResourceGroupName)
  params: {
    name: varIdentityLogStorageAccountName
    location: parLocation
    storageAccountSku: parLogStorageSkuName
    tags: modTags.outputs.tags
    roleAssignments: (parStorageAccountAccess.enableRoleAssignmentForStorageAccount) ? [
      {
        principalIds: [
          parStorageAccountAccess.principalIds
        ]
        principalType: parStorageAccountAccess.principalType
        roleDefinitionIdOrName: parStorageAccountAccess.roleDefinitionIdOrName
      }
    ] : []
    lock: 'CanNotDelete'
  }
  dependsOn: [
    modIdentityResourceGroup
  ]
}

module modIdentityNetworkSecurityGroup '../../../Modules/Microsoft.Network/networkSecurityGroups/az.net.network.security.group.with.diagnostics.bicep' = {
  name: 'deploy-${varIdentityShortName}-nsg-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varIdentityResourceGroupName)
  params: {
    name: varIdentityNetworkSecurityGroupName
    location: parLocation
    tags: modTags.outputs.tags

    securityRules: parIdentityNetworkSecurityGroupRules

    diagnosticWorkspaceId: parLogAnalyticsWorkspaceResourceId
    diagnosticStorageAccountId: modIdentityLogStorage.outputs.resourceId

    diagnosticLogCategoriesToEnable: parIdentityNetworkSecurityGroupDiagnosticsLogs
  }
}

module modIdentityRouteTable '../../../Modules/Microsoft.Network/routeTable/az.net.route.table.bicep' = {
  name: 'deploy-${varIdentityShortName}-routeTable-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varIdentityResourceGroupName)
  params: {
    name: varRouteTableName
    location: parLocation
    tags: modTags.outputs.tags

    routes: [
      {
        name: varRouteTableName
        properties: {
          addressPrefix: parRouteTableRouteAddressPrefix
          nextHopIpAddress: parRouteTableRouteNextHopIpAddress
          nextHopType: parRouteTableRouteNextHopType
        }
      }
    ]
    disableBgpRoutePropagation: parDisableBgpRoutePropagation
  }
  dependsOn: [
    modIdentityResourceGroup
  ]
}

module modIdentityVirtualNetwork '../../../Modules/Microsoft.Network/virtualNetworks/az.net.virtual.network.with.diagnostics.bicep' = {
  name: 'deploy-${varIdentityShortName}-vnet-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varIdentityResourceGroupName)
  params: {
    name: varIdentityVirtualNetworkName
    location: parLocation
    tags: modTags.outputs.tags

    addressPrefixes: [
      parIdentityVirtualNetworkAddressPrefix
    ]

    subnets: [
      {
        addressPrefix: parIdentitySubnetAddressPrefix
        name: varIdentitySubnetName
        networkSecurityGroupId: modIdentityNetworkSecurityGroup.outputs.resourceId
        routeTableId: modIdentityRouteTable.outputs.resourceId
        serviceEndpoints: parIdentitySubnetServiceEndpoints
      }
    ]

    diagnosticWorkspaceId: parLogAnalyticsWorkspaceResourceId
    diagnosticStorageAccountId: modIdentityLogStorage.outputs.resourceId

    diagnosticLogCategoriesToEnable: parIdentityVirtualNetworkDiagnosticsLogs
    diagnosticMetricsToEnable: parIdentityVirtualNetworkDiagnosticsMetrics
    ddosProtectionPlanEnabled: parDeployddosProtectionPlan
    ddosProtectionPlanId: idddosName
  }
}

module spokeIdentitySubscriptionActivityLogging '../../../Modules/Microsoft.Insights/diagnosticSettings/az.insights.diagnostic.setting.bicep' = if (enableActivityLogging) {
  name: 'deploy-activity-logs-${varIdentityShortName}-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    name: 'log-identity-sub-activity-to-${parLogAnalyticsWorkspaceName}'
    diagnosticWorkspaceId: parLogAnalyticsWorkspaceResourceId
    diagnosticLogCategoriesToEnable: [
      'Administrative'
      'Security'
      'ServiceHealth'
      'Alert'
      'Recommendation'
      'Policy'
      'Autoscale'
      'ResourceHealth'
      'Audit'
    ]
    diagnosticMetricCategoriesToEnable: []
  }
  dependsOn: [
    modIdentityVirtualNetwork
  ]
}

output virtualNetworkName string = modIdentityVirtualNetwork.outputs.name
output virtualNetworkResourceId string = modIdentityVirtualNetwork.outputs.resourceId
output subnetNames array = modIdentityVirtualNetwork.outputs.subnetNames
output subnetResourceIds array = modIdentityVirtualNetwork.outputs.subnetResourceIds
output networkSecurityGroupName string = modIdentityNetworkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string = modIdentityNetworkSecurityGroup.outputs.resourceId
