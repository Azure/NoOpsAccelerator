# Network Private Link Private DNS Zone Group `[Microsoft.Network/privateEndpoints/privateLink]`

This module deploys a private endpoint private DNS zone group

## Navigation

- [Resource Types](#Resource-Types)
- [Parameters](#Parameters)
- [Outputs](#Outputs)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Network/privateEndpoints/privateLink` | [2021-08-01](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Network/2021-08-01/privateEndpoints/privateLink) |

## Parameters

**Required parameters**
| Parameter Name | Type | Description |
| :-- | :-- | :-- |
| `privateDNSResourceIds` | array | Array of private DNS zone resource IDs. A DNS zone group can support up to 5 DNS zones. |

**Conditional parameters**
| Parameter Name | Type | Description |
| :-- | :-- | :-- |
| `privateEndpointName` | string | The name of the parent private endpoint. Required if the template is used in a standalone deployment. |

**Optional parameters**
| Parameter Name | Type | Default Value | Description |
| :-- | :-- | :-- | :-- |
| `name` | string | `'default'` | The name of the private DNS zone group. |


## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the private endpoint DNS zone group. |
| `resourceGroupName` | string | The resource group the private endpoint DNS zone group was deployed into. |
| `resourceId` | string | The resource ID of the private endpoint DNS zone group. |