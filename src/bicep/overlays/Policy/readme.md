# Overlays: NoOps Accelerator - Azure Policy for Guardrails

> **IMPORTANT: This is currenly work in progress.**

## Table of Contents

  - [Overview](#overview)
  - [Built-In Policy Sets Assignments](#built-in-policy-sets-assignments)
  - [Custom Policies and Policy Sets](#custom-policies-and-policy-sets)
    - [Custom Policy Definitions](#custom-policy-definitions)
    - [Custom Policy Set Definitions](#custom-policy-set-definitions)
    - [Custom Policy Set Assignments](#custom-policy-set-assignments)
  - [Templated Parameters](#templated-parameters)
  - [Authoring Guide](#authoring-guide)

## Overview

Azure's [Azure Policy](https://docs.microsoft.com/azure/governance/policy/overview) is used to deploy guardrails. Azure Policy supports organizational standards enforcement and at-scale compliance evaluation. With the ability to drill down to the per-resource and per-policy granularity, it offers an aggregated view to assess the overall condition of the environment through its compliance dashboard. Bulk remediation for existing resources and automated remediation for new resources both assist in bringing your resources into compliance.

Implementing governance for resource consistency, legal compliance, security, cost, and management are common use cases for Azure Policy. To assist you in getting started, your Azure environment already has built-in policy definitions for these typical use cases.

![Azure Policy Compliance](../../../../docs/wiki/media/architecture/policy-compliance.jpg)

A set of Custom & Built-in Azure Policy Sets based on Regulatory Compliance are setup with NoOps Accelerator. To boost compliance for compute, data, IAM, storage, logging, networking, and tagging requirements, custom policy sets have been developed. Through automation, these can be further expanded or eliminated as needed by use case.

---

## Built-In Policy Sets Assignments

> **Note**: To ensure that any future advancements made by the Azure Engineering teams are automatically incorporated into the Azure environment, the built-in policy settings are used as-is.

All built-in policy set assignments are located in [policy/builtin/assignments](../../policy/builtin/assignments) folder.

* For the purpose of remediating policies, deployment templates can be adjusted with new policy elements and role assignments.
* When assigning a policy set, runtime parameters are defined in configuration files.

All policy set assignments are at the `root` top level management group.  This top level management group is retrieved from configuration parameter `parRootMg`.  See the [GitHub Actions](../onboarding/policy-as-code/github-actions.md) onboarding guide for instructions to setting up policy pipeline.

| Policy Set | Description | Deployment Template | Configuration |
| --- | --- | --- | --- |
| [NIST SP 800-53 Revision 4][nist80053R4policySet] | This initiative includes policies that address a subset of NIST SP 800-53 Rev. 4 controls. | [nist80053r4.bicep](../../policy/builtin/assignments/nist80053r4.bicep) | [nist80053r4.parameters.json](../../policy/builtin/assignments/nist80053r4.parameters.json) |
| [NIST SP 800-53 Revision 5][nist80053R5policySet] | This initiative includes policies that address a subset of NIST SP 800-53 Rev. 5 controls. | [nist80053r5.bicep](../../policy/builtin/assignments/nist80053r5.bicep) | [nist80053r5.parameters.json](../../policy/builtin/assignments/nist80053r5.parameters.json) |
| [Azure Security Benchmark][asbPolicySet] | The Azure Security Benchmark initiative represents the policies and controls implementing security recommendations defined in Azure Security Benchmark, see https://aka.ms/azsecbm. This also serves as the Microsoft Defender for Cloud default policy initiative. | [asb.bicep](../../policy/builtin/assignments/asb.bicep) | [asb.parameters.json](../../policy/builtin/assignments/asb.parameters.json) |
|  [FedRAMP Moderate][fedrampmPolicySet] | This initiative includes policies that address a subset of FedRAMP Moderate controls. | [fedramp-moderate.bicep](../../policy/builtin/assignments/fedramp-moderate.bicep) | [fedramp-moderate.parameters.json](../../policy/builtin/assignments/fedramp-moderate.parameters.json) |
| Location | Restrict deployments to certain regions. | [location.bicep](../../policy/builtin/assignments/location.bicep) | [location.parameters.json](../../policy/builtin/assignments/location.parameters.json) |

## Custom Policies and Policy Sets

> **Note**: When a built-in alternative is unavailable, custom policies and policy sets are applied. As new options become available, automation is continually updated to utilize built-in policies and policy sets.

All policies and policy set definitions & assignments are at the `root` top level management group.  This top level management group is retrieved from configuration parameter `parRootMg`.  See the [GitHub Actions Pipelines](../onboarding/policy-as-code/github-actions.md) onboarding guide for instructions to setting up policy pipeline.

### Custom Policy Definitions

All custom policy definitions are located in [policy/custom/definitions/policy](../../policy/custom/definitions/policy) folder.

Each policy is organized into it's own folder.  The folder name must not have any spaces nor special characters.  Each folder contains 3 files:

1. azurepolicy.config.json - metadata used by GitHub Actions to configure the policy.
2. azurepolicy.parameters.json - contains parameters used in the policy.
3. azurepolicy.rules.json - the policy rule definition.

See [step-by-step instructions on Azure Policy Authoring Guide](authoring-guide.md) for more information.

GitHub Actions ([.github/workflows/policy.yml](../../.github/workflows/policy.yml)) is used for policy definition automation.  The automation enumerates the policy definition directory (`policy/custom/definitions/policy`) and creates/updates policies that it identifies.

### Custom Policy Set Definitions

All custom policy set definitions are located in [policy/custom/definitions/policyset](../../policy/custom/definitions/policyset) folder.  Custom policy sets contain built-in and custom policies.

GitHub Actions ([.github/workflows/policy.yml](../../.github/workflows/policy.yml)) is used for policy set definition automation.  Defined policy sets can be customized through pipeline configuration.

| Policy Set | Description | Deployment Template | Configuration |
| --- | --- | --- | --- |
| Compute Governance | Azure Policy Add-on to Compute Governance. | [Compute.bicep](../../policy/custom/definitions/policyset/compute.bicep) | [Compute.parameters.json](../../policy/custom/definitions/policyset/compute.parameters.json)
| Data Protection Governance | Configures Microsoft Defender for Cloud, including Azure Defender for subscription and resources. | [DataProtection.bicep](../../policy/custom/definitions/policyset/DataProtection.bicep) | [DataProtection.parameters.json](../../policy/custom/definitions/policyset/DataProtection.parameters.json)
| Identity & Access Governance (IAM) | Configures Microsoft Defender for Cloud, including Azure Defender for subscription and resources. | [Identity.bicep](../../policy/custom/definitions/policyset/Identity.bicep) | [Identity.parameters.json](../../policy/custom/definitions/policyset/Identity.parameters.json)
| Key Vault Governance | Configures Microsoft Defender for Cloud, including Azure Defender for subscription and resources. | [KeyVault.bicep](../../policy/custom/definitions/policyset/KeyVault.bicep) | [KeyVault.parameters.json](../../policy/custom/definitions/policyset/KeyVault.parameters.json)
| Private DNS Zones for Private Endpoints | Policies to configure DNS zone records for private endpoints.  Policy set is assigned through deployment pipeline when private endpoint DNS zones are managed in the Hub Network. | [DNSPrivateEndpoints.bicep](../../policy/custom/definitions/policyset/DNSPrivateEndpoints.bicep) | [DNSPrivateEndpoints.parameters.json](../../policy/custom/definitions/policyset/DNSPrivateEndpoints.parameters.json)
| Logging | Configures monitoring agents for IaaS and diagnostic settings for PaaS to send logs to a central Log Analytics Workspace. | [Logging.bicep](../../policy/custom/definitions/policyset/Logging.bicep) | [Logging.parameters.json](../../policy/custom/definitions/policyset/Logging.parameters.json)
| Networking | Configures policies for network resources. | [Network.bicep](../../policy/custom/definitions/policyset/Network.bicep) | [Network.parameters.json](../../policy/custom/definitions/policyset/Network.parameters.json)
| Tag Governance | Configures required tags and tag propagation from resource groups to resources. | [Tags.bicep](../../policy/custom/definitions/policyset/Tags.bicep) | [Tags.parameters.json](../../policy/custom/definitions/policyset/Tags.parameters.json)

### Custom Policy Set Assignments

All custom policy set assignments are located in [policy/custom/assignments](../../policy/custom/assignments) folder.

* Deployment templates can be customized for additional policy parameters & role assignments for policy remediation.
* Configuration files are used to define runtime parameters during policy set assignment.  

GitHub Actions ([.github/workflows/policy.yml](../../.github/workflows/policy.yml)) is used for policy set assignment automation.  Assigned policy sets can be customized through pipeline configuration.

**Action Step**
```yml
    - template: actions/steps/assign-policy.yml
      parameters:
        description: 'Assign Policy Set'
        deployTemplates: [AKS, DefenderForCloud, LogAnalytics, Network, Tags]
        deployOperation: ${{ variables['deployOperation'] }}
        policyAssignmentManagementGroupScope: $(var-topLevelManagementGroupName)
        workingDir: $(System.DefaultWorkingDirectory)/policy/custom/assignments
```

| Policy Set | Description | Deployment Template | Configuration |
| --- | --- | --- | --- |

---

## Templated Parameters

Parameters can be templated using the syntax `{{PARAMETER_NAME}}`.  Following parameters are supported:

| Templated Parameter | Source Value | Example |
| --- | --- | --- |
| {{var-topLevelManagementGroupName}} | Environment configuration file such as [config/variables/MLZ-main.yml](../../config/variables/MLZ-main.yml)  | `pubsec`
| {{var-logging-logAnalyticsWorkspaceResourceId}} | Resource ID is inferred using Log Analytics settings in environment configuration file such as [config/variables/MLZ-main.yml](../../config/variables/MLZ-main.yml)  | `/subscriptions/bc0a4f9f-07fa-4284-b1bd-fbad38578d3a/resourcegroups/pubsec-central-logging/providers/microsoft.operationalinsights/workspaces/log-analytics-workspace`
| {{var-logging-logAnalyticsWorkspaceId}} |  Workspace ID is inferred using Log Analytics settings in environment configuration file such as [config/variables/MLZ-main.yml](../../config/variables/MLZ-main.yml) | `fcce3f30-158a-4561-a714-361623f42168`
| {{var-logging-logAnalyticsResourceGroupName}} | Environment configuration file such as [config/variables/MLZ-main.yml](../../config/variables/MLZ-main.yml)  | `pubsec-central-logging`
| {{var-logging-logAnalyticsRetentionInDays}} | Environment configuration file such as [config/variables/MLZ-main.yml](../../config/variables/MLZ-main.yml) | `730`
| {{var-logging-diagnosticSettingsforNetworkSecurityGroupsStoragePrefix}} | Environment configuration file such as [config/variables/MLZ-main.yml](../../config/variables/MLZ-main.yml)  | `pubsecnsg`
| {{var-policyAssignmentManagementGroupId}} | The management group scope for policy assignment. | `pubsec`

---

## Authoring Guide

See [Azure Policy Authoring Guide](authoring-guide.md) for step-by-step instructions.

[nist80053r4Policyset]: https://docs.microsoft.com/azure/governance/policy/samples/nist-sp-800-53-r4
[nist80053r5Policyset]: https://docs.microsoft.com/azure/governance/policy/samples/nist-sp-800-53-r5
[pbmmPolicyset]: https://docs.microsoft.com/azure/governance/policy/samples/canada-federal-pbmm
[asbPolicySet]: https://docs.microsoft.com/security/benchmark/azure/overview
[cisMicrosoftAzureFoundationPolicySet]: https://docs.microsoft.com/azure/governance/policy/samples/cis-azure-1-3-0
[fedrampmPolicySet]: https://docs.microsoft.com/azure/governance/policy/samples/fedramp-moderate
[hipaaHitrustPolicySet]: https://docs.microsoft.com/azure/governance/policy/samples/hipaa-hitrust-9-2