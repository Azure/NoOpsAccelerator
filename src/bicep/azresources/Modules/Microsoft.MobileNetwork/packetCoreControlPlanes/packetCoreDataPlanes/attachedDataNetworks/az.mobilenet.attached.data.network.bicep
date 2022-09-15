@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the site')
param siteName string = 'myExampleSite'

@description('The logical name of the user plane interface on the data network. In 5G networks this is called the N6 interface whereas in 4G networks this is called the SGi interface. This should match one of the interfaces configured on your Azure Stack Edge machine.')
param userPlaneDataInterfaceName string = ''

@description('The IP address of the user plane interface on the data network. In 5G networks this is called the N6 interface whereas in 4G networks this is called the SGi interface. Not required for AKS-HCI.')
param userPlaneDataInterfaceIpAddress string = ''

@description('The network address of the data subnet in CIDR notation')
param userPlaneDataInterfaceSubnet string = ''

@description('The data subnet default gateway')
param userPlaneDataInterfaceGateway string = ''

@description('The network address of the subnet from which dynamic IP addresses must be allocated to UEs, given in CIDR notation. Optional if userEquipmentStaticAddressPoolPrefix is specified. If both are specified, they must be the same size and not overlap.')
param userEquipmentAddressPoolPrefix string = ''

@description('The network address of the subnet from which static IP addresses must be allocated to UEs, given in CIDR notation. Optional if userEquipmentAddressPoolPrefix is specified. If both are specified, they must be the same size and not overlap.')
param userEquipmentStaticAddressPoolPrefix string = ''

@description('The name of the data network')
param dataNetworkName string = 'internet'

@description('Whether or not Network Address and Port Translation (NAPT) should be enabled for this data network')
@allowed([
  'Enabled'
  'Disabled'
])
param naptEnabled string

@description('A list of DNS servers that UEs on this data network will use')
param dnsAddresses array

resource packetCoreControlPlane 'Microsoft.MobileNetwork/packetCoreControlPlanes@2022-04-01-preview' existing = {
  name: siteName
}

resource packetCoreDataPlane 'Microsoft.MobileNetwork/packetCoreControlPlanes/packetCoreDataPlanes@2022-04-01-preview' existing = {
    name: siteName
    parent: packetCoreControlPlane
}
    
resource attachedDataNetwork 'Microsoft.MobileNetwork/packetCoreControlPlanes/packetCoreDataPlanes/attachedDataNetworks@2022-04-01-preview' = {
  parent: packetCoreDataPlane
  name: dataNetworkName
  location: location
  properties: {
    userPlaneDataInterface: {
      ipv4Address: userPlaneDataInterfaceIpAddress
      ipv4Subnet: userPlaneDataInterfaceSubnet
      ipv4Gateway: userPlaneDataInterfaceGateway
      name: userPlaneDataInterfaceName
    }
    userEquipmentAddressPoolPrefix: empty(userEquipmentAddressPoolPrefix) ? null : [
      userEquipmentAddressPoolPrefix
    ]
    userEquipmentStaticAddressPoolPrefix: empty(userEquipmentStaticAddressPoolPrefix) ? null : [
      userEquipmentStaticAddressPoolPrefix
    ]
    naptConfiguration: {
      enabled: naptEnabled
    }
    dnsAddresses: dnsAddresses
  }
}

output id string = attachedDataNetwork.id
output name string = attachedDataNetwork.name
output location string = attachedDataNetwork.location
