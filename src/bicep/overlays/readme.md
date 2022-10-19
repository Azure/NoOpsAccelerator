# NoOps Accelerator - Bicep Overlays

In this Overlays directory are to show how to add/extend functionality of NoOps Accelerator Platforms (Landing Zones).

You [must first deploy Enclave or Platform Archetype](../mission-landing-zone/README.md#Overview), then you can deploy these overlays.

## Overlays Deployments

### Management Groups

Management groups give you enterprise-grade management at a large scale no matter what type of subscriptions you might have. All subscriptions within a single management group must trust the same Azure Active Directory tenant.

Read about [Management groups](../../../docs/wiki/architecture.md#3-management-groups)

| Example | Description | Modules |
| ------- | ----------- | ----------- |
| Management Groups | The Enclave Management Groups module deploys a management group hierarchy in a tenant under the `Tenant Root Group`.| anoa.enclave.mgmt.groups.bicep |

### Management Services

| Example | Description | Modules |
| ------- | ----------- | ----------- |
Azure Automation Account | test | [anoa.lz.mgmt.svcs.aa.bicep](../overlays/management-services/automation/anoa.lz.mgmt.svcs.aa.bicep)
Bastion Host | Module to deploy a Bastion Host with Windows/Linux Jump Boxes to the Hub Network | [anoa.lz.mgmt.svcs.remote.access.bicep](../overlays/management-services/bastion/anoa.lz.mgmt.svcs.remote.access.bicep)
Microsoft Defender for Cloud | Module to deploy the Microsoft Defender for Cloud to the Hub Network | [anoa.lz.mgmt.svcs.defender.bicep](../overlays/management-services/defender/anoa.lz.mgmt.svcs.defender.bicep)
Microsoft Front Door Service | Module to deploy the Microsoft Front Door Service to the Hub Network | [anoa.lz.mgmt.svcs.frontdoor.bicep](../overlays/management-services/front-door/anoa.lz.mgmt.svcs.frontdoor.bicep)
Network Security Groups | Module to deploy the Microsoft Front Door Service to the Hub Network | [networkSecurityGroups/](../overlays/management-services/networkSecurityGroups/)
Sentinel | Module to deploy the Microsoft Front Door Service to the Hub Network | [networkSecurityGroups/](../overlays/management-services/networkSecurityGroups/)
Service Health Alerts | Module to deploy the Microsoft Front Door Service to the Hub Network | [networkSecurityGroups/](../overlays/management-services/networkSecurityGroups/)
Subcription Budget | Module to deploy the Microsoft Front Door Service to the Hub Network | [networkSecurityGroups/](../overlays/management-services/networkSecurityGroups/)
Subcription Create | Module to deploy the Microsoft Front Door Service to the Hub Network | [networkSecurityGroups/](../overlays/management-services/networkSecurityGroups/)
Virtual Network Gateway | Module to deploy the Microsoft Front Door Service to the Hub Network | [networkSecurityGroups/](../overlays/management-services/networkSecurityGroups/)

### Policy

| Example | Description | Modules |
| ------- | ----------- | ----------- |


### RBAC/Roles

| Example | Description | Modules |
| ------- | ----------- | ----------- |
| Management Groups |  |  |
| Management Services |  |  |
| Policy |  |  |
| RBAC/Roles |  |  |
| Worloads (Tier 3) |  |  |

### Workloads (Tier 3)

| Example | Description | Modules |
| ------- | ----------- | ----------- |
| Management Groups |  |  |
| Management Services |  |  |
| Policy |  |  |
| RBAC/Roles |  |  |
| Worloads (Tier 3) |  |  |