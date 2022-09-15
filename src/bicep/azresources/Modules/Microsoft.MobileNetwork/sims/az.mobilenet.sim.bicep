@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param mobileNetworkName string = ''

@description('The name of the SIM policy')
param simPolicyName string = 'Default-policy'

@description('The name for the SIM.')
param simName string = ''

@description('The Integrated Circuit Card ID (ICC Id) for the SIM.')
param integratedCircuitCardIdentifier string = ''

@description('The International Mobile Subscriber Identity (IMSI) for the SIM.')
param internationalMobileSubscriberIdentity string = ''

@description('The authenticationKey for the SIM.')
param authenticationKey string = ''

@description('The Opc value for the SIM.')
param operatorKeyCode string = ''

@description('An optional free-form text field that can be used to record the device type this sim is associated with, for example Video camera. The Azure portal allows Sims to be grouped and filtered based on this value.')
param deviceType string = ''

@description('An array containing Static IP Configurations.  See https://docs.microsoft.com/en-us/azure/templates/microsoft.mobilenetwork/simgroups/sims?pivots=deployment-language-bicep for a full description of the required properties and their format.')
param staticIpConfiguration array = []

resource mobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = if(!empty(mobileNetworkName)) {
  name: mobileNetworkName  
}

resource simPolicy 'Microsoft.MobileNetwork/mobileNetworks/simPolicies@2022-04-01-preview' existing = if(!empty(simPolicyName)) {
  parent: mobileNetwork
  name: simPolicyName  
}

resource simResource 'Microsoft.MobileNetwork/sims@2022-03-01-preview' = {
  name: simName
  location: location
  properties: {
    integratedCircuitCardIdentifier: integratedCircuitCardIdentifier
    internationalMobileSubscriberIdentity: internationalMobileSubscriberIdentity
    authenticationKey: authenticationKey
    operatorKeyCode: operatorKeyCode
    deviceType: deviceType
    simPolicy: (!empty(simPolicyName)) ? {
      id: simPolicy.id
    } : null
    staticIpConfiguration: staticIpConfiguration
  }
}

output id string = simResource.id
output name string = simResource.name
output location string = simResource.location
