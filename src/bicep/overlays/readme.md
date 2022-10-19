# NoOps Accelerator - Bicep Overlays

In this Overlays directory are to show how to add/extend functionality of NoOps Accelerator Enclaves & Platforms (Landing Zones).

You must first deploy [Enclave](../../bicep/enclaves/) or [Platform Landing Zone](../../bicep/platforms/), then you can deploy these overlays.

## Overlays Deployments

### Management Groups

Management groups give you enterprise-grade management at a large scale no matter what type of subscriptions you might have. All subscriptions within a single management group must trust the same Azure Active Directory tenant.

Read about [Management groups](../../bicep/overlays/management-groups/readme.md)

| Example | Description | Modules |
| ------- | ----------- | ----------- |
| Management Groups | The Enclave Management Groups module deploys a management group hierarchy in a tenant under the `Tenant Root Group`.| [deploy.bicep](../overlays/management-groups/deploy.bicep) |

### Management Services

| Overlay | Description | Modules |
| ------- | ----------- | ----------- |
Azure Automation Account | Module to deploy a Azure Automation Accoun to an resource group | [deploy.bicep](../overlays/management-services/automation/deploy.bicep)
Bastion Host | Module to deploy a Bastion Host with Windows/Linux Jump Boxes to the Hub Network | [deploy.bicep](../overlays/management-services/bastion/deploy.bicep)
Microsoft Defender for Cloud | Module to deploy the Microsoft Defender for Cloud to the Hub or Spoke Network | [deploy.bicep](../overlays/management-services/defender/deploy.bicep)
Microsoft Front Door Service (Coming Soon) | Module to deploy the Microsoft Front Door Service to the Hub Network | [deploy.bicep](../overlays/management-services/front-door/deploy.bicep)
Service Health Alerts | Module to deploy the Microsoft Front Door Service to an subscription or resource group | [deploy.bicep](../overlays/management-services/service-health/deploy.bicep)
Subcription Budget | Module to deploy the Microsoft Front Door Service to an subscription | [deploy.bicep](../overlays/management-services/subscription-budget/deploy.bicep)
Azure Container Registry | Module to deploy the Azure Container Registry to the Spoke Network | [deploy.bicep](../overlays/management-services/containerRegistry/deploy.bicep)
Azure Kubernetes Service | Module to deploy the Azure Kubernetes Service to the Spoke Network | [deploy.bicep](../overlays/management-services/kubernetesCluster/deploy.bicep)
Key Vault | Module to deploy the Key Vault to the Spoke Network | [deploy.bicep](../overlays/management-services/keyvault/deploy.bicep)
Storage Account | Module to deploy the Storage Account to the Spoke Network | [deploy.bicep](../overlays/management-services/storageAccount/deploy.bicep)

### Policy

Azure Policy is used to implement guardrails in your environment.

Read about [Policy](../overlays/policy/hub-spoke/readme.md)

| Example | Description | Modules |
| ------- | ----------- | ----------- |
| Policy | The Enclave Management Groups module deploys a management group hierarchy in a tenant under the `Tenant Root Group`.| deploy.bicep |

### RBAC/Roles

The Enclave Roles overlay module deploys a role definitions in a specific `Management Group`.  This is accomplished through a managmenent-group-scoped Azure Resource Manager (ARM) deployment.  The role definitions heirarchy can be modifed by editing `deploy.parameters.json`.

Read about [Roles](../overlays/roles/readme.md)

| Example | Description | Modules |
| ------- | ----------- | ----------- |
| Roles | The Enclave Roles overlay module deploys a role definitions in a specific `Management Group`.Group`.| [deploy.bicep](../overlays/roles/deploy.bicep) |
