# Overlays: Microsoft Service Health Alerts

## Overview

This overlay module deploys Microsoft Service Health Alerts to the target resource group.

Read on to understand what this overlay does, and when you're ready, collect all of the pre-requisites, then deploy the overlay

## About Microsoft Service Health Alerts

The docs on Microsoft Service Health Alerts: <https://docs.microsoft.com/en-us/azure/service-health/overview>

[Service health notifications](https://docs.microsoft.com/azure/service-health/service-health-notifications-properties) are published by Azure, and contain information about the resources under your subscription.  Service health notifications can be informational or actionable, depending on the category.

Our examples configure service health alerts for `Security` and `Incident`. However, these categories can be customized based on your need. Please review the possible options in [Azure Docs](https://docs.microsoft.com/azure/service-health/service-health-notifications-properties#details-on-service-health-level-information).

The subscription and resource group can be changed by providing the resource group name (Param: parTargetSubscriptionId/parTargetResourceGroup) and ensuring that the Azure context is set the proper subscription.  

## Pre-requisites

* A virtual network and subnet is deployed. (a deployment of [deploy.bicep](../../../../bicep/platforms/lz-platform-scca-hub-3spoke/deploy.bicep))
* Decide if the optional parameters is appropriate for your deployment. If it needs to change, override one of the optional parameters.
 
## Parameters

See below for information on how to use the appropriate deployment parameters for use with this overlay:

Deployment Output Name | Description
-----------------------| -----------
parRequired | Required values used with all resources.
parTags | Required tags values used with all resources.
parLocation | The region to deploy resources into. It defaults to the deployment location.
parTargetResourceGroup | The name of the Target Resource Group
parServiceHealthAlerts | The object of the Service Health alerts

Optional Parameters | Description
------------------- | -----------
None

## Deploy the Overlay

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell or Azure CLI for help if needed. The commands below assume you are deploying in Azure Commercial and show the entire process from deploying Platform Hub/Spoke Design and then adding an Microsoft Service Health Alerts post-deployment.

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
cd service-health
az deployment sub create \
   --name deploy-AppServicePlan
   --template-file overlays/service-health/deploy.bicep \
   --parameters @overlays/service-health/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'eastus'
```

OR

```bash
# For Azure Government regions
az deployment sub create \
  --template-file overlays/service-health/deploy.bicep \
  --parameters @overlays/service-health/deploy.parameters.json \
  --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
  --resource-group anoa-usgovvirginia-platforms-hub-rg \
  --location 'usgovvirginia'
```

### PowerShell

```powershell
# For Azure Commerical regions
New-AzSubscriptionDeployment `
  -ManagementGroupId xxxxxxx-xxxx-xxxxxx-xxxxx-xxxx
  -TemplateFile overlays/service-health/deploy.bicepp `
  -TemplateParameterFile overlays/service-health/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -ResourceGroup anoa-eastus-platforms-hub-rg `
  -Location 'eastus'
```

OR

```powershell
# For Azure Government regions
New-AzSubscriptionDeployment `
  -ManagementGroupId xxxxxxx-xxxx-xxxxxx-xxxxx-xxxx
  -TemplateFile overlays/service-health/deploy.bicepp `
  -TemplateParameterFile overlays/service-health/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -ResourceGroup anoa-usgovvirginia-platforms-hub-rg `
  -Location  'usgovvirginia'
```

## Extending the Overlay

By default, this overlay has the minium parmeters needed to deploy the service. If you like to add addtional parmeters to the service, please refer to the module description located in AzResources here: [`Activity Log Alerts [Microsoft.Insights/activityLogAlerts]`](./../../../azresources/Modules/Microsoft.Insights/activityLogAlerts/readme.md)

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Microsoft Service Health Alerts deployment can be deleted with these steps:

### Delete Resource Groups

Remove-AzResourceGroup -Name anoa-eastus-workload-serviceAlerts-rg

### Delete Deployments

Remove-AzSubscriptionDeployment -Name deploy-ServiceAlerts

## Example Output in Azure

![Example Deployment Output](media/aspExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")
