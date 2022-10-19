@description('The name for the parent private link scope.')
param privateLinkScopeName string

@description('The name for the private endpoint connection.')
param name string

@description('The name of Private endpoint which the connection belongs to.')
param privateEndpointName string

resource privateLinkScope 'Microsoft.HybridCompute/privatelinkscopes@2022-03-10' existing = {
  name: privateLinkScopeName
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' existing = {
  name: privateEndpointName
}

resource privateEndpointConnection 'Microsoft.HybridCompute/privateLinkScopes/privateEndpointConnections@2022-05-10-preview' = {
  name: name
  parent: privateLinkScope
  properties: {
    privateEndpoint: {
      id: privateEndpoint.id
    }
  }
}

output id string = privateEndpointConnection.id
output name string = privateEndpointConnection.name
