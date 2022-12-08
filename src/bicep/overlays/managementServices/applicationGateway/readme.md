# Overlays: Application Gateway

## Overview

This overlay module adds an web traffic load balancer that enables you to manage traffic to your web applications. This application gateway is meant to be in the Hub Network of the deployed hub/spoke design.

Read on to understand what this overlay does, and when you're ready, collect all of the pre-requisites, then deploy the overlay

## About Application Gateway

The docs on Application Gateway : <https://docs.microsoft.com/en-us/azure/application-gateway/overview>

Some particulars about Application Gateway:

* Supports Secure Sockets Layer (SSL/TLS) termination
* Supports Autoscaling
* Zone redundancy
* Can be a Web Application Firewall
* Ingress Controller for AKS

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
hubResourceGroupName | The resource group that contains the Hub Virtual Network and deploy the virtual machines into
hubVirtualNetworkName | The resource to deploy a subnet configured for Bastion Host
hubSubnetResourceId | The resource ID of the subnet in the Hub Virtual Network for hosting virtual machines
hubNetworkSecurityGroupResourceId | The resource ID of the Network Security Group in the Hub Virtual Network that hosts rules for Hub Subnet traffic

## Deploy the Overlay

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell or Azure CLI for help if needed. The commands below assume you are deploying in Azure Commercial and show the entire process from deploying Platform Hub/Spoke Design and then adding an Application Gateway post-deployment.

> NOTE: Since you can deploy this overlay post-deployment, you can also build this overlay within other deployment models such as Platforms & Workloads.

Once you have the hub/spoke output values, you can pass those in as parameters to this deployment.

For example, deploying using the `az deployment sub create` command in the Azure CLI:

<h3>Overlay Example: Application Gateway</h3>

<details>

<summary>via Bash</summary>

```bash
# For Azure Commerical regions

#sign  into AZ CLI, this will redirect you to a web browser for authentication, if required
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
cd applicationGateway
az deployment sub create \
   --name deploy-AppGateway
   --template-file overlays/applicationGateway/deploy.bicep \
   --parameters @overlays/applicationGateway/parameters/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'eastus'
```

OR

```bash
# For Azure Government regions

# change Azure Clouds
az cloud set --name AzureUSGovernment

#sign  into AZ CLI, this will redirect you to a web browser for authentication, if required
az login
cd src/bicep/overlays
cd applicationGateway
az deployment sub create \
  --template-file overlays/applicationGateway/deploy.bicep \
  --parameters @overlays/applicationGateway/parameters/deploy.parameters.json \
  --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
  --resource-group anoa-usgovvirginia-platforms-hub-rg \
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

New-AzSubscriptionDeployment `
  -TemplateFile overlays/applicationGateway/deploy.bicepp `
  -TemplateParameterFile overlays/applicationGateway/parameters/deploy.parameters.example.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
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

New-AzSubscriptionDeployment `
  -TemplateFile overlays/applicationGateway/deploy.bicepp `
  -TemplateParameterFile overlays/applicationGateway/parameters/deploy.parameters.example.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location  'usgovvirginia'
```

</details>
<p>

## Extending the Overlay

By default, this overlay has the minium parmeters needed to deploy the service. If you like to add addtional parmeters to the service, please refer to the module description located in AzResources here: [`Network Application Gateways [Microsoft.Network/applicationGateways]`](../../../azresources/Modules/Microsoft.Network/applicationGateway/readme.md)

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Validate the deployment

Use the Azure portal, Azure CLI, or Azure PowerShell to list the deployed resources in the resource group.

Configure the default group using:

```bash
az configure --defaults group=anoa-eastus-dev-appGateway-rg.
```

```bash
az resource list --location eastus --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx --resource-group anoa-eastus-dev-appGateway-rg
```

OR

```powershell
Get-AzResource -ResourceGroupName anoa-eastus-dev-appGateway-rg
```

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Application Gateway deployment can be deleted with these steps:

### Delete Resource Groups

```bash
az group delete --name anoa-eastus-dev-appgateway-rg
```

OR

```powershell
Remove-AzResourceGroup -Name anoa-eastus-dev-appgateway-rg
```

### Delete Deployments

```bash
az deployment delete --name deploy-AppGateway
```

OR

```powershell
Remove-AzSubscriptionDeployment -Name deploy-AppGateway
```

## Example Output in Azure

![App Gateway Example Deployment Output](media/agwExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")

### References

* [Azure Application Gateway Documentation](https://docs.microsoft.com/en-us/azure/application-gateway//)
* [Azure Application Gateway Overview](https://docs.microsoft.com/en-us/azure/application-gateway/overview)
* [Overview of TLS termination and end to end TLS with Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/ssl-overview)