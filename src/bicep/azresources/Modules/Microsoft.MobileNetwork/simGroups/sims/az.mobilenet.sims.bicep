@description('The name for the private mobile network')
param mobileNetworkName string = ''

@description('The name of the SIM policy')
param simPolicyName string = 'Default-policy'

@description('The name for the SIM group.')
param simGroupName string = ''

@description('An array containing properties of the SIM(s) you wish to create. See [Provision proxy SIM(s)](https://docs.microsoft.com/en-gb/azure/private-5g-core/provision-sims-azure-portal) for a full description of the required properties and their format.')
param simResources array = []

@description('An array containing Static IP Configurations.  See https://docs.microsoft.com/en-us/azure/templates/microsoft.mobilenetwork/simgroups/sims?pivots=deployment-language-bicep for a full description of the required properties and their format.')
param staticIpConfiguration array = []

resource mobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = if(!empty(mobileNetworkName)) {
  name: mobileNetworkName  
}

resource simPolicy 'Microsoft.MobileNetwork/mobileNetworks/simPolicies@2022-04-01-preview' existing = if(!empty(simPolicyName)) {
  parent: mobileNetwork
  name: simPolicyName  
}

resource simGroupResource 'Microsoft.MobileNetwork/simGroups@2022-04-01-preview' existing = {
  name: simGroupName  
}

resource resSimResources 'Microsoft.MobileNetwork/simGroups/sims@2022-04-01-preview' = [for item in simResources: {
  parent: simGroupResource
  name: item.simName
  properties: {
    integratedCircuitCardIdentifier: item.integratedCircuitCardIdentifier
    internationalMobileSubscriberIdentity: item.internationalMobileSubscriberIdentity
    authenticationKey: item.authenticationKey
    operatorKeyCode: item.operatorKeyCode
    deviceType: item.deviceType
    simPolicy: (!empty(simPolicyName)) ? {
      id: simPolicy.id
    } : null
    staticIpConfiguration: staticIpConfiguration
  }
}]

output ids array = [for (simResource,i) in simResources: resSimResources[i].id]
output names array = [for (simResource,i) in simResources: resSimResources[i].name]
