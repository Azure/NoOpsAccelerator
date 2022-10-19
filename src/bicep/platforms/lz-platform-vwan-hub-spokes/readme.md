# NoOps Accelerator - Platforms - VWAN Multi-Spoke

Module Tested on:

* Azure Commercial ✔️
* Azure Government ✔️
* Azure Government Secret ❔
* Azure Government Top Secret ❔

> ✔️ = tested,  ❔= currently testing

## Navigation

- [NoOps Accelerator - Platforms - SCCA Compliant Hub - 3 Spoke](#noops-accelerator---platforms---scca-compliant-hub---3-spoke)
  - [Authored & Tested With](#authored--tested-with)
  - [Navigation](#navigation)
  - [Overview](#overview)
  - [Architecture](#architecture)
  - [Pre-requisites](#pre-requisites)
  - [Deployment examples](#deployment-examples)
  - [Parameters](#parameters)
    - [Parameter Usage: `appSettingsKeyValuePairs`](#parameter-usage-appsettingskeyvaluepairs)
  - [Outputs](#outputs)
  - [Resource Types](#resource-types)

## Overview

## Architecture

## Pre-requisites

## Deployment examples

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


### Parameter Usage: `appSettingsKeyValuePairs`

AzureWebJobsStorage, AzureWebJobsDashboard, APPINSIGHTS_INSTRUMENTATIONKEY and APPLICATIONINSIGHTS_CONNECTION_STRING are set separately (check parameters storageAccountId, setAzureWebJobsDashboard, appInsightId).
For all other app settings key-value pairs use this object.

## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `location` | string | The location the resource was deployed into. |
| `name` | string | The name of the site. |

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Authorization/locks` | [2017-04-01](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2017-04-01/locks) |
| `Microsoft.Authorization/roleAssignments` | [2020-10-01-preview](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2020-10-01-preview/roleAssignments) |
