# Hub/Spoke Core Module: NoOps Accelerator - Hub Network

## Overview

This module defines hub network deployment based on the recommendations from the Azure Mission Landing Zone Conceptual Architecture.  

Module deploys the following resources:

* Virtual Network (VNet)
* Subnets
* Azure Firewall
* Private DNS Zones - Details of all the Azure Private DNS zones can be found here --> [https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration)
* DDos Standard Plan

## Hub Network Parameters

The module requires the following inputs for Hub Network:

| Parameter                                | Type   | Default                    | Description                                                                                                                                                                                                                          | Required | Example                    |
|------------------------------------------|--------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|----------------------------|
| parOrgPrefix                             | string | `org`                      | Prefix value which will be prepended to all resource names. Default: org                                                                                                                                                             | Yes      | `org`                      |
| parHubSubscriptionId                     | string | `guid`                     | The subscription ID for the Hub Network and resources. It defaults to the deployment subscription                                                                                                                                    | No       | `xxxx-xxxx-xxxx-xxxx-xxxx` |
| parLocation                              | string | `resourceGroup().location` | The Azure Region to deploy the resources into                                                                                                                                                                                        | Yes      | `eastus`                   |
| parTemplateVersion                       | string | `1.0`                      | The ANOA template version                                                                                                                                                                                                            | Yes      | `1.0`                      |
| parDeployEnvironment                     | string | `platforms`                | A suffix, 3 to 15 characters in length, to append to resource names (e.g. "dev", "test", "prod", "platforms"). It defaults to "platforms".                                                                                           | Yes      | `platforms`                |
| parResourcePrefix                        | string | None                       | A prefix, 3-10 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces                | None     | None                       |
| parDeployArtifacts                       | bool   | true                       | When set to "true", enables Artifacts Resource Group with KV and Storage account for the subscriptions used in the deployment. It defaults to "false".                                                                               | None     | false                      |
| parKeyVaultPolicies                      | array  |                            |                                                                                                                                                                                                                                      |          |                            |
| parDeploymentNameSuffix                  | string | utcNow()                   | A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.                                                                                                                     | None     | utcNow()                   |
| parHubVirtualNetworkAddressPrefix        | string | '10.0.100.0/24'            | The CIDR Virtual Network Address Prefix for the Hub Virtual Network.                                                                                                                                                                 | Yes      | '10.0.100.0/24'            |
| parHubSubnetAddressPrefix                | string | '10.0.100.128/27'          | The CIDR Subnet Address Prefix for the default Hub subnet. It must be in the Hub Virtual Network space.                                                                                                                              | Yes      | '10.0.100.128/27'          |
| parFirewallClientSubnetAddressPrefix     | string | '10.0.100.0/26'            | The CIDR Subnet Address Prefix for the Azure Firewall Subnet. It must be in the Hub Virtual Network space. It must be /26.                                                                                                           | Yes      | '10.0.100.0/26'            |
| parFirewallManagementSubnetAddressPrefix | string | '10.0.100.64/26'           | The CIDR Subnet Address Prefix for the Azure Firewall Management Subnet. It must be in the Hub Virtual Network space. It must be /26.                                                                                                | Yes      | '10.0.100.64/26'           |
| parAzureFirewallEnabled                  | bool   | true                       | Switch which allows Azure Firewall deployment to be disabled. Default: true                                                                                                                                                          | Yes      | false                      |
| parFirewallSkuTier                       | string | 'Standard'                 | [Standard/Premium] The SKU for Azure Firewall. It defaults to "Premium".                                                                                                                                                             | Yes      | 'Standard' or 'Premium'    |
| parFirewallSupernetIPAddress             | string | '10.0.96.0/19'             | Supernet CIDR address for the entire network of vnets, this address allows for communication between spokes. Recommended to use a Supernet calculator if modifying vnet addresses                                                    | Yes      | '10.0.96.0/19'             |
| parFirewallThreatIntelMode               | string | Alert                      | [Alert/Deny/Off] The Azure Firewall Threat Intelligence Rule triggered logging behavior. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".                                                                   | No       | Alert/Deny/Off             |
| parFirewallIntrusionDetectionMode        | string | Alert                      | [Alert/Deny/Off] The Azure Firewall Intrusion Detection mode. Valid values are "Alert", "Deny", or "Off". The default value is "Alert".                                                                                              | No       | Alert/Deny/Off             |
| parFirewallDiagnosticsLogs               | array  | None                       | An array of Firewall Diagnostic Logs categories to collect. See "https://docs.microsoft.com/en-us/azure/firewall/firewall-diagnostics#enable-diagnostic-logging-through-the-azure-portal" for valid values.                          | No       | None                       |
| parFirewallDiagnosticsMetrics                         | array  | None                            | An array of Firewall Diagnostic Metrics categories to collect. See "https://docs.microsoft.com/en-us/azure/firewall/firewall-diagnostics#enable-diagnostic-logging-through-the-azure-portal" for valid values.                                                                       | No  | None                            |
| parFirewallClientSubnetName                           | string | 'AzureFirewallSubnet'           | Subnet name for the Firewall Default is "AzureFirewallSubnet"                                                                                                                                                                                                                        | Yes | 'AzureFirewallSubnet'           |
| parFirewallClientSubnetServiceEndpoints               | array  | None                            | An array of Service Endpoints to enable for the Azure Firewall Client Subnet. See <https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview> for valid settings.                                                                              | No  | None                            |
| parFirewallClientPublicIPAddressAvailabilityZones     | array  | None                            | An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See <https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku> for valid settings. | No  | None                            |
| parFirewallManagementSubnetName                       | string | 'AzureFirewallManagementSubnet' | Subnet name for the Firewall Default is "AzureFirewallManagementSubnet"                                                                                                                                                                                                              | Yes | 'AzureFirewallManagementSubnet' |
| parFirewallManagementSubnetServiceEndpoints           | array  | None                            | An array of Service Endpoints to enable for the Azure Firewall Management Subnet. See <https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview> for valid settings.                                                                          | No  | None                            |
| parFirewallManagementPublicIPAddressAvailabilityZones | array  | None                            | An array of Azure Firewall Public IP Address Availability Zones. It defaults to empty, or "No-Zone", because Availability Zones are not available in every cloud. See <https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses#sku> for valid settings. | No  | None                            |
| parHubVirtualNetworkDiagnosticsLogs                   | array  | None                            | An array of Network Diagnostic Logs to enable for the Hub Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs> for valid settings.                                                                                 | No  | None                            |
| parHubVirtualNetworkDiagnosticsMetrics                | array  | None                            | An array of Network Diagnostic Metrics to enable for the Hub Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics> for valid settings.                                                                           | No  | None                            |
| parHubNetworkSecurityGroupRules                       | array  | None                            | An array of Network Security Group Rules to apply to the Hub Virtual Network. See <https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat> for valid settings.                                 | No  | None                            |
| parHubNetworkSecurityGroupDiagnosticsLogs             | array  | None                            | An array of Network Security Group diagnostic logs to apply to the Hub Virtual Network. See <https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories> for valid settings.                                                                 | No  | None                            |
| parHubNetworkSecurityGroupDiagnosticsMetrics          | array  | None                            | An array of Network Security Group Metrics to apply to enable for the Hub Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics> for valid settings.                                                              | No  | None                            |
| parHubSubnetServiceEndpoints                          | array  | None                            | An array of Service Endpoints to enable for the Hub subnet. See <https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview> for valid settings.                                                                                                | No  | None                            |
| parRouteTableRouteName                                | string | 'default_route'                 | Name of the Route Table for the Hub Network                                                                                                                                                                                                                                          | Yes | 'default_route'                 |
| parRouteTableRouteAddressPrefix                       | string | '0.0.0.0/0'                     |                                                                                                                                                                                                                                                                                      | Yes | '0.0.0.0/0'                     |
| parRouteTableRouteNextHopType                         | string | 'VirtualAppliance'              |                                                                                                                                                                                                                                                                                      | Yes | 'VirtualAppliance'              |
| parLogStorageSkuName                                  | string | 'Standard_GRS'                  | The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See <https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types> for valid settings.                                                                                                             | Yes | 'Standard_GRS'                  |
| parLogAnalyticsWorkspaceResourceId                    | string |                                 |                                                                                                                                                                                                                                                                                      |     |                                 |
| parPublicIPAddressDiagnosticsLogs                     | array  | None                            | An array of Public IP Address Diagnostic Logs for the Azure Firewall. See <https://docs.microsoft.com/en-us/azure/ddos-protection/diagnostic-logging?tabs=DDoSProtectionNotifications#configure-ddos-diagnostic-logs> for valid settings.                                              | Yes | None                            |
| parPublicIPAddressDiagnosticsMetrics                  | array  | None                            | An array of Public IP Address Diagnostic Metrics for the Azure Firewall. See <https://docs.microsoft.com/en-us/azure/ddos-protection/diagnostic-logging?tabs=DDoSProtectionNotifications> for valid settings.                                                                          | Yes | None                            |
| parDeployddosProtectionPlan           | bool   | true                             |                                  | Yes | false                      |
| parSupportedClouds                    | array  | 'AzureCloud'/'AzureUSGovernment' |                                  | Yes | 'AzureCloud'               |
| parStorageAccountAccessObjectId       | string | None                             | Group Id for Storage account     | Yes | 'xxxx-xxxx-xxxx-xxxx-xxxx' |
| parStorageAccountAccessType           | string | None                             | Account Type for Storage account | Yes | 'Group                     |
| parAddRoleAssignmentForStorageAccount | bool   | true                             |                                  | Yes | false                      |

