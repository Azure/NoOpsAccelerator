# Overlays:   NoOps Accelerator - Application Gateway

## Overview

This overlay module adds an web traffic load balancer that enables you to manage traffic to your web applications. This application gateway is meant to be in the Hub Network.

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

### Azure CLI

```bash
# For Azure global regions
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
   --name deploy-AppGateway
   --template-file overlays/app-service-plan/deploy.bicep \
   --parameters @overlays/app-service-plan/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'eastus'
```

OR

```bash
# For Azure IL regions
az deployment sub create \
  --template-file overlays/app-service-plan/deploy.bicep \
  --parameters @overlays/app-service-plan/deploy.parameters.json \
  --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
  --resource-group anoa-usgovvirginia-platforms-hub-rg \
  --location 'usgovvirginia'
```

### PowerShell

```powershell
# For Azure global regions
New-AzSubscriptionDeployment `
  -TemplateFile overlays/app-service-plan/deploy.bicepp `
  -TemplateParameterFile overlays/app-service-plan/deploy.parameters.example.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location 'eastus'
```

OR

```powershell
# For Azure IL regions
New-AzSubscriptionDeployment `
  -TemplateFile overlays/app-service-plan/deploy.bicepp `
  -TemplateParameterFile overlays/app-service-plan/deploy.parameters.example.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location  'usgovvirginia'
```

## Extending the Overlay

By default, this overlay has the minium parmeters needed to deploy the service. If you like to add addtional parmeters to the service, please refer to the module description located in AzResources here: [`App Service Plans `[Microsoft.Web/serverfarms]`](D:\source\repos\NoOpsAccelerator\src\bicep\azresources\Modules\Microsoft.Web\serverfarms\readme.md)

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Validate the deployment

Use the Azure portal, Azure CLI, or Azure PowerShell to list the deployed resources in the resource group.

```bash
az resource list --resource-group anoa-eastus-dev-appplan-rg
```

```powershell
Get-AzResource -ResourceGroupName anoa-eastus-dev-appplan-rg
```

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Application Gateway deployment can be deleted with these steps:

### Delete Resource Groups

```bash
az group delete --name anoa-eastus-dev-appgateway-rg
```

```powershell
Remove-AzResourceGroup -Name anoa-eastus-dev-appgateway-rg
```

### Delete Deployments

```bash
az deployment delete --name deploy-AppGateway
```

```powershell
Remove-AzSubscriptionDeployment -Name deploy-AppGateway
```

## Example Output in Azure

![App Gateway Example Deployment Output](media/agwExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")
