# NoOps Accelerator FAQ

This article answers frequently asked questions relating to NoOps Accelerator.

## How long does NoOps Accelerator reference implementation take to deploy?

Deployment time depends on the options you select during the reference implementation deployment. It varies from around five minutes to 40 minutes, depending on the options selected.

For example:

- Reference implementation without any networking or connectivity options can take around five minutes to deploy.
- Reference implementation with the hub and spoke networking options, including Defender, Sentinel and Bastion, can take around 40 minutes to deploy.

## Why are there custom policy definitions as part of NoOps Accelerator reference implementation?

## Why does the NoOps Accelerator reference implementation require permission at tenant root '/' scope?

Management group creation, subscription creation, and placing subscriptions into management groups are APIs that operate at the tenant root "`/`" scope.

To establish the management group hierarchy and create subscriptions and place them into the defined management groups, the initial deployment must be invoked at the tenant root "`/`" scope. Once you deploy NoOps Accelerator reference implementation architecture, you can remove the owner permission from the tenant root "`/`" scope. The user deploying the NoOps Accelerator reference implementation is made an owner at the intermediate root management group (for example "ANOA").

For more information about tenant-level deployments in Azure, see [Deploy resources to tenant](https://docs.microsoft.com/azure/azure-resource-manager/templates/deploy-to-tenant).

## If we already deployed Mission Landing Zone, do we have to delete everything and start again to use NoOps Accelerator?

If you used the Mission Landing Zone to deploy into your Azure tenant, see the guidance for the NoOps Accelerator infrastructure-as-code tooling you want to use.

### Bicep

The [NoOps Accelerator](https://github.com/Azure/NoOpsAccelerator) tooling supports deploying Bicep files at the [four Azure scopes](https://docs.microsoft.com/azure/azure-resource-manager/management/overview#understand-scope).

> Expand more on how to use bicep

Leave us feedback via [GitHub issues on the NoOps Accelerator repository](https://github.com/Azure/NoOpsAccelerator/issues) if you want to see something added to NoOps Accelerator.

### Next steps