Parameters file located in the [Deployments](../../../../deployments/HubSpoke/networking/hub/) folder under hub/spoke.

## Outputs

The module will generate the following outputs:

table

## Deployment

> **Note:** `bicepconfig.json` file is included in the module directory.  This file allows us to override Bicep Linters.  Currently there are two URLs which were removed because of linter warnings.  URLs removed are the following: database.windows.net and core.windows.net

In this example, the Hub (Tier 0) resources will be deployed to the resource group specified. According to the Azure Mission Landing Zone Conceptual Architecture, the hub resources should be deployed into the Platform Connectivity subscription. During the deployment step, we will take the default values and not pass any parameters.

There are two different sets of input parameters; one for deploying to Azure global regions, and another for deploying specifically to Azure IL regions. This is due to different private DNS zone names for Azure services in Azure global regions and Azure IL. The recommended private DNS zone names are available [here](https://docs.microsoft.com/azure/private-link/private-endpoint-dns). Other differences in Azure IL regions are as follow:

* DDoS Protection feature is not available. parDdosEnabled parameter is set as false.

* The SKUs available for an ExpressRoute virtual network gateway are Standard, HighPerformance and UltraPerformance. Sku is set as "Standard" in the example parameters file.

 | Azure Cloud    | Bicep template      | Input parameters file                    |
 | -------------- | ------------------- | ---------------------------------------- |
 | Global regions | anoa.lz.hub.network.bicep | anoa.lz.hub.network.parameters.json    |
 | IL regions  | anoa.lz.hub.network.bicep | anoa.lz.hub.network.parameters.json |

> For the examples below we assume you have downloaded or cloned the Git repo as-is and are in the root of the repository as your selected directory in your terminal of choice.

### Azure CLI

```bash
# For Azure Commerical regions

# Set Platform connectivity subscription ID as the the current subscription 

ConnectivitySubscriptionId="[your platform connectivity subscription ID]"
az account set --subscription $ConnectivitySubscriptionId

az deployment sub create \
   --location eastus  \
   --template-file src/bicep/common/landingzone/core/vdss/hub/anoa.lz.hub.network.bicep \
   --parameters @src/bicep/common/landingzone/core/vdss/hub/anoa.lz.hub.network.parameters.json
```

OR

```bash

# For Azure Government regions

# Set Platform connectivity subscription ID as the the current subscription 

ConnectivitySubscriptionId="[your platform connectivity subscription ID]"
az account set --subscription $ConnectivitySubscriptionId

az deployment sub create \
   --location virginaus  \
   --template-file src/bicep/common/landingzone/core/vdss/hub/anoa.lz.hub.network.bicep \
   --parameters @src/bicep/common/landingzone/core/vdss/hub/anoa.lz.hub.network.parameters.json
```

### PowerShell

```powershell
# For Azure Commerical regions
# Set Platform connectivity subscription ID as the the current subscription 
$ConnectivitySubscriptionId = "[your platform connectivity subscription ID]"

Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId
  
New-AzDeployment `
  -TemplateFile src/bicep/common/landingzone/core/vdss/hub/anoa.lz.hub.network.bicep `
  -TemplateParameterFile src/bicep/common/landingzone/core/vdss/hub/anoa.lz.hub.network.parameters.json `
  -location 'eastus'
```

OR

```powershell

# For Azure Government regions
# Set Platform connectivity subscription ID as the the current subscription 
$ConnectivitySubscriptionId = "[your platform connectivity subscription ID]"

Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId

New-AzDeployment `
  -TemplateFile src/bicep/common/landingzone/core/vdss/hub/anoa.lz.hub.network.bicep `
  -TemplateParameterFile src/bicep/common/landingzone/core/vdss/hub/anoa.lz.hub.network.parameters.json `
  -location 'virginiatus'
```

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator can be deleted with these steps:

## Example Output in Azure

![Example Deployment Output](images/hubNetworkExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")
