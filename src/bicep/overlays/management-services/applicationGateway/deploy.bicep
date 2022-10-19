// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Module Example to deploy a Application Gateway to the Hub Network
DESCRIPTION: The following components will be options in this deployment
              Application Gateway
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

// === PARAMETERS ===
targetScope = 'resourceGroup'

// REQUIRED PARAMETERS
// Example (JSON)
// These are the required parameters for the deployment
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
// These are the required tags for the deployment
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
param parLocation string = resourceGroup().location

// HUB NETWORK PARAMETERS

@description('The resource group name for the Hub Network and resources.')
param parHubResourceGroupName string

@description('The resource group name for the Hub Network name.')
param parHubVirtualNetworkName string

// LOGGING PARAMETERS

@description('Log Analytics Workspace Resource Id Needed for NSG, VNet and Activity Logging')
param parLogAnalyticsWorkspaceResourceId string

@description('The resource group name for the Hub Network and resources. It defaults to the deployment resource group.')
param parHubLogStorageResourceId string

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

@description('The current date - do not override the default value')
param dateUtcNow string = utcNow('yyyy-MM-dd HH:mm:ss')

param subnetAddressPrefix string

// APP GATEWAY PARAMETERS

@description('Application gateway tier')
param parAppGateway object

@description('Application gateway tier')
@allowed([
  'Standard'
  'WAF'
  'Standard_v2'
  'WAF_v2'
])
param parTier string

@description('Application gateway sku')
@allowed([
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
  'WAF_Medium'
  'WAF_Large'
  'Standard_v2'
  'WAF_v2'
])
param parSku string

@description('Array containing front end ports')
@metadata({
  name: 'Front port name'
  port: 'Integer containing port number'
})
param parFrontEndPorts array

@description('Array containing http listeners')
@metadata({
  name: 'Listener name'
  protocol: 'Listener protocol'
  frontEndPort: 'Front end port name'
  sslCertificate: 'SSL certificate name' // only required for https listeners
  hostNames: 'Array containing host names'
  firewallPolicy: 'Enabled/Disabled. Configures firewall policy on listener'
})
param parHttpListeners array

@description('Array containing request routing rules')
@metadata({
  name: 'Rule name'
  ruleType: 'Rule type'
  listener: 'Http listener name'
  backendPool: 'Backend pool name'
  backendHttpSettings: 'Backend http setting name'
  redirectConfiguration: 'Redirection configuration name'
})
param parRules array

@description('Public ip address name')
param parPublicIpAddressName string

@description('Application gateway subnet name')
param parSubnetName string

// VARIABLES

var subnetName = 'AppGWSubnet' // The subnet name for VNG Hosts must be 'AppGWSubnet'

/*
  NAMING CONVENTION
  Here we define a naming conventions for resources.
  First, we take `parDeployEnvironment` and `parDeployEnvironment` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.
*/

var varResourceToken = 'resource_token'
var varNameToken = 'name_token'
var varNamingConvention = '${toLower(parRequired.orgPrefix)}-${toLower(parLocation)}-${toLower(parRequired.deployEnvironment)}-${varNameToken}-${toLower(varResourceToken)}'

var varApplicationGatewayNamingConvention = replace(varNamingConvention, varResourceToken, 'agway')

var varHubName = 'hub'
var varHubApplicationGatewayName = replace(varApplicationGatewayNamingConvention, varNameToken, varHubName)

//=== TAGS === 

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
  workload: 'appGateway'
}

@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'appg-tags-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription()
  params: {    
    resourceGroupName: parHubResourceGroupName
    tags: union(parTags, referential)
  }
}

// HUB VNET

resource resHubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: parHubVirtualNetworkName
}

// ADD GATEWAY SUBNET TO HUB

resource resSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: '${parHubVirtualNetworkName}/${subnetName}'
  properties: {
    addressPrefix: subnetAddressPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

// HUB APP GATEWAY 

module modHubAppGateway '../../../azresources/Modules/Microsoft.Network/applicationGateway/az.net.application.gateway.bicep' = {
  name: 'deploy-${varHubName}-vnet-gateway-${parLocation}-${parDeploymentNameSuffix}'
  scope: resourceGroup(parHubResourceGroupName)
  params: {
    // Required parameters
    applicationGatewayName: varHubApplicationGatewayName
    location: parLocation    
    frontEndPorts: parFrontEndPorts
    httpListeners: parHttpListeners
    publicIpAddressName: parPublicIpAddressName
    rules: parRules
    sku: parSku
    subnetName: parSubnetName
    tier: parTier
    vNetName: resHubVirtualNetwork.name
    vNetResourceGroup: parHubResourceGroupName
    diagnosticStorageAccountId: parHubLogStorageResourceId
    logAnalyticsWorkspaceId: parLogAnalyticsWorkspaceResourceId
    enableDiagnostics: true
  }
  dependsOn: [
    resSubnet
  ]
}
