# Module: NoOps Accelerator - Landing Zone Core (Hub/Spoke)

## Overview

NoOps Accelerator Landing Zone Core (Hub/Spoke) is based on the recommendations from the [Azure Mission Landing Zone Conceptual Architecture](https://github.com/Azure/missionlz).

> All spokes name can be changed.

These modules deploy the following resources:

* Hub Virtual Network (VNet)  
* Spoke
  * Identity (Tier 0)
  * Operations (Tier 1)
  * Shared Services (Tier 2)
* Logging
  * Azure Log Analytics
* Operations Artifacts (Optional)
* Azure Firewall
* Network peerings
* Private DNS Zones - Details of all the Azure Private DNS zones can be found here --> [https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration)

## What is a Landing Zone?

A **landing zone** is networking infrastructure configured to provide a secure environment for hosting workloads.

[![Landing Zones Azure Academy Video](https://img.youtube.com/vi/9BKgz9Rl1eo/0.jpg)](https://youtu.be/9BKgz9Rl1eo "Don't let this happen to you 😮 Build A Landing Zone 👍 - Click to Watch!")

## Understanding the NoOps Accelerator Landing Zone Core

NoOps Accelerator Landing Zone Core has the following scope:

* Hub and spoke networking intended to comply with SCCA controls
* Predefined spokes for identity, operations, shared services, and workloads
* Compatibility with SCCA compliance (and other compliance frameworks)
* Security using standard Azure tools with sensible defaults

<!-- markdownlint-disable MD033 -->
<!-- allow html for images so that they can be sized -->
<img src="docs/images/scope-v2.png" alt="A table of the components Mission LZ provisions in Azure beneath a rectangle labeled DISA Secure Cloud Computing Architecture Controls" width="600" />
<!-- markdownlint-enable MD033 -->

## NoOps Accelerator Landing Zone Core - Module Deployment Sequence

There are 2 deployment options available to deploy the NoOps Accelerator Landing Zone networking topology. One that uses an orchestration module for the spoke networking and one that does not.

> NOTE: We recommend using deployment option 1 were possible as the orchestration module has some added benefits, like remote access, microsoft defender as well as the spoke networking.

### Deployment Option 1 - Using Orchestration Module - lz-platform-scca-hub-3spoke

This deployment option does utilize the orchestration module (a module that wrap/call other core modules).

| Deployment Order | Module | Description | Prerequisites | Module Documentation |
 | --------------------------------- | ------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
 | 1 | NoOps Accelerator SCCA Compliant Hub - 3 Spoke Landing Zone | Creates NoOps Accelerator SCCA Compliant Hub - 3 Spoke Landing Zone with Azure Firewall to support Hub & Spoke network topology in the Transport subscription. | Management Groups, Policy, Subscription for NoOps Accelerator Landing Zone Networking. | [src\bicep\plarforms\lz-platform-scca-hub-3spoke\](../../../bicep/platforms/lz-platform-scca-hub-3spoke)|

### Deploy Option 1 using the Azure CLI
<!-- markdownlint-disable MD013 -->
1. Clone the repository and change directory to the root of the repository:

```bash
    git clone https://github.com/Azure/NoOpsAccelerator.git
    cd noopsaccelerator
```

2. Deploy NoOps Accelerator SCCA Compliant Hub - 3 Spoke Landing Zone with the az deployment sub create command. For a quickstart, we suggest a test deployment into the current AZ CLI subscription setting these parameters:

    * `--name`: (optional) The deployment name, which is visible in the Azure Portal under Subscription/Deployments.
    * `--location`: (required) The Azure region to store the deployment metadata.
    * `--subscription`: (required) The Azure subscription Id.
    * `--template-file`: (required) The file path to the `deploy.bicep` template.
    * `--parameters`: (required) (required) The file path to the `deployments\MLZ\deploy.parameters.json` template that is used to generate values for your resources.

Here's an example:

```bash
    az deployment sub create \
    --name deploy-lz-network \
    --location eastus \
    --template-file ./src/bicep/platforms/lz-platform-scca-hub-3spoke/deploy.bicep \
    --parameters @./src/bicep/platforms/lz-platform-scca-hub-3spoke/deploy.parameters.json \
    --subscription xxxxxxx-xxxx-xxxxxxx-xxxxx-xxxx
```

3. After a successful deployment, see our overlays directory for how to extend the capabilities of NoOps Accelerator Landing Zone.

> Don't have Azure CLI? Here's how to get started with Azure Cloud Shell in your browser: <https://docs.microsoft.com/en-us/azure/cloud-shell/overview>

### Deployment Option 2 - No Orchestration Module

This deployment option doesn't utilize any orchestration modules (modules that wrap/call other modules). You use this deployment option if it is needed to break apart the tiers into different deployment options.

 | Deployment Order | Module | Description | Prerequisites | Module Documentation |
 | --------------------------------- | ------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
 | 1 | Logging | Creates Logging infrastructure to support (Sentinel, Log Analytics, Automation Account (Optional)) in the Connectivity subscription. | Management Groups, Subscription for Hub Networking. | [src\bicep\azresources\hub-spoke-core\vdms\logging\anoa.lz.logging.bicep](../azresources/hub-spoke-core/vdms/logging/README.md) |
  | 2 | Hub Networking | Creates Hub networking infrastructure with Azure Firewall to support Mission Landing Zone network topology in the Connectivity subscription. | Management Groups, Subscription for Hub Networking. | [src\bicep\azresources\hub-spoke-core\vdss\hub\anoa.lz.hub.network.bicep](../azresources/hub-spoke-core/vdss/hub/readme.md) |
   | 3 | Operations Spoke Network | Creates Operations Spoke networking infrastructure for workloads to support Mission Landing Zone network topology. Spoke subscriptions are used for deploying construction sets and workloads. | Management Groups, Logging, Hub Networking & Subscription for spoke networking. | [src\bicep\azresources\hub-spoke-core\vdms\operations\anoa.lz.ops.network.bicep](../azresources/hub-spoke-core/vdms/operations/README.md) |
   | 3 | Identity Spoke Network | Creates Identiyy Spoke networking infrastructure for workloads to support Mission Landing Zone network topology. Spoke subscriptions are used for deploying construction sets and workloads. | Management Groups, Logging, Hub Networking & Subscription for spoke networking. | [src\bicep\azresources\hub-spoke-core\vdss\identity\anoa.lz.id.network.bicep](../azresources/hub-spoke-core/vdss/identity/README.md) |
   | 3 | Shared Services Spoke Network | Creates Shared Services Spoke networking infrastructure for workloads to support Mission Landing Zone network topology. Spoke subscriptions are used for deploying construction sets and workloads. | Management Groups, Logging, Hub Networking & Subscription for spoke networking. | [src\bicep\azresources\hub-spoke-core\vdms\sharedservices\anoa.lz.svcs.network.bicep](../azresources/hub-spoke-core/vdms/sharedServices/README.md) |
   | 4 | Hub VNet Peering | Creates VNet peering between 2 VNets (e.g. Hub & Spoke) in the Mission Landing Zone topology. Make sure to run this module twice, once in each direction. e.g. Hub to Spoke and then Spoke to Hub | Management Groups, Logging, Hub Networking & Subscription for spoke networking. | [src\bicep\azresources\hub-spoke-core\peering\hub\anoa.lz.hub.network.peerings.bicep](../azresources/hub-spoke-core/peering/hub/readme.md) |
   | 5 | Spoke VNet Peering | Creates Spoke VNet peering between 2 VNets (e.g. Hub & Spoke) in the Mission Landing Zone topology. Make sure to run this module twice, once in each direction. e.g. Hub to Spoke and then Spoke to Hub | Management Groups, Logging, Hub Networking & Subscription for spoke networking. | [src\bicep\azresources\hub-spoke-core\peering\spoke\anoa.lz.spoke.network.peerings.bicep](../azresources/hub-spoke-core/peering/spoke/readme.md) |

### Deploy Option 2 using the Azure CLI

1. Clone the repository and change directory to the root of the repository:

```bash
    git clone https://github.com/Azure/NoOpsAccelerator.git
    cd noops
```

2. Deploy Mission Landing Zone with the az deployment sub create command in sequence with above table.

## Required Parameters

The module requires the following inputs:

| Parameter                         | Type   | Default                                                                                              | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Required                   | Example                                        |
 | --------------------------------- | ------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- | ---------------------------------------------- |
| parOrgPrefix                       | string | `aona`                                                                           | Prefix value which will be prepended to all resource names. Default: anoa                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Yes                          | `aona`
| parLocation                       | string | `resourceGroup().location`                                                                           | The Azure Region to deploy the resources into                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Yes                          | `eastus`
| parTemplateVersion                       | string | `1.0`                                                                           | The ANOA template version                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Yes                          | `1.o`
| parDeployEnvironment                       | string | None                                                                           | A suffix, 3 to 15 characters in length, to append to resource names (e.g. "dev", "test", "prod", "platforms"). It defaults to "platforms".'                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Yes                          | `platforms`
| parResourcePrefix                       | string | None                       | A prefix, 3-15 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Yes                          | None

## Hub Network Parameters

The module requires the following inputs for Hub Network:

| Parameter                                | Type   | Default                    | Description                                                                                                                                                                                                                          | Required | Example                    |
|------------------------------------------|--------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|----------------------------|
| parHubSubscriptionId                     | string | `guid`                     | The subscription ID for the Hub Network and resources. It defaults to the deployment subscription                                                                                                                                    | No       | `xxxx-xxxx-xxxx-xxxx-xxxx` |
| parDeployArtifacts                       | bool   | true                       | When set to "true", enables Artifacts Resource Group with KV and Storage account for the subscriptions used in the deployment. It defaults to "false".                                                                               | None     | false                      |
| parKeyVaultPolicies                      | array  |                            |                                                                                                                                                                                                                                      |          |                            ||
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

## Operations Network Parameters

The module requires the following inputs for Operations Network:

| Parameter                                | Type   | Default                    | Description                                                                                                                                                                                                                          | Required | Example                    |
|------------------------------------------|--------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|----------------------------|
| parOperationsSubscriptionId                     | string | `guid`                     | The subscription ID for the Operations Network and resources. It defaults to the deployment subscription                                                                                                                                    | No       | `xxxx-xxxx-xxxx-xxxx-xxxx` | Yes| None |
parOperationsVirtualNetworkAddressPrefix | string | No       | The CIDR Virtual Network Address Prefix for the Operations Virtual Network. | Yes| None |
parOperationsSubnetAddressPrefix | string | No       | The CIDR Subnet Address Prefix for the default Operations subnet. It must be in the Operations Virtual Network space.| Yes| None |
parSourceAddressPrefixes | string | No       | The CIDR Virtual Network Address Prefix for the Identity/SharedServices Virtual Network. Leave blank if no spokes are needed. | Yes| None |
parLogStorageSkuName | string | No       | The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See <https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types> for valid settings.. | Yes| None |
parOperationsVirtualNetworkDiagnosticsLogs | array | No       | An array of Network Diagnostic Logs to enable for the Operations Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs> for valid settings. | Yes| None |
parOperationsVirtualNetworkDiagnosticsMetrics | array | No       | An array of Network Diagnostic Metrics to enable for the Operations Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/> diagnostic-settings?tabs=CMD#metrics for valid settings. | Yes| None |
parOperationsNetworkSecurityGroupRules | array | No       | An array of Network Security Group rules to apply to the Operations Virtual Network. See <https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat> for valid settings. | Yes| None |
parOperationsNetworkSecurityGroupDiagnosticsLogs | array | No       | An array of Network Security Group diagnostic logs to apply to the Operations Virtual Network. See <https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories> for valid settings. | Yes| None |
parOperationsNetworkSecurityGroupDiagnosticsMetrics | array | No       | An array of Network Security Group Diagnostic Metrics to enable for the Operations Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics> for valid settings. | Yes| None |
parOperationsSubnetServiceEndpoints | array | No       | An array of Service Endpoints to enable for the Operations subnet. See <https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview> for valid settings. | Yes| None |
parLogAnalyticsWorkspaceResourceId | string | No       | . | Yes| None |
parLogAnalyticsWorkspace | string | No       | . | Yes| None |
parFirewallPrivateIPAddress | string | No       | . | Yes| None |
parStorageAccountAccessObjectId | string | No       | . | Yes| None |
parStorageAccountAccessType | string | No       | . | Yes| None |
parAddRoleAssignmentForStorageAccount | bool | No       | . | Yes| None |

## Shared Services Network Parameters

The module requires the following inputs for Shared Services Network:

| Parameter                                | Type   | Default                    | Description                                                                                                                                                                                                                          | Required | Example                    |
|------------------------------------------|--------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|----------------------------|
| parSharedServicesSubscriptionId                     | string | `guid`                     | The subscription ID for the SharedServices Network and resources. It defaults to the deployment subscription                                                                                                                                    | No       | `xxxx-xxxx-xxxx-xxxx-xxxx` | Yes| None |
parSharedServicesVirtualNetworkAddressPrefix | string | No       | The CIDR Virtual Network Address Prefix for the SharedServices Virtual Network. | Yes| None |
parSharedServicesSubnetAddressPrefix | string | No       | The CIDR Subnet Address Prefix for the default SharedServices subnet. It must be in the SharedServices Virtual Network space.| Yes| None |
parSourceAddressPrefixes | string | No       | The CIDR Virtual Network Address Prefix for the Identity/SharedServices Virtual Network. Leave blank if no spokes are needed. | Yes| None |
parLogStorageSkuName | string | No       | The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See <https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types> for valid settings.. | Yes| None |
parSharedServicesVirtualNetworkDiagnosticsLogs | array | No       | An array of Network Diagnostic Logs to enable for the SharedServices Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs> for valid settings. | Yes| None |
parSharedServicesVirtualNetworkDiagnosticsMetrics | array | No       | An array of Network Diagnostic Metrics to enable for the SharedServices Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/> diagnostic-settings?tabs=CMD#metrics for valid settings. | Yes| None |
parSharedServicesNetworkSecurityGroupRules | array | No       | An array of Network Security Group rules to apply to the SharedServices Virtual Network. See <https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat> for valid settings. | Yes| None |
parSharedServicesNetworkSecurityGroupDiagnosticsLogs | array | No       | An array of Network Security Group diagnostic logs to apply to the SharedServices Virtual Network. See <https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories> for valid settings. | Yes| None |
parSharedServicesNetworkSecurityGroupDiagnosticsMetrics | array | No       | An array of Network Security Group Diagnostic Metrics to enable for the SharedServices Virtual Network. See <https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics> for valid settings. | Yes| None |
parSharedServicesSubnetServiceEndpoints | array | No       | An array of Service Endpoints to enable for the SharedServices subnet. See <https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview> for valid settings. | Yes| None |
parLogAnalyticsWorkspaceResourceId | string | No       | . | Yes| None |
parLogAnalyticsWorkspace | string | No       | . | Yes| None |
parFirewallPrivateIPAddress | string | No       | . | Yes| None |
parStorageAccountAccessObjectId | string | No       | . | Yes| None |
parStorageAccountAccessType | string | No       | . | Yes| None |
parAddRoleAssignmentForStorageAccount | bool | No       | . | Yes| None |

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
parLogAnalyticsWorkspace | string | No       | . | Yes| None |
parFirewallPrivateIPAddress | string | No       | . | Yes| None |
parStorageAccountAccessObjectId | string | No       | . | Yes| None |
parStorageAccountAccessType | string | No       | . | Yes| None |
parAddRoleAssignmentForStorageAccount | bool | No       | . | Yes| None |

## Outputs

The module will generate the following outputs:

table

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator - Mission Landing Zone deployment can be deleted with these steps:

1. Delete all resource groups.
1. Delete the diagnostic settings deployed at the subscription level.
1. If Microsoft Defender for Cloud was deployed (parameter `parDeployDefender=true` was used) then remove subscription-level policy assignments and downgrade the Microsoft Defender for Cloud pricing tiers.

> NOTE: If you deploy and delete Mission Landing Zone in the same subscription multiple times without deleting the subscription-level diagnostic settings, the sixth deployment will fail. Azure has a limit of five diagnostic settings per subscription. The error will be similar to this: `"The limit of 5 diagnostic settings was reached."`

To delete the diagnostic settings from the Azure Portal: choose the subscription blade, then Activity log in the left panel. At the top of the Activity log screen click the Diagnostics settings button. From there you can click the Edit setting link and delete the diagnostic setting.

To delete the diagnotic settings in script, use the AZ CLI or PowerShell. An AZ CLI example is below:

```BASH
# View diagnostic settings in the current subscription
az monitor diagnostic-settings subscription list --query value[] --output table

# Delete a diagnostic setting
az monitor diagnostic-settings subscription delete --name <diagnostic setting name>
```
## References

[Hub and Spoke network topology](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
