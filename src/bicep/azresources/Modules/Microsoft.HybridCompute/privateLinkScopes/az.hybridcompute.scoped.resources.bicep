@description('The name for the parent private link scope.')
param privateLinkScopeName string

@description('The name for the scoped resource.')
param name string

@description('The resource id of the scoped Azure monitor resource.')
param linkedResourceId string

resource privateLinkScope 'Microsoft.HybridCompute/privateLinkScopes@2022-03-10' existing = {
  name: privateLinkScopeName
}

resource scopedResource 'Microsoft.HybridCompute/privateLinkScopes/scopedResources@2020-08-15-preview' = {
  name: name
  parent: privateLinkScope
  properties: {
    linkedResourceId: linkedResourceId
  }
}

output id string = scopedResource.id
output name string = scopedResource.name
