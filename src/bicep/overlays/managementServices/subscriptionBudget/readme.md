# Overlays: Subscription Budgets

## Overview

This overlay module deploys a budget for an Azure Enterprise Agreement (EA) subscription.

Read on to understand what this overlay does, and when you're ready, collect all of the pre-requisites, then deploy the overlay

## About Subscription Budgets

The docs on Cost Management & Billing: <https://docs.microsoft.com/en-us/azure/cost-management-billing/cost-management-billing-overview>

> NOTE: If you have a new subscription, you can't immediately create a budget or use other Cost Management features. It might take up to 48 hours before you can use all Cost Management features.

Budgets are supported for the following types of Azure account types and scopes:

* Azure role-based access control (Azure RBAC) scopes
  * Management groups
  * Subscription
* Enterprise Agreement scopes
  * Billing account
  * Department
  * Enrollment account
* Individual agreements
  * Billing account
* Microsoft Customer Agreement scopes
  * Billing account
  * Billing profile
  * Invoice section
  * Customer
* AWS scopes
  * External account
  * External subscription

## Pre-requisites

* A virtual network and subnet is deployed. (a deployment of [deploy.bicep](../../../../bicep/platforms/lz-platform-scca-hub-3spoke/deploy.bicep))
* Decide if the optional parameters is appropriate for your deployment. If it needs to change, override one of the optional parameters.

The following Azure permissions, or scopes, are supported per subscription for budgets by user and group. For more information about scopes, see Understand and work with scopes.

* Owner: Can create, modify, or delete budgets for a subscription.
* Contributor and Cost Management contributor: Can create, modify, or delete their own budgets. Can modify the budget amount for budgets created by others.
* Reader and Cost Management reader: Can view budgets that they have permission to.
For more information about assigning permission to Cost Management data, see [Assign access to Cost Management data](https://docs.microsoft.com/en-us/azure/cost-management-billing/costs/assign-access-acm-data).

## Parameters

See below for information on how to use the appropriate deployment parameters for use with this overlay:

Required Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
parLocation | string | `[deployment().location]` | The region to deploy resources into. It defaults to the deployment location.
parSubscriptionBudget | object | {object} | The oject parameters of the Subscription Budget

OptionalParameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
None

## Deploy the Overlay

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell or Azure CLI for help if needed. The commands below assume you are deploying in Azure Commercial and show the entire process from deploying Platform Hub/Spoke Design and then adding an Subscription Budgets post-deployment.

> NOTE: Since you can deploy this overlay post-deployment, you can also build this overlay within other deployment models such as Platforms & Workloads.

Once you have the hub/spoke output values, you can pass those in as parameters to this deployment.

For example, deploying using the `az deployment sub create` command in the Azure CLI:

### Azure CLI

```bash
# For Azure Commerical regions
az deployment sub create \
   --template-file overlays/subscription-budget/deploy.bicep \
   --parameters @overlays/subscription-budget/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'eastus'
```

OR

```bash
# For Azure Government regions
az deployment sub create \
  --template-file overlays/subscription-budget/deploy.bicep \
  --parameters @overlays/subscription-budget/deploy.parameters.json \
  --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
  --location 'usgovvirginia'
```

### PowerShell

```powershell
# For Azure Commerical regions
New-AzSubscriptionDeployment `
  -TemplateFile overlays/subscription-budget/deploy.bicepp `
  -TemplateParameterFile overlays/subscription-budget/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location 'eastus'
```

OR

```powershell
# For Azure Government regions
New-AzSubscriptionDeployment `
  -TemplateFile overlays/subscription-budget/deploy.bicepp `
  -TemplateParameterFile overlays/subscription-budget/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location  'usgovvirginia'
```

## Extending the Overlay

By default, this overlay has the minium parmeters needed to deploy the service. If you like to add addtional parmeters to the service, please refer to the module description located in AzResources here: [`App Service Plans `[Microsoft.Web/serverfarms]`](D:\source\repos\NoOpsAccelerator\src\bicep\azresources\Modules\Microsoft.Web\serverfarms\readme.md)

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Review Deployed Resources

Use the Azure portal, Azure CLI, or Azure PowerShell to list the deployed resources in the resource group.

```bash
az consumption budget list
```

OR

```powershell
Get-AzConsumptionBudget
```

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Subscription Budgets deployment can be deleted with these steps:

### Delete Resources

```bash
az consumption budget delete --budget-name MyBudget
```

OR

```powershell
Remove-AzConsumptionBudget -Name MyBudget
```

## Example Output in Azure

![Example Deployment Output](media/aspExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")
