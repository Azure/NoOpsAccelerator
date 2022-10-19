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

@description('Management Group varScope for the policy assignment.')
param parPolicyAssignmentManagementGroupId string

@allowed([
  'Default'
  'DoNotEnforce'
])
@description('Policy set assignment enforcement mode.  Possible values are { Default, DoNotEnforce }.  Default value:  Default')
param parEnforcementMode string = 'Default'

@description('Log Analytics Workspace Data Retention in days.')
param parRequiredRetentionDays string

// Telemetry - Azure customer usage attribution
// Reference:  https://docs.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution
var telemetry = json(loadTextContent('../../../../azresources/Modules/Global/telemetry.json'))
module telemetryCustomerUsageAttribution '../../../../azresources//Modules/Global/partnerUsageAttribution/customer-usage-attribution-management-group.bicep' = if (telemetry.customerUsageAttribution.enabled) {
  name: 'pid-${telemetry.customerUsageAttribution.modules.policy}-fedramp'
}

var varPolicyId = 'e95f5a9f-57ad-4d03-bb0b-b1d16db93693' // FedRAMP Moderate
var varAssignmentName = 'FedRAMP Moderate'

var varPolicyScopedId = resourceId('Microsoft.Authorization/policySetDefinitions', varPolicyId)


// Policy Assignment
module modPolicySetAssignment '../../../../azresources/Modules/Microsoft.Authorization/policyAssignments/managementGroup/az.auth.policy.set.assignment.mg.bicep' = {
  name: 'fedramp-m-${uniqueString('fedramp-moderate-',parPolicyAssignmentManagementGroupId)}'
  scope: managementGroup()
  params: {
    name: varAssignmentName
    policyDefinitionId: varPolicyScopedId
    enforcementMode: parEnforcementMode
    displayName: varAssignmentName
    managementGroupId: parPolicyAssignmentManagementGroupId
    parameters: {
      requiredRetentionDays: {
        value: parRequiredRetentionDays
      }
    }
    location: parLocation
    identity: 'SystemAssigned'
    roleDefinitionIds:  [
      '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    ]
  }
}
