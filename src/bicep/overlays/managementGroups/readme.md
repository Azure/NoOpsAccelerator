# Overlays: NoOps Accelerator - Management Groups

## Overview

The Enclave Management Groups module deploys a management group hierarchy in a tenant under the `Tenant Root Group`.  This is accomplished through a tenant-scoped Azure Resource Manager (ARM) deployment.  The heirarchy can be modifed by editing `deploy.parameters.json`.

>NOTE: This module setups up a enclave management group structure suitable for the Hub/ 3 Spoke Design. You can create other parameter files that can be used for other organizational requirement.

Read on to understand what this overlay does, and when you're ready, collect all of the pre-requisites, then deploy the overlay

## Architecture

Azure NoOps Accelerator recommends the following Management Group structure. This structure can be customized based on your organization's requirements.

* Workloads will be split by 2 groups of archtypes (INTERNAL, PARTNERS).
* Sandbox management group is used for any new subscriptions that will be created. This will remove the subscription sprawl from the Root Tenant Group and will pull all subscriptions into the security compliance.

The hierarchy created by the deployment ([Azure Parameters template located in "management-groups/parameters" folder](../../overlays/management-groups/parameters/deploy.parameters.json)) is:

![Enclave Management Groups](../management-groups/media/01%20-%20Management%20Group%20Design.jpg)

## About Management Groups

The docs on Management Groups: <https://learn.microsoft.com/en-us/azure/governance/management-groups/overview>. By default, this overlay will deploy resources into tenant.  

The subscription and resource group can be changed by providing the resource group name (Param: parTargetSubscriptionId/parTargetResourceGroup) and ensuring that the Azure context is set the proper subscription.  

## Pre-requisites

* A organization tenant is available.
* Decide if the optional parameters is appropriate for your deployment. If it needs to change, override one of the optional parameters.

## Parameters

See below for information on how to use the appropriate deployment parameters for use with this overlay:

Required Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
| `parRootMg` | string | `anoa` | Prefix for the management group hierarchy.  This management group will be created as part of the deployment. |
| `parManagementGroups` | array  | none | Set Parameter to true to Apply Top Level Management Group Prefix of deployment |

Optional Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
| `parRequireAuthorizationForGroupCreation` | bool | `false` |Display name for top level management group.  This name will be applied to the management group prefix defined in `parRootMg` parameter. |

## Outputs

This overlay will generate the following outputs:

| Output Name | Type | Description |
| :-- | :-- | :-- |
None

## Deploy the Overlay

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell or Azure CLI for help if needed.

The commands below assume you are deploying in Azure Commercial and show the entire process deploying Management Groups.

For example, deploying using the `az deployment mg create` command in the Azure CLI:

<h3>Overlay Example: Management Groups</h3>

<details>

<summary>via Bash</summary>

```bash
# For Azure Commerical regions
az login
cd src/bicep/overlays
cd management-groups
az deployment mg create \
   --template-file overlays/management-groups/deploy.bicep \
   --parameters @overlays/management-groups/deploy.parameters.json \
   --location 'eastus'
```

```bash
# For Azure Government regions

# change Azure Clouds
az cloud set --name AzureUSGovernment

#sign  into AZ CLI, this will redirect you to a web browser for authentication, if required
az login
az deployment mg create \
  --template-file overlays/management-groups/deploy.bicep \
  --parameters @overlays/management-groups/deploy.parameters.json \
  --location 'usgovvirginia'
```
</details>

<p>

<details>

<summary>via Powershell</summary>

```powershell
# For Azure Commerical regions

#sign in to Azure  from Powershell, this will redirect you to a web browser for authentication, if required
Connect-AzAccount

#Fetch the list of available Tenant Ids.
Get-AzTenant

#Grab the tenant Id Switch to another active directory tenant.
Set-AzContext -TenantId XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

New-AzManagementGroupDeployment `
  -ManagementGroupId xxxxxxx-xxxx-xxxxxx-xxxxx-xxxx
  -TemplateFile overlays/management-groups/deploy.bicepp `
  -TemplateParameterFile overlays/management-groups/deploy.parameters.json `
  -Location 'eastus'
```

OR

```powershell
# For Azure Government regions

#sign in to Azure  from Powershell, this will redirect you to a web browser for authentication, if required
Connect-AzAccount

#Fetch the list of available Tenant Ids.
Get-AzTenant

#Grab the tenant Id Switch to another active directory tenant.
Set-AzContext -TenantId XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

New-AzManagementGroupDeployment `
  -ManagementGroupId xxxxxxx-xxxx-xxxxxx-xxxxx-xxxx
  -TemplateFile overlays/management-groups/deploy.bicepp `
  -TemplateParameterFile overlays/management-groups/deploy.parameters.json `
  -Location  'usgovvirginia'
```
</details>
<p>

<p>
  <details>
    <summary>via Azure CLI</summary>

```bash
# For Azure Commerical regions

# Sign into AZ CLI, this will redirect you to a web browser for authentication, if required
az login

az deployment mg create
 --template-file deploy.bicep
 --parameters @parameters/deploy.parameters.json
 --location eastus
 --name deploy-enclave-mg
 --management-group-id '<< your tenant id >>'
```

```bash
# For Azure Government regions

# change Azure Clouds
az cloud set --name AzureUSGovernment

#sign  into AZ CLI, this will redirect you to a web browser for authentication, if required
az login

az deployment mg create
 --template-file deploy.bicep
 --parameters @parameters/deploy.parameters.json
 --location eastus
 --name deploy-enclave-mg
 --management-group-id '<< your tenant id >>'
```

  </details>
</p>

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator Management Groups deployment can be deleted with these steps:

Delete all hierarchy settings defined at the Management Group level.

```bash
az account management-group hierarchy-settings delete --name GroupName
```

## Example Output in Azure

![Example Deployment Output](media/mgExampleManagementStructure.png "Example Deployment Output in Azure global regions")
