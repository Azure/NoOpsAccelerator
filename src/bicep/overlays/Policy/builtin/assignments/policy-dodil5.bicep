// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

targetScope = 'managementGroup'

@description('Location for the deployment.')
param parLocation string = deployment().location

@description('Management Group scope for the policy assignment.')
param parPolicyAssignmentManagementGroupId string

@allowed([
  'Default'
  'DoNotEnforce'
])
@description('Policy set assignment enforcement mode.  Possible values are { Default, DoNotEnforce }.  Default value:  Default')
param parEnforcementMode string = 'Default'

@description('Log Analytics Resource Id to integrate Microsoft Defender for Cloud.')
param parLogAnalyticsWorkspaceId string

@description('List of members that should be excluded from Windows VM Administrator Group.')
param parListOfMembersToExcludeFromWindowsVMAdministratorsGroup string

@description('List of members that should be included in Windows VM Administrator Group.')
param parListOfMembersToIncludeInWindowsVMAdministratorsGroup string

var varPolicyId = 'f9a961fa-3241-4b20-adc4-bbf8ad9d7197' // DoD Impact Level 5 (Azure Government) /providers/Microsoft.Authorization/policySetDefinitions/f9a961fa-3241-4b20-adc4-bbf8ad9d7197
var varAssignmentName = 'DoD Impact Level 5 (Azure Government)'

var varPolicyScopedId = resourceId('Microsoft.Authorization/policySetDefinitions', varPolicyId)

// Telemetry - Azure customer usage attribution
// Reference:  https://docs.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution
var telemetry = json(loadTextContent('../../../../azresources/Modules/Global/telemetry.json'))
module telemetryCustomerUsageAttribution '../../../../azresources//Modules/Global/partnerUsageAttribution/customer-usage-attribution-management-group.bicep' = if (telemetry.customerUsageAttribution.enabled) {
  name: 'pid-${telemetry.customerUsageAttribution.modules.policy}-dod-il5'
}

// Policy Assignment
module modPolicySetAssignment '../../../../azresources/Modules/Microsoft.Authorization/policyAssignments/managementGroup/az.auth.policy.set.assignment.mg.bicep' = {
  name: 'dodil5-${uniqueString('dod-il5-',parPolicyAssignmentManagementGroupId)}'
  scope: managementGroup()
  params: {
    name: varAssignmentName
    policyDefinitionId: varPolicyScopedId
    enforcementMode: parEnforcementMode
    displayName: varAssignmentName
    managementGroupId: parPolicyAssignmentManagementGroupId
    parameters: {
      requiredRetentionDays: {
        logAnalyticsWorkspaceIdforVMReporting: {
          value: parLogAnalyticsWorkspaceId
         }
         listOfMembersToExcludeFromWindowsVMAdministratorsGroup: {
          value: parListOfMembersToExcludeFromWindowsVMAdministratorsGroup
         }
         listOfMembersToIncludeInWindowsVMAdministratorsGroup: {
          value: parListOfMembersToIncludeInWindowsVMAdministratorsGroup
         }
      }
    }
    location: parLocation
    identity: 'SystemAssigned'
    roleDefinitionIds:  [
      '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    ]
  }
}
