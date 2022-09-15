@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param mobileNetworkName string

@description('The name for the site')
param siteName string = 'myExampleSite'

@description('The names of packet core control planes to include as network functions for the site')
param packetCoreControlPlaneNames array = []

@description('The names of packet core data planes to include as network functions for the site')
param packetCoreDataPlaneNames array = []

var packetCoreControlPlaneIDs = [ for (packetCoreControlPlaneName,i) in packetCoreControlPlaneNames: {
  id: packetCoreControlPlanes[i].id
} ]

var packetCoreDataPlaneIDs = [ for (packetCoreDataPlaneName,i) in packetCoreDataPlaneNames: {
  id: packetCoreDataPlanes[i].id
} ]

var networkFunctions = concat(packetCoreControlPlaneIDs,packetCoreDataPlaneIDs)

resource mobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = {
  name: mobileNetworkName  
}

resource packetCoreControlPlanes 'Microsoft.MobileNetwork/packetCoreControlPlanes@2022-04-01-preview' existing = [for packetCoreControlPlaneName in packetCoreControlPlaneNames:{
  name: packetCoreControlPlaneName
}]

resource packetCoreDataPlanes 'Microsoft.MobileNetwork/packetCoreControlPlanes/packetCoreDataPlanes@2022-04-01-preview' existing = [for packetCoreDataPlaneName in packetCoreDataPlaneNames:{
  name: packetCoreDataPlaneName
}]

resource site 'Microsoft.MobileNetwork/mobileNetworks/sites@2022-04-01-preview' = {
  name: siteName
  parent: mobileNetwork
  location: location
  properties: {
    networkFunctions: networkFunctions
  }
}

output id string = site.id
output name string = site.name
output location string = site.location
