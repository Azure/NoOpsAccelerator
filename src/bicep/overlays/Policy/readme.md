# Overlays: NoOps Accelerator - Policy

## Overview

The Enclave Roles overlay module deploys a role definations hierarchy in a tenant under the `Tenant Root Group`.  This is accomplished through a tenant-scoped Azure Resource Manager (ARM) deployment.  The heirarchy can be modifed by editing `anoa.lz.mgmt.groups.parameters.example.json`.  

Module deploys the following resources:

* Enclave Management Groups

The hierarchy created by the deployment is:

* Tenant Root Group
  * Top Level Management Group (defined by parameter `parManagementGroups`)
    * Platform
      * Management
      * Connectivity
      * Identity
    * Workloads
      * internal
        * Dev
        * Test
        * Prod
    * Sandbox

## Deploy Enclave Management Groups

The docs on Management Groups: <https://docs.microsoft.com/en-us/azure/bastion/bastion-overview>

## Pre-requisites

Currently there are no Pre-requisites

## Parameters

The module requires the following inputs:

| Parameter                             | Type   | Description                                                                                                                                                     | Requirements                      | Example               |
| ------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- | --------------------- |
| parRootMg      | string | Prefix for the management group hierarchy.  This management group will be created as part of the deployment.                                                    | 2-10 characters                   | `alz`                 |
| parRequireAuthorizationForGroupCreation | string | Display name for top level management group.  This name will be applied to the management group prefix defined in `parTopLevelManagementGroupPrefix` parameter. | Minimum two characters            | `Azure Landing Zones` |
| parManagementGroups | array   | Set Parameter to true to Apply Top Level Management Group Prefix of deployment | Mandatory input, default: `false`  | `false` |
| parSubscriptions | array   | Set Parameter to true to Apply Top Level Management Group Prefix of deployment | Mandatory input, default: `false`  | `false` |
| parTenantId      | string | Prefix for the management group hierarchy.  This management group will be created as part of the deployment.                                                    | 2-10 characters                   | `alz`                 |
| parTelemetryOptOut                    | bool   | Set Parameter to true to Opt-out of deployment telemetry | Mandatory input, default: `false` | `false`  |

## Outputs

The module will generate the following outputs:

| Output | Type | Example |
| ------ | ---- | ------- |
None

## Deployment

In this overlay, the management groups are created at the `Tenant Root Group` through a tenant-scoped deployment.

### Azure CLI

```bash
# For Azure global regions
az deployment mg create \
   --template-file overlays/management-groups/anoa.lz.mgmt.groups.bicep \
   --parameters @overlays/management-groups/anoa.lz.mgmt.groups.parameters.example.json \
   --location 'eastus'
```

OR

```bash
# For Azure IL regions
az deployment mg create \
  --template-file overlays/management-groups/anoa.lz.mgmt.groups.bicep \
  --parameters @overlays/management-groups/anoa.lz.mgmt.groups.parameters.example.json \
  --location 'usgovvirginia'
```

### PowerShell

```powershell
# For Azure global regions
New-AzManagementGroupDeployment `
  -ManagementGroupId xxxxxxx-xxxx-xxxxxx-xxxxx-xxxx
  -TemplateFile overlays/management-groups/anoa.lz.mgmt.groups.bicepp `
  -TemplateParameterFile overlays/management-groups/anoa.lz.mgmt.groups.parameters.example.json `
  -Location 'eastus'
```

OR

```powershell
# For Azure IL regions
New-AzManagementGroupDeployment `
  -ManagementGroupId xxxxxxx-xxxx-xxxxxx-xxxxx-xxxx
  -TemplateFile overlays/management-groups/anoa.lz.mgmt.groups.bicepp `
  -TemplateParameterFile overlays/management-groups/anoa.lz.mgmt.groups.parameters.example.json `
  -Location  'usgovvirginia'
```

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator Logging deployment can be deleted with these steps:

## Example Output in Azure

![Example Deployment Output](images/operationsNetworkExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")

