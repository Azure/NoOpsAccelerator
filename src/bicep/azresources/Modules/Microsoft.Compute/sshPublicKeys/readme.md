# Images `[Microsoft.Compute/sshPublicKeys]`

This module deploys a ssh PublicKeys.

## Navigation

- [Images `[Microsoft.Compute/images]`](#images-microsoftcomputeimages)
  - [Navigation](#navigation)
  - [Resource types](#resource-types)
  - [Parameters](#parameters)
    - [Parameter Usage: `roleAssignments`](#parameter-usage-roleassignments)
    - [Parameter Usage: `tags`](#parameter-usage-tags)
  - [Outputs](#outputs)
  - [Cross-referenced modules](#cross-referenced-modules)
  - [Deployment examples](#deployment-examples)

## Resource types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Authorization/roleAssignments` | [2022-04-01](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2022-04-01/roleAssignments) |
| `Microsoft.Compute/sshPublicKeys` | [2021-04-01](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Compute/2022-08-01/sshpublickeys) |

## Parameters

**Required parameters**
| Parameter Name | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the image. |
| `location` | string | `[resourceGroup().location]` |  | Resource location. |
| `tags` | object | `{object}` | Tags of the resource. |

**Optional parameters**
| Parameter Name | Type | Default Value | Description |
| :-- | :-- | :-- | :-- |
| `publicKey` | string | `` | SSH public key used to authenticate to a virtual machine through ssh. If this property is not initially provided when the resource is created, the publicKey property will be populated when generateKeyPair is called. If the public key is provided upon resource creation, the provided public key needs to be at least 2048-bit and in ssh-rsa format. |

### Parameter Usage: `tags`

Tag names and tag values can be provided as needed. A tag can be left without a value.

<details>

<summary>Parameter JSON format</summary>

```json
"tags": {
    "value": {
        "Environment": "Non-Prod",
        "Contact": "test.user@testcompany.com",
        "PurchaseOrder": "1234",
        "CostCenter": "7890",
        "ServiceName": "DeploymentValidation",
        "Role": "DeploymentValidation"
    }
}
```

</details>

<details>

<summary>Bicep format</summary>

```bicep
tags: {
    Environment: 'Non-Prod'
    Contact: 'test.user@testcompany.com'
    PurchaseOrder: '1234'
    CostCenter: '7890'
    ServiceName: 'DeploymentValidation'
    Role: 'DeploymentValidation'
}
```

</details>
<p>

## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `location` | string | The location the resource was deployed into. |
| `name` | string | The name of the sshPublicKeys. |
| `tags` | string | The resource group the sshPublicKeys was deployed into. |
| `Id` | string | The resource ID of the sshPublicKeys. |

## Cross-referenced modules

_None_

## Deployment examples

The following module usage examples are retrieved from the content of the files hosted in the module's `.test` folder.
   >**Note**: The name of each example is based on the name of the file from which it is taken.

   >**Note**: Each example lists all the required parameters first, followed by the rest - each in alphabetical order.

<h3>Example 1: Parameters</h3>

<details>

<summary>via Bicep module</summary>

```bicep
module key './Microsoft.Compute/sshPublicKeys/az.com.ssh.keys.bicep' = {
  name: '${uniqueString(deployment().name)}-sshKey'
  params: {
    // Required parameters
    name: '<<namePrefix>>-az-key-x-001'
    // Non-required parameters
    publicKey: '<<name>>'    
  }
}
```

</details>
<p>

<details>

<summary>via JSON Parameter file</summary>

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    // Required parameters
    "name": {
      "value": "<<namePrefix>>-az-img-x-001"
    },
    "location": {
      "value": "Premium_LRS"
    },    
    // Non-required parameters
    "publicKey": {
      "value": "<<name>>"
    }
  }
}
```

</details>
<p>