/*
SUMMARY: Module to deploy the Shared Services Network and it's components based on the Azure Mission Landing Zone conceptual architecture 
DESCRIPTION: The following components will be options in this deployment
              Shared Services Virtual Network (Vnet)
              Subnets  
              Route Table
              Network Security Group
              Log Storage
              Activity Logging
              Private DNS Zones - Details of all the Azure Private DNS zones can be found here --> https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration     
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

targetScope = 'subscription'

// REQUIRED PARAMETERS

@description('Prefix value which will be prepended to all resource names. Default: org')
param parOrgPrefix string = 'org'

@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param parDataServicesSubscriptionId string = subscription().subscriptionId

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

@description('The MLZ template version')
@minLength(3)
param parTemplateVersion string

@minLength(3)
@maxLength(15)
@description('A suffix, 3 to 15 characters in length, to append to resource names (e.g. "dev", "test", "prod"). ')
param parDeployEnvironment string

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

//DDOS PARAMETERS

@description('Switch which allows DDOS deployment to be disabled. Default: false')
param parDeployddosProtectionPlan bool = false

@description('Use this parameter if you are deploying seperatly from the full network deploy. If deploying full network, switch to false. It defaults to "true".')
param parResourceGroupModuleCreate bool = true

// NETWORK ADDRESS SPACE PARAMETERS
@description('The CIDR Virtual Network Address Prefix for the Shared Services Virtual Network.')
param parDataServicesVirtualNetworkAddressPrefix string = '10.0.120.0/26'

@description('The CIDR Subnet Address Prefix for the default Shared Services subnet. It must be in the Shared Services Virtual Network space.')
param parDataServicesSubnetAddressPrefix string = '10.0.120.0/27'

// SHARED SERVICES NETWORK PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the DataServices Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param parDataServicesVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the DataServices Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param parDataServicesVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group rules to apply to the DataServices Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param parDataServicesNetworkSecurityGroupRules array = [
  {
    name: 'Allow-Traffic-From-Spokes'
    properties: {
      access: 'Allow'
      description: 'Allow traffic from spokes'
      destinationAddressPrefix: parDataServicesVirtualNetworkAddressPrefix
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
        '10.0.110.0/26'
        '10.0.115.0/26'
      ]
      sourcePortRange: '*'
    }
    type: 'string'
  }
]

@description('An array of Network Security Group diagnostic logs to apply to the DataServices Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param parDataServicesNetworkSecurityGroupDiagnosticsLogs array = [
  'NetworkSecurityGroupEvent'
  'NetworkSecurityGroupRuleCounter'
]

@description('An array of Service Endpoints to enable for the DataServices subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param parDataServicesSubnetServiceEndpoints array = [
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

// LOGGING PARAMETERS

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param parLogStorageSkuName string = 'Standard_GRS'

@description('Log Analytics Workspace Resource Id Needed for NSG, VNet and Activity Logging')
param parLogAnalyticsWorkspaceResourceId string

@description('Log Analytics Workspace Name Needed Activity Logging')
param parLogAnalyticsWorkspaceName string

@description('Enable this setting if this network is on a different subscriptiom as the Hub. Will give conflict errors if on same sub as the Hub')
param enableActivityLogging bool = false

//STORAGE ACCOUNTS
@description('Account for access to Storage')
param parStorageAccountAccessObjectId string

@description('Switch which allows Role Assignment for the Storage Account. Default: true')
param parAddRoleAssignmentForStorageAccount bool = true

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

var varDataServicesName = 'dataservices'
var varDataServicesShortName = 'datasvcs'
var varDataServicesResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varDataServicesName)
var varDataServicesLogStorageAccountShortName = replace(varStorageAccountNamingConvention, varNameToken, varDataServicesShortName)
var varDataServicesLogStorageAccountUniqueName = replace(varDataServicesLogStorageAccountShortName, 'unique_storage_token', uniqueString(parDataServicesSubscriptionId, parLocation, parDeployEnvironment, parOrgPrefix))
var varDataServicesLogStorageAccountName = take(varDataServicesLogStorageAccountUniqueName, 23)
var varDataServicesVirtualNetworkName = replace(varVirtualNetworkNamingConvention, varNameToken, varDataServicesName)
var varDataServicesNetworkSecurityGroupName = replace(varNetworkSecurityGroupNamingConvention, varNameToken, varDataServicesName)
var varDataServicesSubnetName = replace(varSubnetNamingConvention, varNameToken, varDataServicesName)
var svcsddosName = replace(varDdosNamingConvention, varNameToken, varDataServicesName)

// ROUTETABLE VALUES
var varRouteTableName = '${varDataServicesSubnetName}-routetable'

// TAGS

@description('Resource group tags')
module modTags '../../../Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-${varDataServicesShortName}-tags-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    onlyUpdate: true
    tags: {
      organizationName: parOrgPrefix
      hostName: parDeployEnvironment
      regionName: parLocation
      templateVersion: parTemplateVersion
    }
  }
}

// RESOURCE GROUPS

module modDataServicesResourceGroup '../../../Modules/Microsoft.Resources/resourceGroups/az.resource.groups.bicep' = if(parResourceGroupModuleCreate) {
  name: 'deploy-${varDataServicesShortName}-rg-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parDataServicesSubscriptionId)
  params: {
    name: varDataServicesResourceGroupName
    location: parLocation
    tags: modTags.outputs.tags
  }
}

module modSvcsLogStorage '../../../Modules/Microsoft.Storage/storageAccounts/az.data.storage.bicep' = {
  name: 'deploy-${varDataServicesShortName}-logStorage-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varDataServicesResourceGroupName)
  params: {
    name: varDataServicesLogStorageAccountName
    location: parLocation   
    storageAccountSku: parLogStorageSkuName
    tags: modTags.outputs.tags
    roleAssignments: (parAddRoleAssignmentForStorageAccount) ? [
      {
        principalIds: [
          parStorageAccountAccessObjectId
        ]
        roleDefinitionIdOrName: 'Contributor'
      }
    ] : []
    lock: 'CanNotDelete'  
  }
  dependsOn: [
    modDataServicesResourceGroup
  ]
}

module modDataServicesNetworkSecurityGroup '../../../Modules/Microsoft.Network/networkSecurityGroup/az.net.network.security.group.with.diagnostics.bicep' = {
  name: 'deploy-${varDataServicesShortName}-nsg-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varDataServicesResourceGroupName)
  params: {
    name: varDataServicesNetworkSecurityGroupName
    location: parLocation
    tags: modTags.outputs.tags

    securityRules: parDataServicesNetworkSecurityGroupRules

    diagnosticWorkspaceId: parLogAnalyticsWorkspaceResourceId
    diagnosticStorageAccountId: modSvcsLogStorage.outputs.resourceId

    diagnosticLogCategoriesToEnable: parDataServicesNetworkSecurityGroupDiagnosticsLogs   
  }
}

module modDataServicesRouteTable '../../../Modules/Microsoft.Network/routeTable/az.net.route.table.bicep' = {
  name: 'deploy-${varDataServicesShortName}-routeTable-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varDataServicesResourceGroupName)
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
    modDataServicesResourceGroup
  ]
}

module modDataServicesVirtualNetwork '../../../Modules/Microsoft.Network/virtualNetworks/az.net.virtual.network.with.diagnostics.bicep' = {
  name: 'deploy-${varDataServicesShortName}-virtualNetwork-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varDataServicesResourceGroupName)
  params: {
    name: varDataServicesVirtualNetworkName
    location: parLocation
    tags: modTags.outputs.tags

    addressPrefixes: [
      parDataServicesVirtualNetworkAddressPrefix
    ]

    subnets: [     
      {
        addressPrefix: parDataServicesSubnetAddressPrefix
        name: varDataServicesSubnetName
        networkSecurityGroupId: modDataServicesNetworkSecurityGroup.outputs.resourceId  
        routeTableId: modDataServicesRouteTable.outputs.resourceId
        serviceEndpoints: parDataServicesSubnetServiceEndpoints
      } 
    ]

    diagnosticWorkspaceId: parLogAnalyticsWorkspaceResourceId
    diagnosticStorageAccountId: modSvcsLogStorage.outputs.resourceId

    diagnosticLogCategoriesToEnable: parDataServicesVirtualNetworkDiagnosticsLogs
    diagnosticMetricsToEnable: parDataServicesVirtualNetworkDiagnosticsMetrics
    ddosProtectionPlanEnabled: parDeployddosProtectionPlan
    ddosProtectionPlanId: svcsddosName
  }
}

module spokeDataServicesSubscriptionActivityLogging '../../../Modules/Microsoft.Insights/diagnosticSettings/az.insights.diagnostic.setting.bicep' = if (enableActivityLogging) {
  name: 'deploy-activity-logs-${varDataServicesShortName}-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    diagnosticEventHubName: 'log-dataservices-sub-activity-to-${parLogAnalyticsWorkspaceName}'
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
    modDataServicesVirtualNetwork
    modSvcsLogStorage
  ]
}

output virtualNetworkName string = modDataServicesVirtualNetwork.outputs.name
output virtualNetworkResourceId string = modDataServicesVirtualNetwork.outputs.resourceId
output subnetNames array = modDataServicesVirtualNetwork.outputs.subnetNames
output subnetResourceIds array = modDataServicesVirtualNetwork.outputs.subnetResourceIds
output networkSecurityGroupName string = modDataServicesNetworkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string =  modDataServicesNetworkSecurityGroup.outputs.resourceId
