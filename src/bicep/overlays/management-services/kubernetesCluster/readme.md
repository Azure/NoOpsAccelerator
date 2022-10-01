# Overlay: NoOps Accelerator - Azure Kubernetes Service - Cluster

## Overview

This overlay module deploys a Azure Kubernetes Service - Cluster suitable for hosting docker containers apps. The cluster will be deployed to the Hub/Spoke shared services resource group using default naming unless alternative values are provided at run time.

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## Deploy Azure Kubernetes Service - Cluster

The docs on Azure Kubernetes Service: <https://docs.microsoft.com/en-us/azure/aks/>.  By default, this overlay will deploy resources into standard default hub/spoke subscriptions and resource groups.  

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
parKubernetesCluster | object | {object} | The object parameters of the Azure Kubernetes Cluster.
parTargetSubscriptionId | string | `xxxxxx-xxxx-xxxx-xxxxx-xxxxxx` | The target subscription ID for the target Network and resources. It defaults to the deployment subscription.
parTargetResourceGroup | string | `anoa-eastus-platforms-hub-rg` | The name of the resource group in which the Azure Kubernetes Cluster will be deployed. If unchanged or not specified, the NoOps Accelerator will create an resource group to be used.
parTargetVNetName | string | `anoa-eastus-platforms-hub-vnet` | The name of the VNet in which the aks will be deployed. If unchanged or not specified, the NoOps Accelerator shared services resource group is used.
parTargetSubnetName | string | `anoa-eastus-platforms-hub-snet` | The name of the Subnet in which the aks will be deployed. If unchanged or not specified, the NoOps Accelerator shared services resource group is used.

## Deploy the Overlay

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying Hub/Spoke and then adding an Azure Kubernetes Service - Cluster post-deployment.

> NOTE: Since you can deploy this overlay post-deployment, you can also build this overlay within other deployment models such as Platforms & Workloads.

Once you have the hub/spoke output values, you can pass those in as parameters to this deployment.

> IMPORTANT: Please make sure that supperted versions are in the region that you are deploying to. Use `az aks get-verions` to understand what aks versions are supported per region.

For example, deploying using the `az deployment group create` command in the Azure CLI:

### Azure CLI

```bash
# For Azure Commerical regions
az login
cd src/bicep
cd platforms/lz-platform-scca-hub-3spoke
az deployment sub create \ 
--name contoso \
--subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
--template-file deploy.bicep \
--location eastus \
--parameters @parameters/deploy.parameters.json
cd overlays
cd kubernetesCluster
az deployment sub create \
   --name deploy-AKS-Network
   --template-file deploy.bicep \
   --parameters @parameters/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'eastus'
```

OR

```bash
# For Azure Government regions
az deployment group create \
  --name deploy-AKS-Network
   --template-file overlays/kubernetesCluster/deploy.bicep \
   --parameters @overlays/kubernetesCluster/parameters/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'usgovvirginia'
```

### PowerShell

```powershell
# For Azure Commerical regions
New-AzSubscriptionDeployment `
  -TemplateFile overlays/kubernetesCluster/deploy.bicepp `
  -TemplateParameterFile overlays/kubernetesCluster/parameters/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location 'eastus'
```

OR

```powershell
# For Azure Government regions
New-AzSubscriptionDeployment `
  -TemplateFile overlays/kubernetesCluster/deploy.bicepp `
  -TemplateParameterFile overlays/kubernetesCluster/parameters/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location  'usgovvirginia'
```

## Extending the Overlay

By default, this overlay has the minium parameters needed to deploy the service. If you like to add addtional parmeters to the service, please refer to the module description located in AzResources here: [Azure Kubernetes Services `[Microsoft.ContainerService/managedClusters]`](../../../azresources/Modules/Microsoft.ContainerRegistry/registries/readmd.md)

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Validate the deployment

Use the Azure portal, Azure CLI, or Azure PowerShell to list the deployed resources in the resource group.

Configure the default group using:

```bash
az configure --defaults group=anoa-eastus-workload-aks-rg.
```

```bash
az resource list --location eastus --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx --resource-group anoa-eastus-workload-aks-rg
```

OR

```powershell
Get-AzResource -ResourceGroupName anoa-eastus-workload-aks-rg
```

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Azure Kubernetes Service - Cluster deployment can be deleted with these steps:

### Delete Resource Groups

```bash
az group delete --name anoa-eastus-workload-aks-rg
```

OR

```powershell
Remove-AzResourceGroup -Name anoa-eastus-workload-aks-rg
```

### Delete Deployments

```bash
az deployment delete --name deploy-AKS-Network
```

OR

```powershell
Remove-AzSubscriptionDeployment -Name deploy-AKS-Network
```

## Example Output in Azure

![Example Deployment Output](media/aksNetworkExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")

### References

* [Introduction to private Docker container registries in Azure](https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans)
* [Azure Container Registry service tiers(Sku's)](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-skus)