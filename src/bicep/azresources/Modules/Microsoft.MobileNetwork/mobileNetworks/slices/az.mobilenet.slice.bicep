@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param mobileNetworkName string

@description('The name of the slice')
param sliceName string = 'slice-1'

@description('The slice differentiator of the slice')
param sd string = ''

@description('The Slice Service Type (SST) of the slice')
param sst int = 1

resource mobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = {
  name: mobileNetworkName  
}

resource slice 'Microsoft.MobileNetwork/mobileNetworks/slices@2022-04-01-preview' = {
  parent: mobileNetwork
  name: sliceName
  location: location
  properties: {
    snssai: {
      sd: sd
      sst: sst
    }
  }
}

output id string = slice.id
output name string = slice.name
output location string = slice.location
