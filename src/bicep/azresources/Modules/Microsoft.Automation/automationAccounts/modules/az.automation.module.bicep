// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

@description('Required. Name of the Automation Account module.')
param name string

@description('Conditional. The name of the parent Automation Account. Required if the template is used in a standalone deployment.')
param automationAccountName string

@description('Required. Module package URI, e.g. https://www.powershellgallery.com/api/v2/package.')
param uri string

@description('Optional. Module version or specify latest to get the latest version.')
param version string = 'latest'

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the Automation Account resource.')
param tags object = {}

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' existing = {
  name: automationAccountName
}

resource module 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: name
  parent: automationAccount
  location: location
  tags: tags
  properties: {
    contentLink: {
      uri: version != 'latest' ? '${uri}/${name}/${version}' : '${uri}/${name}'
      version: version != 'latest' ? version : null
    }
  }
}

@description('The name of the deployed module.')
output name string = module.name

@description('The resource ID of the deployed module.')
output resourceId string = module.id

@description('The resource group of the deployed module.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = module.location
