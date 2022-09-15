@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param mobileNetworkName string = ''

@description('The name for the SIM group.')
param simGroupName string = ''

@description('A Key Vault Key url to encrypt the SIM data that belongs to this SIM group.')
param keyUrl string = ''

@description('Optional. Tags of the resource.')
param tags object = {}

resource mobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = if(!empty(mobileNetworkName)) {
  name: mobileNetworkName  
}

resource simGroupResource 'Microsoft.MobileNetwork/simGroups@2022-04-01-preview' = {
  name: empty(simGroupName) ? 'placeHolderForValidation' : simGroupName
  location: location
  tags: tags
  properties: {
    encryptionKey: (!empty(keyUrl)) ? {
      keyUrl: 'string'
    } : null
    mobileNetwork: (!empty(mobileNetworkName)) ? {
      id: mobileNetwork.id      
    } : null
  }
}

output id string = simGroupResource.id
output name string = simGroupResource.name
output location string = simGroupResource.location
