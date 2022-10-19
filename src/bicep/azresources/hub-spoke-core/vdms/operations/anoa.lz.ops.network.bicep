/*
SUMMARY: Module to deploy the Operations Network and it's components based on the Azure Mission Landing Zone conceptual architecture 
DESCRIPTION: The following components will be options in this deployment
              Operations Virtual Network (Vnet)
              Subnets  
              Route Table
              Network Security Group
              Log Storage
              Activity Logging
              Private DNS Zones - Details of all the Azure Private DNS zones can be found here --> https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration     
AUTHOR/S: jspinella

*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

targetScope = 'subscription'

// REQUIRED PARAMETERS

@description('Prefix value which will be prepended to all resource names. Default: anoa')
param parOrgPrefix string = 'anoa'

@description('The subscription ID for the Operations Network and resources. It defaults to the deployment subscription.')
param parOperationsSubscriptionId string = subscription().subscriptionId

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
@description('The CIDR Virtual Network Address Prefix for the Operations Virtual Network.')
param parOperationsVirtualNetworkAddressPrefix string = '10.0.115.0/26'

@description('The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.')
param parOperationsSubnetAddressPrefix string = '10.0.115.0/27'

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param parLogStorageSkuName string = 'Standard_GRS'

// OPERATIONS NETWORK PARAMETERS

@description('An array of Network Diagnostic Logs to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param parOperationsVirtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param parOperationsVirtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group rules to apply to the Operations Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param parOperationsNetworkSecurityGroupRules array = []

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

@description('Log Analytics Workspace Resource Id Needed for NSG, VNet and Activity Logging')
param parLogAnalyticsWorkspaceResourceId string

@description('Log Analytics Workspace Name Needed Activity Logging')
param parLogAnalyticsWorkspaceName string

@description('Enable this setting if this network is on a different subscriptiom as the Hub. Will give conflict errors if on same sub as the Hub')
param enableActivityLogging bool = false

// ROUTE TABLE 

@description(' An Array of Routes to be established within the hub route table.')
param parRouteTableRoutes array = [
  {
    name: 'ops-routetable'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopIpAddress: parFirewallPrivateIPAddress
      nextHopType: 'VirtualAppliance'
    }
  }
]

@description('Firewall private IP address within the hub route table.')
param parFirewallPrivateIPAddress string

param parDisableBgpRoutePropagation bool

//DDOS PARAMETERS

@description('Switch which allows DDOS deployment to be disabled. Default: false')
param parDeployddosProtectionPlan bool = false

// STORAGE ACCOUNTS RBAC
@description('Account for access to Storage')
param parOperationsStorageAccountAccess object

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
var subnetNamingConvention = replace(varNamingConvention, varResourceToken, 'snet')
var virtualNetworkNamingConvention = replace(varNamingConvention, varResourceToken, 'vnet')
var varDdosNamingConvention = replace(varNamingConvention, varResourceToken, 'ddos')

// OPERATIONS NAMES

var varOperationsName = 'operations'
var varOperationsShortName = 'ops'
var varOperationsResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varOperationsName)
var varOperationsLogStorageAccountShortName = replace(varStorageAccountNamingConvention, varNameToken, varOperationsShortName)
var varOperationsLogStorageAccountUniqueName = replace(varOperationsLogStorageAccountShortName, 'unique_storage_token',  uniqueString(parOperationsSubscriptionId, parLocation, parDeployEnvironment, parOrgPrefix))
var varOperationsLogStorageAccountName = take(varOperationsLogStorageAccountUniqueName, 23)
var varOperationsVirtualNetworkName = replace(virtualNetworkNamingConvention, varNameToken, varOperationsName)
var varOperationsNetworkSecurityGroupName = replace(varNetworkSecurityGroupNamingConvention, varNameToken, varOperationsName)
var varOperationsSubnetName = replace(subnetNamingConvention, varNameToken, varOperationsName)
var opsddosName = replace(varDdosNamingConvention, varNameToken, varOperationsName)

// TAGS

@description('Resource group tags')
module modTags '../../../Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-${varOperationsShortName}-tags-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    tags: parTags
  }
}

// RESOURCE GROUPS

module modOperationsResourceGroup '../../../Modules/Microsoft.Resources/resourceGroups/az.resource.groups.bicep' = {
  name: 'deploy-${varOperationsShortName}-rg-${parDeploymentNameSuffix}'
  scope: subscription(parOperationsSubscriptionId)
  params: {
    name: varOperationsResourceGroupName
    location: parLocation
    tags: modTags.outputs.tags
  }
}

//STORAGE ACCOUNT

module modOpsLogStorage '../../../Modules/Microsoft.Storage/storageAccounts/az.data.storage.bicep' = {
  name: 'deploy-${varOperationsShortName}-logStorage-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(varOperationsResourceGroupName) 
    params: {
      name: varOperationsLogStorageAccountName
      location: parLocation   
      storageAccountSku: parLogStorageSkuName
      tags: modTags.outputs.tags
      roleAssignments: (parOperationsStorageAccountAccess.enableRoleAssignmentForStorageAccount) ? [
        {
          principalIds: [
            parOperationsStorageAccountAccess.principalIds
          ]
          roleDefinitionIdOrName: parOperationsStorageAccountAccess.roleDefinitionIdOrName
        }
      ] : []
      lock: 'CanNotDelete'    
  }
  dependsOn: [
    modOperationsResourceGroup
  ]
}

// NETWORK SECURITY GROUP

module modOperationsNetworkSecurityGroup '../../../Modules/Microsoft.Network/networkSecurityGroups/az.net.network.security.group.with.diagnostics.bicep' = {
  name: 'deploy-${varOperationsShortName}-networkSecurityGroup-${parLocation}-${parDeploymentNameSuffix}' 
  scope: resourceGroup(varOperationsResourceGroupName)  
  params: {
    name: varOperationsNetworkSecurityGroupName
    location: parLocation
    tags: modTags.outputs.tags

    securityRules: parOperationsNetworkSecurityGroupRules

    diagnosticWorkspaceId: parLogAnalyticsWorkspaceResourceId
    diagnosticStorageAccountId: modOpsLogStorage.outputs.resourceId

    diagnosticLogCategoriesToEnable: parOperationsNetworkSecurityGroupDiagnosticsLogs    
  }
}

module modOperationsRouteTable '../../../Modules/Microsoft.Network/routeTable/az.net.route.table.bicep' = {
  name: 'deploy-${varOperationsShortName}-routeTable-${parLocation}-${parDeploymentNameSuffix}'  
  scope: resourceGroup(varOperationsResourceGroupName) 
  params: {
    name: 'ops-routetable'
    location: parLocation
    tags: modTags.outputs.tags

    routes: parRouteTableRoutes
    disableBgpRoutePropagation: parDisableBgpRoutePropagation
  }
  dependsOn: [
    modOperationsResourceGroup
  ]
}

module modOperationsVirtualNetwork '../../../Modules/Microsoft.Network/virtualNetworks/az.net.virtual.network.with.diagnostics.bicep' = {
  name: 'deploy-${varOperationsShortName}-virtualNetwork-${parLocation}-${parDeploymentNameSuffix}'  
  scope: resourceGroup(varOperationsResourceGroupName) 
  params: {
    name: varOperationsVirtualNetworkName
    location: parLocation
    tags: modTags.outputs.tags

    addressPrefixes: [
      parOperationsVirtualNetworkAddressPrefix
    ]

    subnets: [
        {
          addressPrefix: parOperationsSubnetAddressPrefix
          name: varOperationsSubnetName
          networkSecurityGroupId: modOperationsNetworkSecurityGroup.outputs.resourceId  
          routeTableId: modOperationsRouteTable.outputs.resourceId
          serviceEndpoints: parOperationsSubnetServiceEndpoints
        } 
    ]

    diagnosticWorkspaceId: parLogAnalyticsWorkspaceResourceId
    diagnosticStorageAccountId: modOpsLogStorage.outputs.resourceId

    diagnosticLogCategoriesToEnable: parOperationsVirtualNetworkDiagnosticsLogs
    diagnosticMetricsToEnable: parOperationsVirtualNetworkDiagnosticsMetrics
    ddosProtectionPlanEnabled: parDeployddosProtectionPlan
    ddosProtectionPlanId: opsddosName
  }
}

module spokeOpsSubscriptionActivityLogging '../../../Modules/Microsoft.Insights/diagnosticSettings/az.insights.diagnostic.setting.bicep' = if (enableActivityLogging) {
  name: 'deploy-activity-logs-${varOperationsShortName}-${parLocation}-${parDeploymentNameSuffix}'  
  params: {
    name: 'log-operations-sub-activity-to-${parLogAnalyticsWorkspaceName}'
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
    diagnosticMetricCategoriesToEnable: [
      'AllMetrics'
    ]
  }
  dependsOn: [
    modOperationsVirtualNetwork
    modOpsLogStorage
  ]
}

output virtualNetworkName string = modOperationsVirtualNetwork.outputs.name
output virtualNetworkResourceId string = modOperationsVirtualNetwork.outputs.resourceId
output subnetNames array = modOperationsVirtualNetwork.outputs.subnetNames
output subnetResourceIds array = modOperationsVirtualNetwork.outputs.subnetResourceIds
output networkSecurityGroupName string = modOperationsNetworkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string =  modOperationsNetworkSecurityGroup.outputs.resourceId
output operationsResourceGroupName string = varOperationsResourceGroupName
output operationsLogStorageAccountName string = varOperationsLogStorageAccountName
