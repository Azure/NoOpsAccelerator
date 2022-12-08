
// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Module to deploy the Microsoft Azure SecurityCenter to the Hub Network 
DESCRIPTION: The following components will be options in this deployment
              Microsoft Defender
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

targetScope = 'subscription'

// REQUIRED PARAMETERS

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

// MICROSOFT DEFENDER PARAMETERS

// Microsoft Defender for Cloud
// Example (JSON)
// -----------------------------
// "parSecurityCenter": {
//   "value": {
//       "alertNotifications": "Off",
//       "alertsToAdminsNotifications": "Off",
//       "emailSecurityContact": "anoa@microsoft.com",
//       "phoneSecurityContact": "5555555555"
//   }
// }
@description('Microsoft Defender for Cloud.  It includes email and phone.')
param parSecurityCenter object

// LOGGING PARAMETERS

// Logging Log Analytics Workspace Resource Id
// (JSON Parameter)
// ---------------------------
// "parLogAnalyticsWorkspaceResourceId": {
//   "value": "/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourcegroups/anoa-eastus-platforms-logging-rg/providers/microsoft.operationalinsights/workspaces/anoa-eastus-platforms-logging-log"
// }
@description('Log Analytics Workspace Resource Id Needed for Defender')
param parLogAnalyticsWorkspaceResourceId string

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

module modDefender '../../../azresources/Modules/Microsoft.Security/azureSecurityCenter/az.sec.center.bicep' = {
  name: 'set-sub-defender-${parLocation}-${parDeploymentNameSuffix}'
  params: {
    // Required parameters
    workspaceId: parLogAnalyticsWorkspaceResourceId
    // Non-required parameters
    securityContactProperties: {
      alertNotifications: parSecurityCenter.alertNotifications
      alertsToAdmins: parSecurityCenter.alertsToAdminsNotifications
      email: parSecurityCenter.emailSecurityContact
      phone:  parSecurityCenter.phoneSecurityContact 
    }
  }
}

