@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param mobileNetworkName string

@description('The name for the site')
param siteName string = 'myExampleSite'

@description('The platform type where packet core is deployed.')
@allowed([
  'AKS-HCI'
  'BaseVM'
])
param platformType string = 'AKS-HCI'

@description('The name of the control plane interface on the access network. In 5G networks this is called the N2 interface whereas in 4G networks this is called the S1-MME interface. This should match one of the interfaces configured on your Azure Stack Edge machine.')
param controlPlaneAccessInterfaceName string = ''

@description('The IP address of the control plane interface on the access network. In 5G networks this is called the N2 interface whereas in 4G networks this is called the S1-MME interface.')
param controlPlaneAccessIpAddress string = ''

@description('The network address of the access subnet in CIDR notation')
param accessSubnet string = ''

@description('The access subnet default gateway')
param accessGateway string = ''

@description('The mode in which the packet core instance will run')
param coreNetworkTechnology string = '5GC'

@description('The resource ID of the customLocation representing the ASE device where the packet core will be deployed. If this parameter is not specified then the 5G core will be created but will not be deployed to an ASE. [Collect custom location information](https://docs.microsoft.com/en-gb/azure/private-5g-core/collect-required-information-for-a-site#collect-custom-location-information) explains which value to specify here.')
param customLocation string = ''

@description('The sku for the packetCoreControlPlane.')
param sku string = 'EvaluationPackage'

resource mobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = {
  name: mobileNetworkName  
}

resource packetCoreControlPlane 'Microsoft.MobileNetwork/packetCoreControlPlanes@2022-04-01-preview' = {
  name: siteName
  location: location
  properties: {
    mobileNetwork: {
      id: mobileNetwork.id
    }
    sku: sku
    coreNetworkTechnology: coreNetworkTechnology
    platform: {
      type: platformType
      customLocation: empty(customLocation) ? null : {
        id: customLocation
      }
    }
    controlPlaneAccessInterface: {
      ipv4Address: controlPlaneAccessIpAddress
      ipv4Subnet: accessSubnet
      ipv4Gateway: accessGateway
      name: controlPlaneAccessInterfaceName
    }
  }
}

output id string = packetCoreControlPlane.id
output name string = packetCoreControlPlane.name
output location string = packetCoreControlPlane.location
