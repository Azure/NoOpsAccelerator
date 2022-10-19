# Hub/Spoke Core Module:   NoOps Accelerator - Identity Spoke Network

## Overview

This module defines Identity spoke network deployment based on the recommendations from the Azure Mission Landing Zone Conceptual Architecture.  

Module deploys the following resources:

* Virtual Network (VNet)
* Subnets
* Network Security Group
* Storage Account

## Required Parameters

The module requires the following inputs:

| Parameter                         | Type   | Default                                                                                              | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Required                   | Example                                        |
 | --------------------------------- | ------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- | ---------------------------------------------- |
| parOrgPrefix                       | string | `aona`                                                                           | Prefix value which will be prepended to all resource names. Default: anoa                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Yes                          | `aona`
| parLocation                       | string | `resourceGroup().location`                                                                           | The Azure Region to deploy the resources into                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Yes                          | `eastus`
| parTemplateVersion                       | string | `1.0`                                                                           | The ANOA template version                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Yes                          | `1.o`
| parDeployEnvironment                       | string | None                                                                           | A suffix, 3 to 15 characters in length, to append to resource names (e.g. "dev", "test", "prod", "platforms"). It defaults to "platforms".'                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Yes                          | `platforms`
| parResourcePrefix                       | string | None                       | A prefix, 3-15 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Yes                          | None

## Identity Network Parameters

The module requires the following inputs for Identity Network:

| Parameter                                | Type   | Default                    | Description                                                                                                                                                                                                                          | Required | Example                    |
|------------------------------------------|--------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|----------------------------|
| parIdentitySubscriptionId                     | string | `guid`                     | The subscription ID for the Identity Network and resources. It defaults to the deployment subscription                                                                                                                                    | No       | `xxxx-xxxx-xxxx-xxxx-xxxx` | Yes| None |
parIdentityVirtualNetworkAddressPrefix | string | No       | The CIDR Virtual Network Address Prefix for the Identity Virtual Network. | Yes| None |
parIdentitySubnetAddressPrefix | string | No       | The CIDR Subnet Address Prefix for the default Identity subnet. It must be in the Identity Virtual Network space.| Yes| None |
parSourceAddressPrefixes | string | No       | The CIDR Virtual Network Address Prefix for the Identity/Identity Virtual Network. Leave blank if no spokes are needed. | Yes| None |
parLogStorageSkuName | string | No       | The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See <https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types> for valid settings.. | Yes| None |
parIdentityVirtualNetworkDiagnosticsLogs | array | No       | An array of Network Diagnostic Logs to enable for the Identity Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs> for valid settings. | Yes| None |
parIdentityVirtualNetworkDiagnosticsMetrics | array | No       | An array of Network Diagnostic Metrics to enable for the Identity Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/> diagnostic-settings?tabs=CMD#metrics for valid settings. | Yes| None |
parIdentityNetworkSecurityGroupRules | array | No       | An array of Network Security Group rules to apply to the Identity Virtual Network. See <https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat> for valid settings. | Yes| None |
parIdentityNetworkSecurityGroupDiagnosticsLogs | array | No       | An array of Network Security Group diagnostic logs to apply to the Identity Virtual Network. See <https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories> for valid settings. | Yes| None |
parIdentityNetworkSecurityGroupDiagnosticsMetrics | array | No       | An array of Network Security Group Diagnostic Metrics to enable for the Identity Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics> for valid settings. | Yes| None |
parIdentitySubnetServiceEndpoints | array | No       | An array of Service Endpoints to enable for the Identity subnet. See <https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview> for valid settings. | Yes| None |
parLogAnalyticsWorkspaceResourceId | string | No       | . | Yes| None |
parFirewallPrivateIPAddress | string | No       | . | Yes| None |
parRouteTableRouteName | string | No       | . | Yes| None |
parRouteTableRouteAddressPrefix | string | No       | . | Yes| None |
parRouteTableRouteNextHopIpAddress | string | No       | . | Yes| None |
parRouteTableRouteNextHopType | string | No       | . | Yes| None |
parStorageAccountAccessObjectId | string | No       | . | Yes| None |
parStorageAccountAccessType | string | No       | . | Yes| None |
parAddRoleAssignmentForStorageAccount | bool | No       | . | Yes| None |

Parameters file located in the [Deployments](../../../../deployments/HubSpoke/networking/identity/) folder under hub/spoke.

## Outputs

The module will generate the following outputs:

table

## Deployment

> **Note:** `bicepconfig.json` file is included in the module directory.  This file allows us to override Bicep Linters.  Currently there are two URLs which were removed because of linter warnings.  URLs removed are the following: database.windows.net and core.windows.net

In this example, the Identity (Tier 2) resources will be deployed to the resource group specified. According to the Azure Mission Landing Zone Conceptual Architecture, the operations resources should be deployed into the Platform Management subscription. During the deployment step, we will take the default values and not pass any parameters.

Other differences in Azure IL regions are as follow:

 | Azure Cloud    | Bicep template      | Input parameters file                    |
 | -------------- | ------------------- | ---------------------------------------- |
 | Global regions | anoa.lz.id.network.bicep | anoa.lz.id.network.parameters.json    |
 | IL regions  | anoa.lz.id.network.bicep | anoa.lz.id.network.parameters.il.json |

> For the examples below we assume you have downloaded or cloned the Git repo as-is and are in the root of the repository as your selected directory in your terminal of choice.

### Azure CLI

```bash
# For Azure Commerical regions

# Set Platform connectivity subscription ID as the the current subscription 

ConnectivitySubscriptionId="[your platform management subscription ID]"
az account set --subscription $ConnectivitySubscriptionId

az deployment sub create \
   --location eastus \
   --template-file src/bicep/common/landingzone/core/vdms/identity/anoa.lz.id.network.bicep \
   --parameters @src/bicep/common/landingzone/core/vdms/identity/anoa.lz.id.network.parameters.json
```

OR

```bash

# For Azure Government regions

# Set Platform connectivity subscription ID as the the current subscription 

ConnectivitySubscriptionId="[your platform management subscription ID]"
az account set --subscription $ConnectivitySubscriptionId

az deployment sub create \
   --location virginiaus \
   --template-file src/bicep/common/landingzone/core/vdms/identity/anoa.lz.id.network.bicep \
   --parameters @src/bicep/common/landingzone/core/vdms/identity/anoa.lz.id.network.parameters.json
```

### PowerShell

```powershell
# For Azure Commerical regions
# Set Platform connectivity subscription ID as the the current subscription 
$ConnectivitySubscriptionId = "[your platform management subscription ID]"

Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId
  
New-AzDeployment `
  -TemplateFile src/bicep/common/landingzone/core/vdms/identity/anoa.lz.id.network.bicep `
  -TemplateParameterFile src/bicep/common/landingzone/core/vdms/identity/anoa.lz.id.network.parameters.json `
  -Location 'eastus'
```

OR

```powershell

# For Azure Government regions
# Set Platform connectivity subscription ID as the the current subscription 
$ConnectivitySubscriptionId = "[your platform management subscription ID]"

Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId
  
New-AzDeployment `
  -TemplateFile src/bicep/common/landingzone/core/vdms/identity/anoa.lz.id.network.bicep `
  -TemplateParameterFile src/bicep/common/landingzone/core/vdms/identity/anoa.lz.id.network.parameters.json `
  -Location 'virginiaus'
```

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator Identity network deployment can be deleted with these steps:

## Example Output in Azure

![Example Deployment Output](media/identityNetworkExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")