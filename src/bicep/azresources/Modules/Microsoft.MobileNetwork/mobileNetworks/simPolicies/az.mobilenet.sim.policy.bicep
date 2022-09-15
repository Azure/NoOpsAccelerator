@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param mobileNetworkName string

@description('The name of the service')
param allowedServiceNames array = [
  'Allow-all-traffic'
]

@description('The name of the SIM policy')
param simPolicyName string = 'Default-policy'

@description('The name of the slice')
param defaultSliceName string = 'slice-1'

@description('The name of the data network')
param dataNetworkName string = 'internet'

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Aggregate maximum uplink bit rate across all non-GBR QoS flows of all PDU sessions of a given UE.')
param ueAmbr_uplink string = '2 Gbps'

@description('Aggregate maximum downlink bit rate across all non-GBR QoS flows of all PDU sessions of a given UE.')
param ueAmbr_downlink string = '2 Gbps'

@description('Aggregate maximum uplink bit rate across all non-GBR QoS flows of a given PDU session.')
param sessionAmbr_uplink string = '2 Gbps'

@description('Aggregate maximum downlink bit rate across all non-GBR QoS flows of a given PDU session.')
param sessionAmbr_downlink string = '2 Gbps'

resource mobileNetwork 'Microsoft.MobileNetwork/mobileNetworks@2022-04-01-preview' existing = {
  name: mobileNetworkName  
}

resource dataNetwork 'Microsoft.MobileNetwork/mobileNetworks/dataNetworks@2022-04-01-preview' existing = {
  parent: mobileNetwork
  name: dataNetworkName
}

resource slice 'Microsoft.MobileNetwork/mobileNetworks/slices@2022-04-01-preview' existing = {
  parent: mobileNetwork
  name: defaultSliceName
}

resource services 'Microsoft.MobileNetwork/mobileNetworks/services@2022-04-01-preview' existing = [for serviceName in allowedServiceNames: {
  parent: mobileNetwork
  name: serviceName
}]

resource simPolicy 'Microsoft.MobileNetwork/mobileNetworks/simPolicies@2022-04-01-preview' = {
  parent: mobileNetwork
  name: simPolicyName
  location: location
  tags: tags
  properties: {
    ueAmbr: {
      uplink: ueAmbr_uplink
      downlink: ueAmbr_downlink
    }
    defaultSlice: {
      id: slice.id
    }    
    sliceConfigurations: [
      {
        slice: {
          id: slice.id
        }
        defaultDataNetwork: {
          id: dataNetwork.id
        }
        dataNetworkConfigurations: [
          {
            dataNetwork: {
              id: dataNetwork.id
            }
            sessionAmbr: {
              uplink: sessionAmbr_uplink
              downlink: sessionAmbr_downlink
            }
            allowedServices: [ for (serviceName,i) in allowedServiceNames:{ 
                id: services[i].id
            }]
          }
        ]
      }
    ]
  }
}
