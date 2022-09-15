@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param mobileNetworkName string

@description('The name of the data network')
param dataNetworkName string = 'internet'

resource mobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = {
  name: mobileNetworkName  
}

resource dataNetwork 'Microsoft.MobileNetwork/mobileNetworks/dataNetworks@2022-04-01-preview' = {
  parent: mobileNetwork
  name: dataNetworkName
  location: location
  properties: {}
}

output id string = dataNetwork.id
output name string = dataNetwork.name
output location string = dataNetwork.location
