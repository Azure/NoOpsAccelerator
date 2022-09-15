@description('Region where the ARC enabled machine will be deployed (must match the resource group region).')
param location string = resourceGroup().location

@description('The name for the ARC enabled machine.')
param machineName string

@description('Optional. Tags of the resource.')
param tags object = {}

@description('The name for the machine extension.')
param name string

@description('Indicates whether the extension should use a newer minor version if one is available at deployment time. Once deployed, however, the extension will not upgrade minor versions unless redeployed, even with this property set to true.')
param autoUpgradeMinorVersion bool = true

@description('Indicates whether the extension should be automatically upgraded by the platform if there is a newer version available.')
param enableAutomaticUpgrade bool = true

@description('How the extension handler should be forced to update even if the extension configuration has not changed.')
param forceUpdateTag string = ''

@description('The extension can contain either protectedSettings or protectedSettingsFromKeyVault or no protected settings at all.')
param protectedSettings object = {}

@description('The name of the extension handler publisher.')
param publisher string = ''

@description('Json formatted public settings for the extension.')
param settings object = {}

@description('Specifies the type of the extension; an example is "CustomScriptExtension".')
param type string = ''

@description('Specifies the version of the script handler.')
param typeHandlerVersion string = ''


resource machine 'Microsoft.HybridCompute/machines@2022-05-10-preview' existing = {
  name: machineName
}

resource extension 'Microsoft.HybridCompute/machines/extensions@2022-05-10-preview' = {
  name: name
  location: location
  tags: tags
  parent: machine
  properties: {
    autoUpgradeMinorVersion: autoUpgradeMinorVersion
    enableAutomaticUpgrade: enableAutomaticUpgrade
    forceUpdateTag: forceUpdateTag
    protectedSettings: protectedSettings
    publisher: publisher
    settings: settings
    type: type
    typeHandlerVersion: typeHandlerVersion
  }
}

output id string = extension.id
output name string = extension.name
output location string = extension.location
