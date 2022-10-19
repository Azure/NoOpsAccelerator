// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Example to deploy role defintions to a existing enclave.
DESCRIPTION: The following components will be options in this deployment
              * Roles
                * Custom - VM Operator
                * Custom - Platform Operations (PlatformOps)
                * Custom - Network Operations (NetOps)
                * Custom - Security Operations (SecOps)
                * Custom - Appilcation Operations (AppOps)
                * Custom - Landing Zone Application Owner
                * Custom - Landing Zone Subscription Owner
                * Custom - Storage Operator
              
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

targetScope = 'managementGroup'

// REQUIRED PARAMETERS
param parRoleDefinitionInfo object
param parAssignableScopeManagementGroupId string

param parLocation string = deployment().location

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

// Telemetry - Azure customer usage attribution
// Reference:  https://docs.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution
var telemetry = json(loadTextContent('../../azresources/Modules/Global/telemetry.json'))
module telemetryCustomerUsageAttribution '../../azresources//Modules/Global/partnerUsageAttribution/customer-usage-attribution-management-group.bicep' = if (telemetry.customerUsageAttribution.enabled) {
  name: 'pid-${telemetry.customerUsageAttribution.modules.roles}-${uniqueString(parLocation)}'
}

//module to trigger custom role vm_operator 
module role_definitions '../../azresources/Modules/Microsoft.Authorization/roleDefinitions/az.auth.role.definition.bicep' = [for (definitionInfo, i) in parRoleDefinitionInfo.definitions: {
  name: 'enclave-RoleDef-${i}-${parDeploymentNameSuffix}'
  params: {    
    location: parLocation
    roleName: definitionInfo.roleName
    actions: definitionInfo.actions
    description: definitionInfo.roleDescription
    managementGroupId: parAssignableScopeManagementGroupId   
  }
}]
