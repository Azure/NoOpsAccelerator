# Overlays: NoOps Accelerator - Roles

## Overview

The Enclave Roles overlay module deploys a role definitions in a specific `Management Group`.  This is accomplished through a managmenent-group-scoped Azure Resource Manager (ARM) deployment.  The role definitions heirarchy can be modifed by editing `deploy.parameters.json`.  

Module deploys the following resources:

* Enclave Roles Definitions

The definitions created by the deployment is:

* Custom - VM Operator
* Custom - Network Operations (NetOps)
* Custom - Security Operations (SecOps)
* Custom - Landing Zone Application Owner
* Custom - Landing Zone Subscription Owner
* Custom - Storage Operator

## About Roles

The docs on Roles: <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/identity-access>. By default, this overlay will deploy resources into Management Groups. The role definitions are defined in [Identity and access management](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/identity-access) recommendations.

The Roles can be changed by providing the Management Group Id (Param: parAssignableScopeManagementGroupId) and ensuring that the Azure context is set the proper subscription.  

## Pre-requisites

* A organization tenant is available.
* Decide if the optional parameters is appropriate for your deployment. If it needs to change, override one of the optional parameters.

## Parameters

See below for information on how to use the appropriate deployment parameters for use with this overlay:

Required Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
| parRoleDefinitionInfo | object | {object} | Prefix for the role definition hierarchy.  This role definition will be created as part of the deployment.                                                    | role definition                   | `none`                 |
| parAssignableScopeManagementGroupId | string | `ANOA` | Name for default Management Group Id For role definitions. | Minimum two characters   |
| parUserAssignedIdentities | array   | `none`  | Set of User Assigned Identities to apply role definitions hierarchy of deployment | 

Optional Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
none

## Outputs

The module will generate the following outputs:

| Output | Type | Example |
| ------ | ---- | ------- |
None

## Deployment

In this overlay, the role definitions hierarchy are created at a specific `Management Group` through a managmenent-group-scoped deployment. The custom roles will be deployed to the 'ANOA' management group (the intermediate root management group).

Input parameter file parameters/deploy.parameters.all.json defines the assignable scope for the roles. In this case, it will be the same management group (i.e. 'ANOA') as the one specified for the deployment operation. There is no change in the input parameter file for different Azure clouds because there is no change to the intermediate root management group.

<h3>Overlay Example: Roles</h3>

<details>

<summary>via Bash</summary>

```bash
# For Azure Commerical regions
az login
cd src/bicep/overlays
cd roles
az deployment mg create \
   --name deploy-roles \
   --management-group-id 'ANOA' \
   --template-file overlays/roles/deploy.bicep \
   --parameters @overlays/roles/deploy.parameters.all.json \
   --location 'eastus'
```

```bash
# For Azure Government regions

# change Azure Clouds
az cloud set --name AzureUSGovernment

#sign  into AZ CLI, this will redirect you to a web browser for authentication, if required
az login
az deployment mg create \
   --name deploy-roles \
   --management-group-id 'ANOA' \
   --template-file overlays/roles/deploy.bicep \
   --parameters @overlays/roles/deploy.parameters.all.json \
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
  -Name deploy-roles `
  -ManagementGroupId xxxxxxx-xxxx-xxxxxx-xxxxx-xxxx
  -TemplateFile overlays/roles/deploy.bicep `
  -TemplateParameterFile overlays/roles/deploy.parameters.all.json `
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
  -Name deploy-roles `
  -ManagementGroupId xxxxxxx-xxxx-xxxxxx-xxxxx-xxxx
  -TemplateFile overlays/roles/deploy.bicep `
  -TemplateParameterFile overlays/roles/deploy.parameters.all.json `
  -Location  'usgovvirginia'
```
</details>
<p>

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Validate the deployment

Use the Azure portal, Azure CLI, or Azure PowerShell to verify that the custom role was created.

Configure the default group using:

```bash
az role definition list --name "Custom - Network Operations (NetOps)"
```

OR

```powershell
Get-AzRoleDefinition "Custom - Network Operations (NetOps)"
```

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator Roles deployment can be deleted with these steps:

Removes the `Custom - Network Operations (NetOps)` role from the anoauser@contoso.com user at the management group scope.

```bash
az role assignment delete --assignee "anoauser@contoso.com" \
--role "Custom - Network Operations (NetOps)" \
--scope "/providers/Microsoft.Management/managementGroups/anoa"
```

```powershell
Remove-AzRoleAssignment -SignInName anoauser@contoso.com `
-RoleDefinitionName "Custom - Network Operations (NetOps)" `
-Scope "/providers/Microsoft.Management/managementGroups/anoa"
```

## Example Output in Azure

![Example Deployment Output](images/operationsNetworkExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")

## References

* [Understand Azure role definitions](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-definitions)