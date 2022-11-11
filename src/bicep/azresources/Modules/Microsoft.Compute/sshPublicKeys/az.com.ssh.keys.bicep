// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
@description('Required. The name of the image.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Tags of the resource.')
param publickey string = ''

resource key 'Microsoft.Compute/sshPublicKeys@2022-08-01' =  {
  name: name
  location: location
  tags: tags
  properties: {
    publicKey: publickey
  }
}

output sshPublicKeysId string = key.id
output sshPublicKeysName string = key.name
output sshPublicKeysLocation string = key.location
output sshPublicKeysTags object = key.tags
