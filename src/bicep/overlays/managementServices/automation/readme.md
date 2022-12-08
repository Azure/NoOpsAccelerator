# Overlays: Automation Account

## Overview

This overlay module deploys an Platform Landing Zone compatible Azure Automation account, with diagnostic logs pointed to the Platform Landing Zone Log Analytics Workspace (LAWS) instance.

## About Azure Automation Account

The docs on Azure Automation Account: <https://docs.microsoft.com/en-us/azure/automation/>. By default, this overlay will deploy resources into standard default hub/spoke subscriptions and resource groups.  

The subscription and resource group can be changed by providing the resource group name (Param: parTargetSubscriptionId/parTargetResourceGroup) and ensuring that the Azure context is set the proper subscription.  

Automation is needed in three broad areas of cloud operations:

* Deploy and manage - Deliver repeatable and consistent infrastructure as code.
* Response - Create event-based automation to diagnose and resolve issues.
* Orchestrate - Orchestrate and integrate your automation with other Azure or third party services and products.

One Automation account can manage resources across all regions and subscriptions for a given tenant.

## Pre-requisites

* A hub/spoke LZ deployment (a deployment of [deploy.bicep](../../../../bicep/platforms/lz-platform-scca-hub-3spoke/deploy.bicep))
* Decide if the optional parameters is appropriate for your deployment. If it needs to change, override one of the optional parameters.

## Parameters

See below for information on how to use the appropriate deployment parameters for use with this overlay:

Required Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
parRequired | object | {object} | Required values used with all resources.
parTags | object | {object} | Required tags values used with all resources.
parLocation | string | `[deployment().location]` | The region to deploy resources into. It defaults to the deployment location.
parLockLevel | string | `[deployment().location]` | The region to deploy resources into. It defaults to the deployment location.
parDiagnosticStorageAccountName | The resource group that contains the Hub Virtual Network and deploy the virtual machines into
parLogAnalyticsWorkspaceName | The resource to deploy a subnet configured for Bastion Host
parTargetSubscriptionId | string | `xxxxxx-xxxx-xxxx-xxxxx-xxxxxx` | The target subscription ID for the target Network and resources. It defaults to the deployment subscription.
parTargetResourceGroup | string | `anoa-eastus-platforms-hub-rg` | The name of the resource group in which the automation account will be deployed. If unchanged or not specified, the NoOps Accelerator will create an resource group.

Optional Parameters | Description
------------------- | -----------
None

## Deploy the Overlay

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell or Azure CLI for help if needed. The commands below assume you are deploying in Azure Commercial and show the entire process from deploying Platform Hub/Spoke Design and then adding an Azure Automation account post-deployment.

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
cd automation
az deployment sub create \
   --name deploy-AA
   --template-file overlays/automation/deploy.bicep \
   --parameters @overlays/automation/parameters/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'eastus'
```

OR

```bash
# For Azure Government regions
az deployment group create \
  --template-file overlays/automation/deploy.bicep \
  --parameters @overlays/automation/parameters/deploy.parameters.json \
  --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
  --resource-group anoa-usgovvirginia-platforms-hub-rg \
  --location 'usgovvirginia'
```

### PowerShell

```powershell
# For Azure Commerical regions
New-AzSubscriptionDeployment `  -
  -TemplateFile overlays/automation/deploy.bicepp `
  -TemplateParameterFile overlays/automation/parameters/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location 'eastus'
```

OR

```powershell
# For Azure Government regions
New-AzSubscriptionDeployment `
  -TemplateFile overlays/automation/deploy.bicepp `
  -TemplateParameterFile overlays/automation/parameters/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location  'usgovvirginia'
```

## Extending the Overlay

By default, this overlay has the minium parmeters needed to deploy the service. If you like to add addtional parmeters to the service, please refer to the module description located in AzResources here: [Container Registries `[Microsoft.ContainerRegistry/registries]`](../../../azresources/Modules/Microsoft.ContainerRegistry/registries/readmd.md)

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Validate the deployment

Use the Azure portal, Azure CLI, or Azure PowerShell to list the deployed resources in the resource group.

Configure the default group using:

```bash
az configure --defaults group=anoa-eastus-workload-aa-rg.
```

```bash
az resource list --location eastus --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx --resource-group anoa-eastus-workload-aa-rg
```

OR

```powershell
Get-AzResource -ResourceGroupName anoa-eastus-workload-aa-rg
```

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Azure Automation account deployment can be deleted with these steps:

### Delete Resource Groups

```bash
az group delete --name anoa-eastus-workload-aa-rg
```

OR

```powershell
Remove-AzResourceGroup -Name anoa-eastus-workload-aa-rg
```

### Delete Deployments

```bash
az deployment delete --name deploy-AA
```

OR

```powershell
Remove-AzSubscriptionDeployment -Name deploy-AA
```

## Example Output in Azure

![Example Deployment Output](media/aaExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")

### References

* [Azure Automation account service tiers(Sku's)](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-skus)