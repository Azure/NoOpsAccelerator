// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Module Example to deploy the Service Health Alerts.
DESCRIPTION: The following components will be options in this deployment
              * Service Health Alert
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

targetScope = 'subscription' //Deploying at Subscription scope to allow resource groups to be created and resources in one deployment

// REQUIRED PARAMETERS

@description('Prefix value which will be prepended to all resource names. Default: anoa')
param parOrgPrefix string = 'anoa'

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

@description('The ANOA template version')
@minLength(3)
param parTemplateVersion string = '1.0'

@minLength(3)
@maxLength(15)
@description('A suffix, 3 to 15 characters in length, to append to resource names (e.g. "dev", "test", "prod", "platforms"). It defaults to "platforms".')
param parDeployEnvironment string = 'platforms'

// Service Health
// Example (JSON)
// -----------------------------
// "serviceHealthAlerts": {
//   "value": {
//     "incidentTypes": [ "Incident", "Security", "Maintenance", "Information", "ActionRequired" ],
//     "regions": [ "Global", "East US", "West US" ],
//     "alertRuleName": "ALZ alert rule",
//     "alertRuleDescription": "Alert rule for Azure Landing Zone"
//     "actionGroupId": '/subscriptions/<<subscriptionId>>/resourceGroups/validation-rg/providers/microsoft.insights/actiongroups/adp-<<namePrefix>>-az-ag-x-001'
//   }
// }
@description('The object of the Service Health alerts')
param parServiceHealthAlerts object = {}

// SUBSCRIPTIONS PARAMETERS

// Target Resource Group Name
// (JSON Parameter)
// ---------------------------
// "parTargetResourceGroup": {
//   "value": "anoa-eastus-platforms-hub-rg"
// }
@description('The name of the resource group in which the services will be deployed. If unchanged or not specified, the NoOps Accelerator will create an resource group to be used.')
param parTargetResourceGroup string = ''

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

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

// SERVICE HEALTH NAMES

var varServiceHealthName = 'ServiceHealth'
var varServiceHealtResourceGroupName = replace(varResourceGroupNamingConvention, varNameToken, varServiceHealthName)

var incidentTypesProperty = [for incidentType in parServiceHealthAlerts.incidentTypes: {
  field: 'properties.incidentType'
  equals: incidentType
}]

//=== TAGS === 

@description('Resource group tags')
module modTags '../../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'service-health-tags-${parDeploymentNameSuffix}'
  params: {
    resourceGroupName: rgServiceHealth.name
    tags: {
      hostName: parDeployEnvironment
      regionName: parLocation
      templateVersion: parTemplateVersion
      applicationName: 'serviceHealthAlerts'
      organizationName: parOrgPrefix
    }

  }
}

// SERVICE HEALTH ALERTS

// Create Service Health resource group for managing alerts and action groups
resource rgServiceHealth 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: (!empty(parTargetResourceGroup)) ? parTargetResourceGroup : varServiceHealtResourceGroupName
  location: parLocation
}

// Create Service Health alerts
module modServiceHealthAlerts '../../../azresources/Modules/Microsoft.Insights/activityLogAlerts/az.insights.activity.log.alert.bicep' = {
  name: 'deploy-service-health-${parLocation}-${parDeploymentNameSuffix}'
  scope: rgServiceHealth
  params: {
    location: parLocation
    conditions: [
      {
        allOf: [
          {
            field: 'category'
            equals: 'ServiceHealth'
          }
          {
            anyOf: (!empty(parServiceHealthAlerts)) ? incidentTypesProperty : []
    
          }
          {
            field: 'properties.impactedServices[*].ImpactedRegions[*].RegionName'
            containsAny: (!empty(parServiceHealthAlerts)) ? parServiceHealthAlerts.regions : []
          }
        ]
      }
    ]
    name: (!empty(parServiceHealthAlerts)) ? parServiceHealthAlerts.alertRuleName : ''
    alertDescription: (!empty(parServiceHealthAlerts)) ? parServiceHealthAlerts.alertRuleDescription : ''
    enabled: true
    actions: [
      {
        actionGroupId: parServiceHealthAlerts.actionGroupId
      }
    ]
  }
}
