// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Overlay Example to deploy Bulit-In/Custom policy defintions/assignments to a existing enclave
DESCRIPTION: The following components will be options in this deployment
              * Policies
                * Bulit-In - Location
                * Bulit-In - NIST SP 800-53 R5
                * Bulit-In - FedRAMP Moderate
                * Custom - Compute Governance             
              
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

targetScope = 'managementGroup'

//REQUIRED PARAMETERS
param parPolicy object

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

// Telemetry - Azure customer usage attribution
// Reference:  https://docs.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution
var telemetry = json(loadTextContent('../../../azresources/Modules/Global/telemetry.json'))
module telemetryCustomerUsageAttribution '../../../azresources//Modules/Global/partnerUsageAttribution/customer-usage-attribution-management-group.bicep' = if (telemetry.customerUsageAttribution.enabled) {
  name: 'pid-${telemetry.customerUsageAttribution.modules.policy}-${uniqueString(parLocation)}'
}


// BUILT-IN POLICIES
//Location Policy
module polLocation '../../../azresources/Policy/builtin/assignments/location.bicep' = if (parPolicy.bulitInPolicy.policies[0].enabled) {
  name: 'LocationDefintionDeployment-${parDeploymentNameSuffix}'
  params: {
    parLocation: parLocation
    parPolicyAssignmentManagementGroupId: parPolicy.bulitInPolicy.policies[0].policyAssignmentManagementGroupId
    allowedLocations: parPolicy.bulitInPolicy.policies[0].allowedLocations
  }
}

//NIST SP 800-53 R5 Policy
module polNISTR5 '../../../azresources/Policy/builtin/assignments/policy-nist80053r5.bicep' = if (parPolicy.bulitInPolicy.policies[1].enabled) {
  name: 'NISTR5DefintionDeployment-${parDeploymentNameSuffix}'
  params: {
    parLocation: parLocation
    parPolicyAssignmentManagementGroupId: parPolicy.bulitInPolicy.policies[1].policyAssignmentManagementGroupId
    parRequiredRetentionDays: parPolicy.bulitInPolicy.policies[1].requiredRetentionDays
  }
}

//FedRAMP Moderate Policy
module polFedRAMPModerate '../../../azresources/Policy/builtin/assignments/policy-fedramp-moderate.bicep' = if (parPolicy.bulitInPolicy.policies[2].enabled) {
  name: 'FedRAMPModerateDefintionDeployment-${parDeploymentNameSuffix}'
  params: {
    parLocation: parLocation
    parPolicyAssignmentManagementGroupId: parPolicy.bulitInPolicy.policies[2].policyAssignmentManagementGroupId
    parRequiredRetentionDays: parPolicy.bulitInPolicy.policies[2].requiredRetentionDays
  }
}

// CUSTOM POLICIES DEFINITIONS
//Custom Compute Governance Policy Defintion
module polComputeDef '../../../azresources/Policy/custom/definitions/policySet/Compute.bicep' = if (parPolicy.customPolicy.policies[0].enabled) {
  name: 'ComputeDefDeploy-${parDeploymentNameSuffix}'
  params: {
    parPolicyDefinitionManagementGroupId: parPolicy.customPolicy.policies[0].policyDefinitionManagementGroupId
  }
}

//Custom Data Protection Governance Policy Defintion
module polDataProtectionAssignment '../../../azresources/Policy/custom/definitions/policySet/DataProtection.bicep' = if (parPolicy.customPolicy.policies[1].enabled) {
  name: 'DataDefDeploy-${parDeploymentNameSuffix}'
}

//Custom Identity Governance Policy Defintion
module polIdentityProtectionAssignment '../../../azresources/Policy/custom/definitions/policySet/Identity.bicep' = if (parPolicy.customPolicy.policies[2].enabled) {
  name: 'IdentityDefDeploy-${parDeploymentNameSuffix}'
  params: {
    policyDefinitionManagementGroupId: parPolicy.customPolicy.policies[2].policyDefinitionManagementGroupId
  }
}

//Custom Key Vault Governance Policy Defintion
module polKeyVaultProtectionAssignment '../../../azresources/Policy/custom/definitions/policySet/KeyVault.bicep' = if (parPolicy.customPolicy.policies[3].enabled) {
  name: 'KeyVaultDefDeploy-${parDeploymentNameSuffix}'
  params: {
    policyDefinitionManagementGroupId: parPolicy.customPolicy.policies[3].policyDefinitionManagementGroupId
  }
}

// CUSTOM POLICIES ASSIGNMENTS
//Custom Compute Governance Policy Assignment
module polComputeAssign '../../../azresources/Policy/custom/assignments/Compute.bicep' = if (parPolicy.customPolicy.policies[0].enabled) {
  name: 'ComputeDefDeploy-${parDeploymentNameSuffix}'
  params: {
    parLocation: parLocation
    parPolicyDefinitionManagementGroupId: parPolicy.customPolicy.policies[0].policyDefinitionManagementGroupId
    parPolicyAssignmentManagementGroupId:  parPolicy.customPolicy.policies[0].parPolicyAssignmentManagementGroupId
  }
}
