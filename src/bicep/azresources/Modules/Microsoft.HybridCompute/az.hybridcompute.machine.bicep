@description('Region where the ARC enabled machine will be deployed (must match the resource group region).')
param location string = resourceGroup().location

@description('The name for the ARC enabled machine.')
param name string

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Identity for the resource(ex. SystemAssigned).')
param identity object = {}

@description('Optional. Public Key that the client provides to be used during initial resource onboarding.')
param clientPublicKey string 

@description('Optional. The metadata of the cloud environment (Azure/GCP/AWS/OCI...).')
param cloudMetadata object = {}

@description('Optional. Metadata pertaining to the geographic location of the resource.')
param locationData object = {}

@description('Optional. Specifies whether any MS SQL instance is discovered on the machine.')
param mssqlDiscovered string = ''

@description('Optional. Specifies the operating system settings for the hybrid machine.')
param osProfile object = {}

@description('Optional. The type of Operating System (windows/linux).')
param osType string = ''

@description('Optional. The resource id of the parent cluster (Azure HCI) this machine is assigned to, if any.')
param parentClusterResourceId string = ''

@description('Optional. The resource id of the private link scope this machine is assigned to, if any.')
param privateLinkScopeResourceId string = ''

@description('Optional. Statuses of dependent services that are reported back to ARM.')
param serviceStatuses object = {}

resource machine 'Microsoft.HybridCompute/machines@2022-05-10-preview' = {
  name: name
  location: location
  tags: tags
  identity: identity
  properties: {
    clientPublicKey: clientPublicKey
    cloudMetadata: cloudMetadata
    locationData: locationData
    mssqlDiscovered: mssqlDiscovered
    osProfile: osProfile
    osType: osType
    parentClusterResourceId: parentClusterResourceId
    privateLinkScopeResourceId: privateLinkScopeResourceId
    serviceStatuses: serviceStatuses
  }
}

output id string = machine.id
output name string = machine.name
output location string = machine.location
