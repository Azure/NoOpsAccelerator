@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param name string

@description('The mobile country code for the private mobile network')
param mobileCountryCode string = '001'

@description('The mobile network code for the private mobile network')
param mobileNetworkCode string = '01'

@description('Optional. Tags of the resource.')
param tags object = {}

resource mobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    publicLandMobileNetworkIdentifier: {
      mcc: mobileCountryCode
      mnc: mobileNetworkCode
    }
  }
}

output id string = mobileNetwork.id
output name string = mobileNetwork.name
output location string = mobileNetwork.location
