@description('Region where the Mobile Network will be deployed (must match the resource group region)')
param location string = resourceGroup().location

@description('The name for the private mobile network')
param name string

param simGroups array

param sims array

param dataNetworks array

param packetCoreDataPlanes array

param slices array

param services array

param simPolicies array

param packetCoreControlPlanes array

param deploymentid string = substring(uniqueString(utcNow()),0,6)

module mobileNetwork 'mobileNetworks/az.mobilenet.mobile.network.bicep' = {
  name: 'deploy-mobilenetwork-${name}-${deploymentid}'
  params: {
    name: name
    location: location
  }
}

module resSimGroups 'simGroups/az.mobilenet.sim.group.bicep' = [for simGroup in simGroups: {
  name: 'deploy-mobilenetwork-${simGroup.name}-${deploymentid}'  
  params:{
    mobileNetworkName: simGroup.mobileNetworkName
    location: simGroup.location
  }
}]

module resSims 'sims/az.mobilenet.sim.bicep' = [for sim in sims: {
  name: 'deploy-mobilenetwork-${sim.name}-${deploymentid}'
  params:{
    mobileNetworkName: sim.mobileNetworkName
    location: sim.location
  }
}]

module resDataNetwork 'mobileNetworks/dataNetworks/az.mobilenet.data.network.bicep' = [for dataNetwork in dataNetworks: {
  name: 'deploy-datanetwork-${dataNetwork.name}-${deploymentid}'
  params:{
    mobileNetworkName: dataNetwork.mobileNetworkName
    location: dataNetwork.location
  }  
}]

module resPacketCoreDataPlanes 'packetCoreControlPlanes/packetCoreDataPlanes/az.mobilenet.packet.core.data.plane.bicep' = [for packetCoreDataPlane in packetCoreDataPlanes: {
  name: 'deploy-packetCoreDataPlane-${packetCoreDataPlane.name}-${deploymentid}'
  params:{
    location: packetCoreDataPlane.location
  }  
}]

module resSlices 'mobileNetworks/slices/az.mobilenet.slice.bicep' = [for slice in slices: {
  name: 'deploy-slice-${slice.name}-${deploymentid}'
  params:{
    mobileNetworkName: slice.mobileNetworkName
    location: slice.location
  }
}]

module resServices 'mobileNetworks/services/az.mobilenet.service.bicep' = [for service in services: {
  name: 'deploy-service-${service.name}-${deploymentid}'
  params:{
    mobileNetworkName: service.mobileNetworkName
    location: service.location
  }
}]

module resSimPolicies 'mobileNetworks/simPolicies/az.mobilenet.sim.policy.bicep' = [for simPolicy in simPolicies: {
  name: 'deploy-simPolicy-${simPolicy.name}-${deploymentid}'
  params:{
    mobileNetworkName: simPolicy.mobileNetworkName
    location: simPolicy.location
  }
}]

module resPacketCoreControlPlanes 'packetCoreControlPlanes/az.mobilenet.packet.core.control.plane.bicep' = [for packetCoreControlPlane in packetCoreControlPlanes: {
  name: 'deploy-packetCoreControlPlane-${packetCoreControlPlane.name}-${deploymentid}'
  params:{
    mobileNetworkName: packetCoreControlPlane.mobileNetworkName
    location: packetCoreControlPlane.location
  }
}]

output id string = mobileNetwork.outputs.id
output name string = mobileNetwork.outputs.name
output location string = mobileNetwork.outputs.location
