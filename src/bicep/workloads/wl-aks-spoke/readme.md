# Workloads: NoOps Accelerator - Tier 3 Spoke - Azure Kubernetes Service

## Overview

This workload module creates a Workload [Tier 3 Spoke Network](../../azresources/hub-spoke-core/tier3/README.md) deployment that deploys a Private Azure Kubernetes Service with RBAC enabled, if required. A Azure Kubernetes Service utilizes hardware security modules to protect key material. Roles for use must be assigned post-deployment, review reference list below for detailed information.

Read on to understand what this workload does, and when you're ready, collect all of the pre-requisites, then deploy the workload.

## Architecture

 ![Private Azure Kubernetes Service](./media/AKSPrivateClusterTier3.jpg)

> **NOTE:** You have to deploy this Policy, Service Alerts and Budgets in post-deployment. View [Overlay Management Services folder](../../overlays/management-services/)

## About Azure Container Registry

The docs on Azure Container Registry: <https://docs.microsoft.com/en-us/azure/container-registry/>. By default, this workload uses the Azure Container Registry workload to deploy resources into [Platform Hub 1 Spoke Network](../../../bicep/platforms/lz-platform-scca-hub-1spoke/readme.md).  

## About Azure Kubernetes Service - Private Cluster

The docs on Azure Kubernetes Service: <https://docs.microsoft.com/en-us/azure/aks/>.  this workload uses the Azure Kubernetes Service - Cluster workload to deploy resources into [Platform Hub 1 Spoke Network](../../../bicep/platforms/lz-platform-scca-hub-1spoke/readme.md).  

## Pre-requisites

1. A virtual network and subnet is deployed.
1. Decide if the optional parameters is appropriate for your deployment. If it needs to change, override one of the optional parameters.

See below for information on how to use the appropriate deployment parameters for use with this workload:

Required Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
parRequired | object | {object} | Required values used with all resources.
parTags | object | {object} | Required tags values used with all resources.
parLocation | string | `[deployment().location]` | The region to deploy resources into. It defaults to the deployment location.
parWorkload | object | {object} | Required values used for workloads.
parHubSubscriptionId | string | `xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx` | The subscription ID for the Hub Network.
parHubResourceGroupName | string | `anoa-eastus-platforms-hub-rg` | The resource group name for the Hub Network.
parHubVirtualNetworkName | string | `anoa-eastus-platforms-hub-vnet` | The virtual network name for the Hub Network.
parHubVirtualNetworkResourceId | string | `/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourceGroups/anoa-eastus-platforms-hub-rg/providers/Microsoft.Network/virtualNetworks/anoa-eastus-platforms-hub-vnet/subnets/anoa-eastus-platforms-hub-vnet` | The resource ID of the virtual network for the Hub Network.
parHubFirewallPolicyName | string | `anoa-eastus-dev-hub-afwp` | The name of the Firewall Policy in the Hub Virtual Network that hosts rules for Hub Subnet traffic
parFirewallPrivateIPAddress | string | `10.0.100.4` | The private ip address of the Firewall in the Hub Virtual Network.
parLogAnalyticsWorkspaceResourceId | string | `/subscriptions/xxxxxxxx-xxxxxx-xxxxx-xxxxxx-xxxxxx/resourcegroups/anoa-eastus-dev-logging-rg/providers/microsoft.operationalinsights/workspaces/anoa-eastus-dev-logging-log` | Log Analytics Workspace Resource Id.
parLogAnalyticsWorkspaceId | string | `anoa-eastus-dev-logging-log` | Log Analytics Workspace Resource Id
parSourceAddresses | array | `10.0.100.4` | Log Analytics Workspace Resource Id
parKubernetesCluster | object | {object} | The object parameters of the Azure Kubernetes Cluster. Found at [Azure Kubernetes Cluster](../../../bicep/overlays/management-services/kubernetesCluster/readme.md)
parContainerRegistry | object | {object} | Defines the Container Registry. Found at [Azure Container Registry](../../../bicep/overlays/management-services/containerRegistry/readme.md)
parStorageAccountAccess | object | {object} | Defines the Storage Account Access.

Optional Parameters | Description
------------------- | -----------
None

## Outputs

| Output | Type
| ------ | ----
azureKubernetesName | string |
azureKubernetesResourceId | string |
azureContainerRegistryResourceId | string |
workloadResourceGroupName | string |
tags | string |

## Deploy the Workload

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure CLI/PowerShell for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying Hub/Spoke and then adding an Azure Kubernetes Service - Cluster post-deployment.

> NOTE: Since you can deploy this workload post-deployment, you can also build this workload within other deployment models such as other Platforms & Enlaves.

Once you have the hub/spoke output values, you can pass those in as parameters to this workload deployment.

> IMPORTANT: Please make sure that supperted versions are in the region that you are deploying to. Use `az aks get-verions` to understand what aks versions are supported per region.

For example, deploying using the `az deployment group create` command in the Azure CLI:

### Azure CLI

```bash
# For Azure Commerical regions
az login
cd src/bicep
cd platforms/lz-platform-scca-hub-1spoke
az deployment sub create \ 
--name contoso \
--subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
--template-file deploy.bicep \
--location eastus \
--parameters @parameters/deploy.parameters.json
cd workloads
cd wl-aks-spoke
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
   --template-file workloads/wl-aks-spoke/deploy.bicep \
   --parameters @workloads/wl-aks-spoke/parameters/deploy.parameters.json \
   --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
   --location 'usgovvirginia'
```

### PowerShell

```powershell
# For Azure Commerical regions
New-AzSubscriptionDeployment `
  -TemplateFile workloads/wl-aks-spoke/deploy.bicepp `
  -TemplateParameterFile workloads/wl-aks-spoke/parameters/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location 'eastus'
```

OR

```powershell
# For Azure Government regions
New-AzSubscriptionDeployment `
  -TemplateFile workloads/wl-aks-spoke/deploy.bicepp `
  -TemplateParameterFile workloads/wl-aks-spoke/parameters/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location  'usgovvirginia'
```

## Extending the Workload

By default, this workload has the minium parameters needed to deploy the service. If you like to add addtional parmeters to the service, please refer to the modules description located in AzResources here: 

* [Azure Kubernetes Services `[Microsoft.ContainerService/managedClusters]`](../../../azresources/Modules/Microsoft.ContainerRegistry/registries/readmd.md)
* [Container Registries `[Microsoft.ContainerRegistry/registries]`](../../../azresources/Modules/Microsoft.ContainerRegistry/registries/readmd.md)

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
Get-AzResource -ResourceGroupName anoa-eastus-workload-aks-rg -subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx -location eastus
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

## References

* [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
* [Azure Kubernetes Service Overview](https://docs.microsoft.com/en-us/azure/aks/intro-kubernetes)
