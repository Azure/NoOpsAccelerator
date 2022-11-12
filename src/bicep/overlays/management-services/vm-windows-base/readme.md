# Overlays: Windows VM Base

## Overview

This overlay module deploys an Windows VM with a Server 2022 Base.

Read on to understand what this overlay does, and when you're ready, collect all of the pre-requisites, then deploy the overlay

## About Windows VM Base

The docs on Azure Windows VM Base: <https://learn.microsoft.com/en-us/azure/virtual-machines/overview>. By default, this overlay will deploy resources into standard default hub/spoke subscriptions and resource groups.  

The subscription and resource group can be changed by providing the resource group name (Param: parTargetSubscriptionId/parTargetResourceGroup) and ensuring that the Azure context is set the proper subscription.  

## Pre-requisites

* A virtual network and subnet is deployed. (a deployment of [deploy.bicep](../../../../bicep/platforms/lz-platform-scca-hub-3spoke/deploy.bicep))
* Decide if the optional parameters is appropriate for your deployment. If it needs to change, override one of the optional parameters.

## Parameters

See below for information on how to use the appropriate deployment parameters for use with this overlay:

Required Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
parRequired | object | {object} | Required values used with all resources.
parTags | object | {object} | Required tags values used with all resources.
parLocation | string | `[deployment().location]` | The region to deploy resources into. It defaults to the deployment location.
parWindowsVM | object | {object} | The oject parameters of the Windows VM Base.
parTargetSubscriptionId | string | `xxxxx-xxxx-xxxx-xxxx-xxxxxx` |  The subscription ID for the Target Network and resources. It defaults to the deployment subscription.
parTargetResourceGroupName | string | `anoa-eastus-platforms-hub-rg` | The name of the resource group where the Windows VM Base will be deployed.   If not specified, the resource group name will default to the shared services resource group name and subscription.
parTargetSubnetResourceId | string | `/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourceGroups/anoa-eastus-platforms-hub-rg/providers/Microsoft.Network/virtualNetworks/anoa-eastus-platforms-hub-vnet/subnets/anoa-eastus-platforms-hub-snet` | The resource ID of the subnet in the Hub Virtual Network for hosting virtual machines
parLogAnalyticsWorkspaceId | string | `/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourcegroups/anoa-eastus-platforms-logging-rg/providers/microsoft.operationalinsights/workspaces/anoa-eastus-platforms-logging-log` | Log Analytics Workspace Resource Id Needed for Windows VM Base

Optional Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
None

## Outputs

This overlay will generate the following outputs:

| Output Name | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
outWindowsVMName | string | '' | Windows VM Base Name
outResourceGroupName | string | '' | Windows VM Base Resource Group Name
outTags object | {object} | Required tags values used with Windows VM Base overlay.

## Deploy the Overlay

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell or Azure CLI for help if needed. The commands below assume you are deploying in Azure Commercial and show the entire process from deploying Platform Hub/Spoke Design and then adding an Azure Windows VM Base post-deployment.

> NOTE: Since you can deploy this overlay post-deployment, you can also build this overlay within other deployment models such as Platforms & Workloads.

Once you have the hub/spoke output values, you can pass those in as parameters to this deployment.

For example, deploying using the `az deployment sub create` command in the Azure CLI:

<h3>Overlay Example: Windows VM Base</h3>

<details>

<summary>via Bash</summary>

```bash
# For Azure Commerical regions

# When deploying to Azure cloud, first set the cloud.
az cloudset --name AzureCloud

# Set Platform connectivity subscription ID as the the current subscription 
$ConnectivitySubscriptionId="[your platform management subscription ID]"
az account set --subscription $ConnectivitySubscriptionId

#log in
az login
cd src/bicep
cd platforms/lz-platform-scca-hub-3spoke
az deployment sub create \ 
--name deploy-windows-network \
--subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
--template-file deploy.bicep \
--location eastus \
--parameters @parameters/deploy.parameters.json


cd overlays
cd vm-windows-base
az deployment sub create \
   --name deploy-windows-overlay
   --template-file deploy.bicep \
   --parameters @parameters/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'eastus'
```

OR

```bash
# For Azure Government regions

# When deploying to another cloud, like Azure US Government, first set the cloud and log in.
az cloudset --name AzureGovernment

# Set Platform connectivity subscription ID as the the current subscription
$ConnectivitySubscriptionId="[your platform management subscription ID]"
az account set --subscription $ConnectivitySubscriptionId

az login
cd src/bicep
cd overlays
cd vm-windows-base
az deployment group create \
  --name deploy-windows-overlay
   --template-file deploy.bicep \
   --parameters @parameters/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'usgovvirginia'
```


</details>
<p>

<details>

<summary>via Powershell</summary>

### PowerShell

```powershell
# For Azure Commerical regions
# When deploying to Azure cloud, first set the cloud and log in.
Connect-AzAccount -EnvironmentName AzureCloud

# Set Platform connectivity subscription ID as the the current subscription
$ConnectivitySubscriptionId = "[your platform management subscription ID]"
Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId

cd src/bicep
cd overlays
cd vm-windows-base

New-AzSubscriptionDeployment `
  -Name deploy-windows-overlay `
  -TemplateFile deploy.bicepp `
  -TemplateParameterFile parameters/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location 'eastus'
```

OR

```powershell
# For Azure Government regions

# When deploying to another cloud, like Azure US Government, first set the cloud and log in.
Connect-AzAccount -EnvironmentName AzureUSGovernment

# Set Platform connectivity subscription ID as the the current subscription
$ConnectivitySubscriptionId = "[your platform management subscription ID]"
Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId

cd src/bicep
cd overlays
cd vm-windows-base

New-AzSubscriptionDeployment `
  -Name deploy-windows-overlay `
  -TemplateFile deploy.bicepp `
  -TemplateParameterFile parameters/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location  'usgovvirginia'
```
</details>
<p>

## Extending the Overlay

By default, this overlay has the minium parmeters needed to deploy the service. If you like to add addtional parmeters to the service, please refer to the module description located in AzResources here: [Virtual Machines `[Microsoft.Compute/virtualMachines]`](../../../azresources/Modules/Microsoft.Compute/virtualmachines/readme.md)

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Validate the deployment

Use the Azure portal, Azure CLI, or Azure PowerShell to list the deployed resources in the resource group.

Configure the default group using:

```bash
az configure --defaults group=anoa-eastus-dev-windows-rg.
```

```bash
az resource list --location eastus --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx --resource-group anoa-eastus-dev-windows-rg
```

OR

```powershell
Get-AzResource -ResourceGroupName anoa-eastus-dev-windows-rg
```

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Azure Windows VM Base deployment can be deleted with these steps:

### Delete Resource Groups

```bash
az group delete --name anoa-eastus-dev-windows-rg
```

OR

```powershell
Remove-AzResourceGroup -Name anoa-eastus-dev-windows-rg
```

### Delete Deployments

```bash
az deployment delete --name deploy-windows-network
az deployment delete --name deploy-windows-overlay
```

OR

```powershell
Remove-AzSubscriptionDeployment -Name deploy-windows-network
Remove-AzSubscriptionDeployment -Name deploy-windows-overlay
```

## Example Output in Azure

![Example Deployment Output](media/windowsExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")

### References

* [Virtual machines in Azure Documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/overview/)
