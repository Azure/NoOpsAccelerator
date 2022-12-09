targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //
@description('Optional. The location to deploy resources to.')
param location string = deployment().location

// =========== //
// Deployments //
// =========== //

// General resources
// =================
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

// ============== //
// Test Execution //
// ============== //
@batchSize(1)
module runner './testRunner.bicep' =  [for (scenario, i) in testScenarios: if (scenario.enabled) {
  
  name: 'execute-runner-scenario-${i + 1}'
  scope: subscription()
  params: {
    parLocation: location
  
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
  }
}]
