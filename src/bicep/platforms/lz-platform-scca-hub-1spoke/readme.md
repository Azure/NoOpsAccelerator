# NoOps Accelerator - Platforms - SCCA Compliant Hub - 1 Spoke

## Overview

This platform module deploys Hub 1 Spoke landing zone.

> NOTE: This is only the landing zone deployment. The workloads will be deployed with the enclave or can be deployed after the landing zone is created.

Read on to understand what this landing zone does, and when you're ready, collect all of the pre-requisites, then deploy the landing zone.

## Architecture

 ![Hub/Spoke landing zone Architecture](./media/hub-1spoke-network-topology-architecture.jpg)

## About Hub 1 Spoke Landing Zone

The docs on Hub/Spoke Landing Zone: <https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke?tabs=cli>

### What is a Landing Zone?

A **landing zone** is networking infrastructure configured to provide a secure environment for hosting workloads.

[![Landing Zones Azure Academy Video](https://img.youtube.com/vi/9BKgz9Rl1eo/0.jpg)](https://youtu.be/9BKgz9Rl1eo "Don't let this happen to you 😮 Build A Landing Zone 👍 - Click to Watch!")

### Hub/Spoke Networking

Hub/ 1 Spoke Networking is set up in a hub and spoke design, separated by one tier: T1 (Infrastructure Operations). Access control can be configured to allow separation of duties between all tiers.

### Firewall

All network traffic is directed through the firewall residing in the Network Hub resource group. The firewall is configured as the default route for all the T0 (Identity and Authorization) through T3 (workload/team environments) resource groups as follows:

|Name         |Address prefix| Next hop type| Next hop IP address|
|-------------|--------------|-----------------|-----------------|
|default_route| 0.0.0.0/0    |Virtual Appliance|10.0.100.4*       |

*-example IP for firewall

### Tagging

Organize cloud resources to meet the needs of governance, operational management, and accounting. Resources can be managed and found more quickly with the aid of well-defined metadata tagging protocols. By using charge back and show back accounting procedures, these conventions also assist in tying cloud usage charges to specific business teams.

A tagging strategy include business and operational details:

* The business side of this strategy ensures that tags include the organizational information needed to identify the teams. Use a resource along with the business owners who are responsible for resource costs.
* The operational side ensures that tags include information that IT teams use to identify the workload, application, environment, criticality, and other information useful for managing resources.

## Pre-requisites

### Subscriptions

Most customers will deploy each tier to a separate Azure subscription, but multiple subscriptions are not required. A single subscription deployment is good for a testing and evaluation, or possibly a small IT Admin team.

### Operational Network Artifacts

If needed, The Operational Network Artifacts are used when operations wants to seperate all key, secrets and operations storage from the hub/spoke model.

### DDOS

If needed, You can dpeloy an DDOS Standard configuration if a firewall is not needed.

## Parameters

See below for information on how to use the appropriate deployment parameters for use with this landing zone:

Required Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
parRequired | object | {object} | Required values used with all resources.
parTags | object | {object} | Required tags values used with all resources.
parLocation | string | `[deployment().location]` | The region to deploy resources into. It defaults to the deployment location.
parHub | object | {object} | Hub Virtual network configuration. See [azresources/hub-spoke-core/vdss/hub/readme.md](../../azresources/hub-spoke-core/vdss/hub/readme.md)
parOperationsSpoke | object | {object} | Operations Spoke Virtual network configuration. See [See azresources/hub-spoke-core/vdms/operations/readme.md](../../azresources/hub-spoke-core/vdms/operations/readme.md)
parAzureFirewall | object | {object} | Azure Firewall configuration. Azure Firewall is deployed in Forced Tunneling mode where a route table must be added as the next hop.
parLogging | object | {object} | Enables logging parmeters and Microsoft Sentinel within the Log Analytics Workspace created in this deployment. See [azresources/hub-spoke-core/vdms/logging/readme.md](../../azresources/hub-spoke-core/vdms/logging/readme.md)
parRemoteAccess | object | {object} | When set to "true", provisions Azure Bastion Host. It defaults to "false". See [overlays/management-services/bastion/readme.md](../../overlays/management-services/bastion/readme.md)

Optional Parameters | Type | Allowed Values | Description
| :-- | :-- | :-- | :-- |
parNetworkArtifacts | object | {object} | Optional. Enables Operations Network Artifacts Resource Group with KV and Storage account for the ops subscriptions used in the deployment. This overlay allows Bastion keys to be added if Basion Host is enabled. See [azresources/hub-spoke-core/vdss/networkArtifacts/readme.md](../../azresources/hub-spoke-core/vdss/networkArtifacts/readme.md)
parSecurityCenter | object | {object} | Microsoft Defender for Cloud.  It includes email and phone. See [overlays/management-services/defender/readme.md](../../overlays/management-services/defender/readme.md)
parDdosStandard | bool | `false` | DDOS Standard configuration.

## Deploy the Landing Zone

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell or Azure CLI for help if needed. The commands below assume you are deploying in Azure Commercial and show the entire process deploying Platform Hub/Spoke Design.

For example, deploying using the `az deployment sub create` command in the Azure CLI:

### Azure CLI

```bash
# For Azure Commerical regions
az login
cd src/bicep
cd platforms/lz-platform-scca-hub-1spoke
az deployment sub create \ 
--name contoso \
--subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
--template-file platforms/lz-platform-scca-hub-1spoke/deploy.bicep \
--location eastus \
--parameters @platforms/lz-platform-scca-hub-1spoke/parameters/deploy.parameters.json
```

OR

```bash
# For Azure Government regions
az deployment sub create \
  --template-file platforms/lz-platform-scca-hub-1spoke/deploy.bicep \
  --parameters @platforms/lz-platform-scca-hub-1spoke/parameters/deploy.parameters.json \
  --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx \
  --resource-group anoa-usgovvirginia-platforms-hub-rg \
  --location 'usgovvirginia'
```

### PowerShell

```powershell
# For Azure Commerical regions
New-AzSubscriptionDeployment `
  -TemplateFile platforms/lz-platform-scca-hub-1spoke/deploy.bicepp `
  -TemplateParameterFile platforms/lz-platform-scca-hub-1spoke/parameters/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location 'eastus'
```

OR

```powershell
# For Azure Government regions
New-AzSubscriptionDeployment `
  -TemplateFile platforms/lz-platform-scca-hub-1spoke/deploy.bicepp `
  -TemplateParameterFile platforms/lz-platform-scca-hub-1spoke/parameters/deploy.parameters.json `
  -Subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx `
  -Location  'usgovvirginia'
```

## Extending the Landing Zone

By default, this Landing Zone has the minium parmeters needed to deploy the service. If you like to add addtional parmeters to the Landing Zone, please refer to the Landing Zone description located in AzResources here: [`Hub-Spoke-Core`](../../azresources/hub-spoke-core/readme.md)

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Validate the deployment

Use the Azure portal, Azure CLI, or Azure PowerShell to list the deployed resources in the resource group.

Configure the default group using:

```bash
az configure --defaults group=anoa-eastus-platforms-hub-rg.
```

```bash
az resource list --location eastus --subscription xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx --resource-group anoa-eastus-platforms-hub-rg
```

```powershell
Get-AzResource -ResourceGroupName anoa-eastus-platforms-hub-rg
```

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Hub/Spoke deployment can be deleted with these steps:

### Delete Resource Groups

```bash
az group delete -n anoa-eastus-platforms-logging-rg -y
az group delete -n anoa-eastus-platforms-hub-rg -y
az group delete -n anoa-eastus-platforms-operations-rg -y
az group delete -n anoa-eastus-platforms-artifacts-rg -y
```

```powershell
Remove-AzResourceGroup -Name anoa-eastus-platforms-logging-rg
Remove-AzResourceGroup -Name anoa-eastus-platforms-hub-rg
Remove-AzResourceGroup -Name anoa-eastus-platforms-operations-rg
Remove-AzResourceGroup -Name anoa-eastus-platforms-artifacts-rg
```

### Delete Deployments

```bash
az deployment sub delete -n deploy-hubspoke-network
```

```powershell
Remove-AzSubscriptionDeployment -Name deploy-hubspoke-network
```