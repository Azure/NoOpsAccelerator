// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

targetScope = 'subscription'

@description('Location for the deployment.')
param location string = deployment().location

var testScenarios = [
  {
    enabled: true
    subscriptionId: subscription().subscriptionId
    enableResourceLocks: false
    enablePrivateDnsZones: true
    firewallEnabled: true
    sentinelEnabled: true  
    firewallEnableStorage: false
    firewallStoragePrincipalId: ''
    hubEnableStorage: false
    hubStoragePrincipalId: ''
    opsEnableStorage: false
    opsStoragePrincipalId: ''
    loggingEnableStorage: false
    loggingStoragePrincipalId: ''
    networkArtifactsEnabled: false
    networkArtifactsEnableStorage: false
    networkArtifactsStoragePrincipalId: ''
    networkArtifactsTenantId: ''
    networkArtifactsObjectId: ''
    enableRemoteAccess: true
    enableRemoteAccessLinux: true
    enableRemoteAccessWindows: true 
    enableDefender: true
  }  
]

var testRunnerCleanupAfterDeployment = true

var tags = {
  ClientOrganization: 'tbd'
  CostCenter: 'tbd'
  DataSensitivity: 'tbd'
  ProjectContact: 'tbd'
  ProjectName: 'tbd'
  TechnicalContact: 'tbd'
}

resource rgTestHarnessInfraAssets 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'test-harness-infra-assets'
  location: location
  tags: tags
}

resource rgTestHarnessSupportingAssets 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'test-harness-supporting-assets'
  location: location
  tags: tags
}

module rgTestHarnessManagedIdentity '../../../../azresources/Modules/Microsoft.ManagedIdentity/userAssignedIdentities/az.managed.identity.user.assigned.bicep' = {
  scope: rgTestHarnessInfraAssets
  name: 'deploy-test-harness-managed-identity'
  params: {
    name: 'test-harness-hub1spoke-lz-managed-identity'
    location: location
  }
}

module rgTestHarnessManagedIdentityRBAC '../../../../azresources/Modules/Microsoft.Authorization/roleAssignments/subscription/az.auth.role.assignment.sub.bicep' = {
  name: 'rbac-ds-${rgTestHarnessSupportingAssets.name}'
  params: {
     // Owner - this role is cleaned up as part of this deployment
    principalId: rgTestHarnessManagedIdentity.outputs.principalId
    roleDefinitionIdOrName: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    rgTestHarnessManagedIdentity
  ]
}

@batchSize(1)
module runner 'test-runner.bicep' =  [for (scenario, i) in testScenarios: if (scenario.enabled) {
  dependsOn: [
    rgTestHarnessManagedIdentityRBAC
  ]

  name: 'execute-runner-scenario-${i + 1}'
  scope: subscription()
  params: {
    parLocation: location

    parDeploymentScriptIdentityId: rgTestHarnessManagedIdentity.outputs.resourceId
    parDeploymentScriptResourceGroupName: rgTestHarnessInfraAssets.name
   
    parSubscriptionId: scenario.subscriptionId
    parEnableResourceLocks: scenario.enableResourceLocks
    parFirewallEnabled: scenario.firewallEnabled
    parSentinelEnabled: scenario.sentinelEnabled
    parFirewallEnableStorage: scenario.firewallEnableStorage
    parFirewallStoragePrincipalId: scenario.firewallStoragePrincipalId
    parHubEnableStorage: scenario.hubEnableStorage
    parHubStoragePrincipalId: scenario.hubStoragePrincipalId
    parHubEnablePrivateDnsZones: scenario.enablePrivateDnsZones
    parOpsEnableStorage: scenario.opsEnableStorage
    parOpsStoragePrincipalId: scenario.opsStoragePrincipalId
    parLoggingEnableStorage: scenario.loggingEnableStorage
    parLoggingStoragePrincipalId: scenario.loggingStoragePrincipalId
    parNetworkArtifactsEnabled: scenario.networkArtifactsEnabled
    parNetworkArtifactsEnableStorage: scenario.networkArtifactsEnableStorage
    parNetworkArtifactsStoragePrincipalId: scenario.networkArtifactsStoragePrincipalId
    parNetworkArtifactsTenantId: scenario.networkArtifactsTenantId
    parNetworkArtifactsObjectId: scenario.networkArtifactsObjectId
    parEnableRemoteAccess: scenario.enableRemoteAccess
    parEnableRemoteAccessLinux: scenario.enableRemoteAccessLinux
    parEnableRemoteAccessWindows: scenario.enableRemoteAccessWindows
    parEnableDefender: scenario.enableDefender
  
    parTestRunnerCleanupAfterDeployment: testRunnerCleanupAfterDeployment
    
  }
}]

var cleanUpScript = '''
  az account set -s {0}
  echo 'Delete Test Harness Supporting Assets'
  az group delete --name {1} --yes
  echo 'Delete Role Assignment for Test Harness Managed Identity'
  az role assignment delete --assignee {2} --scope {3}
'''

module harnessCleanup '../../../../azresources/Modules/Microsoft.Resources/deploymentScripts/az.resources.deployment.scripts.bicep' = {
  dependsOn: [
    rgTestHarnessManagedIdentityRBAC
    runner
  ]

  scope: rgTestHarnessInfraAssets 
  name: 'execute-cleanup-test-harness'
  params: { 
    name: 'cleanup-test-harness'
    scriptContent: format(cleanUpScript, subscription().subscriptionId, rgTestHarnessSupportingAssets.name, rgTestHarnessManagedIdentity.outputs.principalId, subscription().id)
    userAssignedIdentities: {
      '${rgTestHarnessManagedIdentity.outputs.resourceId}': {}
    }
    location: location
  }
}
