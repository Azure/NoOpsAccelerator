@description('Region where the ARC enabled machine will be deployed (must match the resource group region).')
param location string = resourceGroup().location

@description('The name for the private link scope.')
param name string

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Indicates whether machines associated with the private link scope can also use public Azure Arc service endpoints.')
param publicNetworkAccess string

resource privateLinkScope 'Microsoft.HybridCompute/privatelinkscopes@2022-03-10' = {
  name: name
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: publicNetworkAccess
  }
}

output id string = privateLinkScope.id
output name string = privateLinkScope.name
output location string = privateLinkScope.location
