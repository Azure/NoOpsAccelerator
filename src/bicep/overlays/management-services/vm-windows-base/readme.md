# Overlays: Centos VM Base

## Overview

This overlay module deploys an Centos VM Base.

Read on to understand what this overlay does, and when you're ready, collect all of the pre-requisites, then deploy the overlay

## About Centos VM Base

The docs on Azure Centos VM Base: <https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans>. By default, this overlay will deploy resources into standard default hub/spoke subscriptions and resource groups.  

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
parAppServicePlan | object | {object} | The oject parameters of the Centos VM Base.
parTargetSubscriptionId | string | xxxxx-xxxx-xxxx-xxxx-xxxxxx |  The subscription ID for the Target Network and resources. It defaults to the deployment subscription.
parTargetResourceGroupName | string | '' | The name of the resource group where the Centos VM Base will be deployed.   If not specified, the resource group name will default to the shared services resource group name and subscription.

Optional Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
None

## Outputs

This overlay will generate the following outputs:

| Output Name | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
outAppServicePlanName | string | '' | Centos VM Base Name
outResourceGroupName | string | '' | Centos VM Base Resource Group Name
outTags object | {object} | Required tags values used with Centos VM Base overlay.

## Deploy the Overlay

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell or Azure CLI for help if needed. The commands below assume you are deploying in Azure Commercial and show the entire process from deploying Platform Hub/Spoke Design and then adding an Azure Centos VM Base post-deployment.

> NOTE: Since you can deploy this overlay post-deployment, you can also build this overlay within other deployment models such as Platforms & Workloads.

Once you have the hub/spoke output values, you can pass those in as parameters to this deployment.

For example, deploying using the `az deployment sub create` command in the Azure CLI:

<h3>Overlay Example: Centos VM Base</h3>

<details>

<summary>via Bash</summary>

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
cd app-service-plan
az deployment sub create \
   --name deploy-AppServicePlan
   --template-file overlays/app-service-plan/deploy.bicep \
   --parameters @overlays/app-service-plan/parameters/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'eastus'
```

OR

```bash
# For Azure Government regions
az deployment sub create \
  --template-file overlays/app-service-plan/deploy.bicep \
  --parameters @overlays/app-service-plan/parameters/deploy.parameters.json \
  --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
  --resource-group anoa-usgovvirginia-platforms-hub-rg \
  --location 'usgovvirginia'
```


</details>
<p>

<details>

<summary>via Powershell</summary>

### PowerShell

```powershell
# For Azure Commerical regions
New-AzSubscriptionDeployment `
  -ManagementGroupId xxxxxxx-xxxx-xxxxxx-xxxxx-xxxx
  -TemplateFile overlays/app-service-plan/deploy.bicepp `
  -TemplateParameterFile overlays/app-service-plan/parameters/deploy.parameters.example.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -ResourceGroup anoa-eastus-platforms-hub-rg `
  -Location 'eastus'
```

OR

```powershell
# For Azure Government regions
New-AzSubscriptionDeployment `
  -ManagementGroupId xxxxxxx-xxxx-xxxxxx-xxxxx-xxxx
  -TemplateFile overlays/app-service-plan/deploy.bicepp `
  -TemplateParameterFile overlays/app-service-plan/parameters/deploy.parameters.example.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -ResourceGroup anoa-usgovvirginia-platforms-hub-rg `
  -Location  'usgovvirginia'
```
</details>
<p>

## Extending the Overlay

By default, this overlay has the minium parmeters needed to deploy the service. If you like to add addtional parmeters to the service, please refer to the module description located in AzResources here: [`Centos VM Bases `[Microsoft.Web/serverfarms]`](D:\source\repos\NoOpsAccelerator\src\bicep\azresources\Modules\Microsoft.Web\serverfarms\readme.md)

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Validate the deployment

Use the Azure portal, Azure CLI, or Azure PowerShell to list the deployed resources in the resource group.

Configure the default group using:

```bash
az configure --defaults group=anoa-eastus-dev-appplan-rg.
```

```bash
az resource list --location eastus --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx --resource-group anoa-eastus-dev-appplan-rg
```

OR

```powershell
Get-AzResource -ResourceGroupName anoa-eastus-dev-appplan-rg
```

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Azure Centos VM Base deployment can be deleted with these steps:

### Delete Resource Groups

```bash
az group delete --name anoa-eastus-dev-appplan-rg
```

OR

```powershell
Remove-AzResourceGroup -Name anoa-eastus-dev-appplan-rg
```

### Delete Deployments

```bash
az deployment delete --name deploy-AppServicePlan
```

OR

```powershell
Remove-AzSubscriptionDeployment -Name deploy-AppServicePlan
```

## Example Output in Azure

![Example Deployment Output](media/aspExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")

### References

* [Azure App Service plan Documentation](https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans/)
* [Azure App Service Overview](https://docs.microsoft.com/en-us/azure/app-service/overview)
* [Manage an App Service plan in Azure](https://docs.microsoft.com/en-us/azure/app-service/app-service-plan-manage)