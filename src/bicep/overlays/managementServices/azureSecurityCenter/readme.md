# Overlays: Microsoft Azure Security Center

## Overview

This overlay module adds a standard/defender sku which enables a greater depth of awareness including more recomendations and threat analytics.

Read on to understand what this overlay does, and when you're ready, collect all of the pre-requisites, then deploy the overlay

## About Microsoft Defender

The docs on Microsoft Azure Security Center: <https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-cloud-introduction>

NOTE:
> The Security Center plan by resource type for Microsoft Azure Security Center is enabled by default in the following [Azure Environments](https://docs.microsoft.com/en-us/powershell/module/servicemanagement/azure.service/get-azureenvironment?view=azuresmps-4.0.0): `AzureCloud` and `AzureUSGovernment`. To enable this for other Azure Cloud environments, this will need to executed manually.
Documentation on how to do this can be found
[here](https://docs.microsoft.com/en-us/azure/defender-for-cloud/enable-enhanced-security)

By default, this overlay will deploy resources into standard default hub/spoke subscriptions and resource groups.  

The subscription and resource group can be changed by providing the resource group name (Param: parTargetSubscriptionId/parTargetResourceGroup) and ensuring that the Azure context is set the proper subscription.  

## Pre-requisites

* A virtual network and subnet is deployed. (a deployment of [deploy.bicep](../../../../bicep/platforms/lz-platform-scca-hub-3spoke/deploy.bicep))
* Decide if the optional parameters is appropriate for your deployment. If it needs to change, override one of the optional parameters.

## Parameters

See below for information on how to use the appropriate deployment parameters for use with this overlay:

Required Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
parLocation | string | `[deployment().location]` | The region to deploy resources into. It defaults to the deployment location.
parSecurityCenter | object | {object} | The oject parameters of the Microsoft Bastion Host.
parTargetSubscriptionId | string | `xxxxxx-xxxx-xxxx-xxxxx-xxxxxx` | The target subscription ID for the target Network and resources. It defaults to the deployment subscription.
parLogAnalyticsWorkspaceResourceId | string | `/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourcegroups/anoa-eastus-platforms-logging-rg/providers/microsoft.operationalinsights/workspaces/anoa-eastus-platforms-logging-log` | Log Analytics Workspace Resource Id Needed for Defender

Optional Parameters | Description
------------------- | -----------
None

## Deploy the Overlay

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell or Azure CLI for help if needed. The commands below assume you are deploying in Azure Commercial and show the entire process from deploying Platform Hub/Spoke Design and then adding an Microsoft Defender post-deployment.

> NOTE: Since you can deploy this overlay post-deployment, you can also build this overlay within other deployment models such as Platforms & Workloads.

Once you have the hub/spoke output values, you can pass those in as parameters to this deployment.

For example, deploying using the `az deployment sub create` command in the Azure CLI:

### Azure CLI

```bash
# For Azure Commerical regions
az login
cd src/bicep
cd platforms/lz-platform-scca-hub-3spoke
az deployment sub create \ 
--name contoso \
--subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
--template-file platforms/lz-platform-scca-hub-3spoke/deploy.bicep \
--location eastus \
--parameters @platforms/lz-platform-scca-hub-3spoke/parameters/deploy.parameters.json
cd overlays
cd defender
az deployment sub create \
   --name deploy-defender
   --template-file overlays/defender/deploy.bicep \
   --parameters @overlays/defender/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'eastus'
```

OR

```bash
# For Azure Government regions
az deployment sub create \
  --name deploy-defender
  --template-file overlays/defender/deploy.bicep \
  --parameters @overlays/defender/deploy.parameters.json \
  --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
  --location 'usgovvirginia'
```

### PowerShell

```powershell
# For Azure Commerical regions
New-AzSubscriptionDeployment `
  -TemplateFile overlays/defender/deploy.bicepp `
  -TemplateParameterFile overlays/defender/deploy.parameters.example.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location 'eastus'
```

OR

```powershell
# For Azure Government regions
New-AzSubscriptionDeployment `
  -TemplateFile overlays/defender/deploy.bicepp `
  -TemplateParameterFile overlays/defender/deploy.parameters.example.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location  'usgovvirginia'
```

## Extending the Overlay

By default, this overlay has the minium parmeters needed to deploy the service. If you like to add addtional parmeters to the service, please refer to the module description located in AzResources here: [Microsoft Azure Security Center `[Microsoft.Security/azureSecurityCenter]`](../../../azresources/Modules/Microsoft.Security/azureSecurityCenter/readme.md)

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Validate the deployment

Use the Azure portal, Azure CLI, or Azure PowerShell to list the deployed resources in the resource group.

Configure the default group using:

```bash
az configure --defaults group=anoa-eastus-hub-defender-rg.
```

```bash
az resource list --location eastus --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx --resource-group anoa-eastus-hub-defender-rg
```

OR

```powershell
Get-AzResource -ResourceGroupName anoa-eastus-hub-defender-rg
```

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Microsoft Azure Security Center deployment can be deleted with these steps:

### Delete Resource Groups

```bash
az group delete --name anoa-eastus-hub-defender-rg
```

OR

```powershell
Remove-AzResourceGroup -Name anoa-eastus-hub-defender-rg
```

### Delete Deployments

```bash
az deployment delete --name deploy-defender
```

OR

```powershell
Remove-AzSubscriptionDeployment -Name deploy-defender
```

## Example Output in Azure

![Example Deployment Output](media/defenderExampleDeploymentOutput.png "Example Deployment Output in Azure Commerical regions")
