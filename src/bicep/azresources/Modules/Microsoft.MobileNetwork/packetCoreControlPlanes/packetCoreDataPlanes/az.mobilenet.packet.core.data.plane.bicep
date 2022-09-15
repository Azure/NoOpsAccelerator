@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the site')
param siteName string = 'myExampleSite'

@description('The logical name of the user plane interface on the access network. In 5G networks this is called the N3 interface whereas in 4G networks this is called the S1-U interface. This should match one of the interfaces configured on your Azure Stack Edge machine.')
param userPlaneAccessInterfaceName string = ''

@description('The IP address of the user plane interface on the access network. In 5G networks this is called the N3 interface whereas in 4G networks this is called the S1-U interface. Not required for AKS-HCI.')
param userPlaneAccessInterfaceIpAddress string = ''

@description('The network address of the access subnet in CIDR notation')
param accessSubnet string = ''

@description('The access subnet default gateway')
param accessGateway string = ''

resource packetCoreControlPlane 'Microsoft.MobileNetwork/packetCoreControlPlanes@2022-04-01-preview' existing = {
  name: siteName
}

resource packetCoreDataPlane 'Microsoft.MobileNetwork/packetCoreControlPlanes/packetCoreDataPlanes@2022-04-01-preview' = {
  parent: packetCoreControlPlane
  name: siteName
  location: location
  properties: {
    userPlaneAccessInterface: {
      ipv4Address: userPlaneAccessInterfaceIpAddress
      ipv4Subnet: accessSubnet
      ipv4Gateway: accessGateway
      name: userPlaneAccessInterfaceName
    }
  }
}

output id string = packetCoreDataPlane.id
output name string = packetCoreDataPlane.name
output location string = packetCoreDataPlane.location

