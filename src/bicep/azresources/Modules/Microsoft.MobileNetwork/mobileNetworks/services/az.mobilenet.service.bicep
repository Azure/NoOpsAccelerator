@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param mobileNetworkName string

@description('The name of the service')
param serviceName string = 'Allow-all-traffic'

@description('The service precedence of the service')
param servicePrecedence int = 253

@description('The Policy and Charging Control (PCC) rules of the service')
param pccRules array = [
  {
    ruleName: 'All-traffic'
    rulePrecedence: 253
    trafficControl: 'Enabled'
    serviceDataFlowTemplates: [
      {
        templateName: 'Any-traffic'
        protocol: [
          'ip'
        ]
        direction: 'Bidirectional'
        remoteIpList: [
          'any'
        ]
      }
    ]
  }
]

resource mobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = {
  name: mobileNetworkName  
}

resource service 'Microsoft.MobileNetwork/mobileNetworks/services@2022-04-01-preview' = {
  parent: mobileNetwork
  name: serviceName
  location: location
  properties: {
    servicePrecedence: servicePrecedence
    pccRules: pccRules
  }
}

output id string = service.id
output name string = service.name
output location string = service.location
