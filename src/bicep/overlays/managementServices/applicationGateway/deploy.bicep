// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Module to deploy a Application Gateway to the Hub Network
DESCRIPTION: The following components will be options in this deployment
              Automation Account
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

targetScope = 'subscription'

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
param parLocation string = deployment().location

// SUBSCRIPTIONS PARAMETERS

// Hub Subscription Id
// (JSON Parameter)
// ---------------------------
// "parHubSubscriptionId": {
//   "value": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxx"
// }
@description('The subscription ID for the Hub Network and resources. It defaults to the deployment subscription.')
param parHubSubscriptionId string = subscription().subscriptionId

// Hub Resource Group Name
// (JSON Parameter)
// ---------------------------
// "parHubResourceGroup": {
//   "value": "anoa-eastus-platforms-hub-rg"
// }
@description('The name of the Hub resource group in which the app gateway will be deployed.')
param parHubResourceGroup string = ''

// Hub Virtual Network Name
// (JSON Parameter)
// ---------------------------
// "parHubVirtualNetworkName": {
//   "value": "anoa-eastus-platforms-hub-vnet"
// }
@description('The Hub Virtual Network Name for the Hub Network.')
param parHubVirtualNetworkName string

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

@description('The current date - do not override the default value')
param dateUtcNow string = utcNow('yyyy-MM-dd HH:mm:ss')

// APPLICATION GATEWAY PARAMETERS

@description('Optional. Specify the type of lock.')
param parAppGateway object

// LOGGING PARAMETERS
@description('Specify the Diagnostic Storage Account Name.')
param parDiagnosticStorageAccountName string

@description('[Free/Standard/Premium/PerNode/PerGB2018/Standalone] The SKU for the Log Analytics Workspace. It defaults to "PerGB2018". See https://docs.microsoft.com/en-us/azure/azure-monitor/logs/resource-manager-workspace for valid settings.')
param parLogAnalyticsWorkspaceName string

@description('Required. Name of the front end Public IP Address.')
param publicIPAddressName string

/*
  NAMING CONVENTION
  Here we define a naming conventions for resources.
  First, we take `parDeployEnvironment` and `parDeployEnvironment` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.
*/

var varResourceToken = 'resource_token'
var varNameToken = 'name_token'
var varNamingConvention = '${toLower(parRequired.orgPrefix)}-${toLower(parLocation)}-${toLower(parRequired.deployEnvironment)}-${varNameToken}-${toLower(varResourceToken)}'

// RESOURCE NAME CONVENTIONS WITH ABBREVIATIONS

var varAppGatewayNamingConvention = replace(varNamingConvention, varResourceToken, 'agw')

// APP SERVICE PLAN NAMES

var varHubName = 'hub'
var varAppGatewayResourceGroupName = replace(varAppGatewayNamingConvention, varNameToken, varHubName)

//=== TAGS === 

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}

@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-agw-tags--${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHubSubscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

module modAppGateway '../../../azresources/Modules/Microsoft.Network/applicationGateway/az.net.application.gateway.bicep' = {
  scope: resourceGroup(parHubSubscriptionId, parHubResourceGroup)
  name: 'deploy-agw-${parDeploymentNameSuffix}'
  params: {
    applicationGatewayName: varAppGatewayResourceGroupName
    location: parLocation
    webApplicationFirewallConfiguration: parAppGateway.webApplicationFirewallConfiguration
    sku: parAppGateway.sku
    gatewayIPConfigurations: [
      {
        name: '${varAppGatewayResourceGroupName}-IpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', parHubVirtualNetworkName, 'myAGSubnet')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: '${varAppGatewayResourceGroupName}-FrontendIP'
        properties: {
          privateIPAllocationMethod: parAppGateway.frontendIPConfigurations.privateIPAllocationMethod
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${publicIPAddressName}0')
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: '${varAppGatewayResourceGroupName}-BackendPool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: '${varAppGatewayResourceGroupName}-HTTPSetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: '${varAppGatewayResourceGroupName}-Listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', varAppGatewayResourceGroupName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', varAppGatewayResourceGroupName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
  }
}

output outAppGatewayName string = modAppGateway.name
output outAppGatewayId string = modAppGateway.outputs.resourceId
