# Module:   NoOps Accelerator - Hub Network Peering

## Authored & Tested With

* [azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) version 2.37.0
* bicep cli version v0.9.1
* [bicep](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) v0.6.18 vscode extension

## Overview

This module defines Hub Network Peering based on the recommendations from the Azure Mission Landing Zone Conceptual Architecture.  

Module deploys the following resources:

* Virtual Network (VNet) Peering

## Required Parameters

The module requires the following inputs:

| Parameter                         | Type   | Default                                                                                              | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Required                   | Example                                        |
 | --------------------------------- | ------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- | ---------------------------------------------- |
| parHubVirtualNetworkName                       | string | `None`                                                                           | Provide the Hub Virtual Network Name   | Yes                          | `anoa-eastus-platforms-hub-vnet` |
| parSpokes                       | array | `None`                                                                           | Provide the spoke information in array form  | Yes                          | `{ "name": "operations", "virtualNetworkResourceId": "/subscriptions/xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx/resourceGroups/aona-eastus-platforms-operations-rg/providers/Microsoft.Network/virtualNetworks/aona-eastus-platforms-operations-vnet",                    "virtualNetworkName": "aona-eastus-platforms-operations-vnet" }` |

Parameters file located in the [Deployments](../../../../deployments/HubSpoke/networking/peering/hub) folder under hub/spoke.

## Deployment

### Manual Deployment - Azure CLI

```bash
# For Azure Commerical regions

# Set Platform connectivity subscription ID as the the current subscription 

ConnectivitySubscriptionId="[your platform management subscription ID]"
az account set --subscription $ConnectivitySubscriptionId

az deployment group create \  
   --resource-group anoa-eastus-platforms-hub-rg \ 
   --template-file enclave/bicep/landingzone/network/peering/hub/lz.hub.network.peerings.bicep \
   --parameters @enclave/bicep/landingzone/network/peering/hub/lz.hub.network.peerings.parameters.json
```

OR

```bash

# For Azure Government regions

# Set Platform connectivity subscription ID as the the current subscription 

ConnectivitySubscriptionId="[your platform management subscription ID]"
az account set --subscription $ConnectivitySubscriptionId

az deployment group create \
   --resource-group anoa-eastus-platforms-hub-rg \
   --template-file enclave/bicep/landingzone/networkpeering/hub/lz.hub.network.peerings.bicep \
   --parameters @enclave/bicep/landingzone/network/peering/hub/lz.hub.network.peerings.parameters.json
```

### Manual Deployment - PowerShell

```powershell
# For Azure Commerical regions
# Set Platform connectivity subscription ID as the the current subscription 
$ConnectivitySubscriptionId = "[your platform management subscription ID]"

Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId
  
New-AzResourceGroupDeployment `
  -TemplateFile enclave/bicep/landingzone/network/peering/hub/lz.hub.network.peerings.bicep `
  -TemplateParameterFile enclave/bicep/landingzone/network/peering/hub/lz.hub.network.peerings.json `
  -Resource-Group 'anoa-eastus-platforms-hub-rg'
```

OR

```powershell

# For Azure Government regions
# Set Platform connectivity subscription ID as the the current subscription 
$ConnectivitySubscriptionId = "[your platform management subscription ID]"

Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId
  
New-AzResourceGroupDeployment `
  -TemplateFile enclave/bicep/landingzone/network/peering/hub/lz.hub.network.peerings.bicep `
  -TemplateParameterFile enclave/bicep/landingzone/network/peering/hub/lz.hub.network.peerings.parameters.json `
  -Resource-Group 'anoa-eastus-platforms-hub-rg'
```

## GitHub Actions Workflows/YAML Example

This workflows can be found in the [.github/workflows](.github/workflows) folder

## GitLab Workflows/YAML Example

```yaml

```

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator Hub Network Peering deployment can be deleted with this step:

> Note: Before deleting a peering, ensure your account has the necessary permissions. When a peering is deleted, traffic can no longer flow between two virtual networks. When deleting a virtual networking peering, the corresponding peering will also be removed.

```bash
# For Azure Government regions

# Set Platform connectivity subscription ID as the the current subscription 

ConnectivitySubscriptionId="[your platform management subscription ID]"
az account set --subscription $ConnectivitySubscriptionId

az network vnet peering delete \ 
--resource-group anoa-eastus-platforms-hub-rg \ 
--name to-aona-eastus-platforms-operations-vnet \ 
--vnet-name anoa-eastus-platforms-hub-vnet
```

## Example Output in Azure

![Example Deployment Output](images/operationsNetworkExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")
