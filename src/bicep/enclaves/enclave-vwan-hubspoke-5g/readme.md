# NoOps Accelerator - Enclave - SCCA Compliant Hub - 1 Spoke landing zone with a Azure Kubernetes Service

## Navigation

- [NoOps Accelerator - Enclave - SCCA Compliant Hub - 1 Spoke landing zone with a Azure Kubernetes Service](#noops-accelerator---enclave---scca-compliant-hub---1-spoke-landing-zone-with-a-azure-kubernetes-service)
  - [Navigation](#navigation)
  - [Overview](#overview)
  - [Architecture](#architecture)
  - [Pre-requisites](#pre-requisites)
  - [Deployment examples](#deployment-examples)
  - [Parameters](#parameters)
    - [Parameter Usage: `appSettingsKeyValuePairs`](#parameter-usage-appsettingskeyvaluepairs)
  - [Outputs](#outputs)
  - [Resource Types](#resource-types)
  - [Air-Gapped Clouds](#air-gapped-clouds)
  - [Cleanup](#cleanup)
  - [Example Output in Azure](#example-output-in-azure)

## Overview

This platform module deploys Enclave Hub/Spoke landing zone with a Azure Kubernetes Service.

Read on to understand what this enclave does, and when you're ready, collect all of the pre-requisites, then deploy the enclave.

## Architecture

 ![Enclave Hub/Spoke landing zone with a Azure Kubernetes Service Architecture](../../../bicep/)

## Pre-requisites

* One or more Azure subscriptions where you or an identity you manage has Owner RBAC permissions
* For deployments in the Azure Portal you need access to the portal in the cloud you want to deploy to, such as <https://portal.azure.com> or <https://portal.azure.us>.
* For deployments in BASH or a Windows shell, then a terminal instance with the AZ CLI installed is required. For example, Azure Cloud Shell, or a command shell on your local machine with the AZ CLI installed.
* For PowerShell deployments you need a PowerShell terminal with the Azure Az PowerShell module installed.

>NOTE: The AZ CLI will automatically install the Bicep tools when a command is run that needs them, or you can manually install them following the instructions here.

## Deployment examples

The following module usage examples are retrieved from the content of the files hosted in the module's `enclave-scca-hubspoke-aks` folder.

   >**Note**: The name of each example is based on the name of the file from which it is taken.
   >**Note**: Each example lists all the required parameters first, followed by the rest - each in alphabetical order.

<h3>Example 1: Enclave Deploy</h3>

<details>

<summary>via Bicep module</summary>

```bicep

```

</details>

<h3>Example 2: Artifacts</h3>

<details>

<summary>via Bicep module</summary>

```bicep

```

</details>

## Parameters

**Required parameters**
| Parameter Name | Type | Allowed Values | Description |
| :-- | :-- | :-- | :-- |
| `name` | string |  | Name of the site. |
| `location` | string | `[resourceGroup().location]` |  | Location for all Resources. |

**Optional parameters**
| Parameter Name | Type | Default Value | Allowed Values | Description |
| :-- | :-- | :-- | :-- | :-- |
| `appInsightId` | string | `''` |  | Resource ID of the app insight to leverage for this resource. |
| `appServiceEnvironmentId` | string | `''` |  | The resource ID of the app service environment to use for this resource. |
| `appSettingsKeyValuePairs` | object | `{object}` |  | The app settings-value pairs except for AzureWebJobsStorage, AzureWebJobsDashboard, APPINSIGHTS_INSTRUMENTATIONKEY and APPLICATIONINSIGHTS_CONNECTION_STRING. |
| `authSettingV2Configuration` | object | `{object}` |  | The auth settings V2 configuration. |
| `clientAffinityEnabled` | bool | `True` |  | If client affinity is enabled. |
| `diagnosticEventHubAuthorizationRuleId` | string | `''` |  | Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to. |
| `diagnosticEventHubName` | string | `''` |  | Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category. |
| `diagnosticLogCategoriesToEnable` | array | `[if(equals(parameters('kind'), 'functionapp'), createArray('FunctionAppLogs'), createArray('AppServiceHTTPLogs', 'AppServiceConsoleLogs', 'AppServiceAppLogs', 'AppServiceAuditLogs', 'AppServiceIPSecAuditLogs', 'AppServicePlatformLogs'))]` | `[AppServiceAppLogs, AppServiceAuditLogs, AppServiceConsoleLogs, AppServiceHTTPLogs, AppServiceIPSecAuditLogs, AppServicePlatformLogs, FunctionAppLogs]` | The name of logs that will be streamed. |
| `diagnosticLogsRetentionInDays` | int | `365` |  | Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely. |
| `diagnosticMetricsToEnable` | array | `[AllMetrics]` | `[AllMetrics]` | The name of metrics that will be streamed. |
| `diagnosticSettingsName` | string | `[format('{0}-diagnosticSettings', parameters('name'))]` |  | The name of the diagnostic setting, if deployed. |
| `diagnosticStorageAccountId` | string | `''` |  | Resource ID of the diagnostic storage account. |
| `diagnosticWorkspaceId` | string | `''` |  | Resource ID of log analytics workspace. |
| `httpsOnly` | bool | `True` |  | Configures a site to accept only HTTPS requests. Issues redirect for HTTP requests. |
| `lock` | string | `''` | `['', CanNotDelete, ReadOnly]` | Specify the type of lock. |
| `privateEndpoints` | array | `[]` |  | Configuration details for private endpoints. For security reasons, it is recommended to use private endpoints whenever possible. |
| `roleAssignments` | array | `[]` |  | Array of role assignment objects that contain the 'roleDefinitionIdOrName' and 'principalId' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: '/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11'. |
| `setAzureWebJobsDashboard` | bool | `[if(contains(parameters('kind'), 'functionapp'), true(), false())]` |  | For function apps. If true the app settings "AzureWebJobsDashboard" will be set. If false not. In case you use Application Insights it can make sense to not set it for performance reasons. |
| `siteConfig` | object | `{object}` |  | The site config object. |
| `storageAccountId` | string | `''` |  | Required if app of kind functionapp. Resource ID of the storage account to manage triggers and logging function executions. |
| `storageAccountRequired` | bool | `False` |  | Checks if Customer provided storage account is required. |
| `systemAssignedIdentity` | bool | `False` |  | Enables system assigned managed identity on the resource. |
| `tags` | object | `{object}` |  | Tags of the resource. |
| `userAssignedIdentities` | object | `{object}` |  | The ID(s) to assign to the resource. |
| `virtualNetworkSubnetId` | string | `''` |  | Azure Resource Manager ID of the Virtual network and subnet to be joined by Regional VNET Integration. This must be of the form /subscriptions/{subscriptionName}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}. |


### Parameter Usage: `appSettingsKeyValuePairs`

AzureWebJobsStorage, AzureWebJobsDashboard, APPINSIGHTS_INSTRUMENTATIONKEY and APPLICATIONINSIGHTS_CONNECTION_STRING are set separately (check parameters storageAccountId, setAzureWebJobsDashboard, appInsightId).
For all other app settings key-value pairs use this object.

<details>

<summary>via Bicep module</summary>

```json

```

</details>

## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `location` | string | The location the resource was deployed into. |
| `name` | string | The name of the site. |
| `resourceGroupName` | string | The resource group the site was deployed into. |
| `resourceId` | string | The resource ID of the site. |
| `systemAssignedPrincipalId` | string | The principal ID of the system assigned identity. |

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Authorization/locks` | [2017-04-01](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2017-04-01/locks) |
| `Microsoft.Authorization/roleAssignments` | [2020-10-01-preview](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2020-10-01-preview/roleAssignments) |
| `Microsoft.Insights/diagnosticSettings` | [2021-05-01-preview](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Insights/2021-05-01-preview/diagnosticSettings) |
| `Microsoft.Network/privateEndpoints` | [2021-08-01](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Network/2021-08-01/privateEndpoints) |
| `Microsoft.Network/privateEndpoints/privateDnsZoneGroups` | [2021-08-01](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Network/2021-08-01/privateEndpoints/privateDnsZoneGroups) |
| `Microsoft.App/containerApps` | [2021-03-01](https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/containerapps) |
| `Microsoft.App/managedEnvironments` | [2021-03-01](https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/managedenvironments) |

## Air-Gapped Clouds

For air-gapped clouds it may be convenient to transfer and deploy the compiled ARM template instead of the Bicep template if the Bicep CLI tools are not available or if it is desirable to transfer only one file into the air gap.

## Cleanup

The Bicep/ARM deployment of NoOps Accelerator Logging deployment can be deleted with these steps:

## Example Output in Azure

![Example Deployment Output](images/operationsNetworkExampleDeploymentOutput.png "Example Deployment Output in Azure global regions")

