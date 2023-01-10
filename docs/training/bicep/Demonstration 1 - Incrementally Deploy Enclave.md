# Demonstration 1: Incrementally Deploy a Mission Enclave with Azure Kubernetes Services

This document details a step-by-step deployment of a mission enclave with Azure Kubernetes Services with bicep.

## Setup & Prerequisite Software

1. Installed the latest version of [Git client](https://git-scm.com)

1. Installed the latest version of [Visual Studio Code](https://code.visualstudio.com/)

1. Installed the [bicep extension](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#vs-code-and-bicep-extension) in Visual Studio Code

1. Installed the latest version of [PowerShell](https://github.com/powershell/powershell#get-powershell)

1. Installed latest version of the **Azure PowerShell** module. See [Install the Azure Az PowerShell module](https://learn.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-9.0.1) for more information.

    **PowerShell Quick Installation for Azure PowerShell**

    ``` PowerShell
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    ```

1. Installed the latest version of [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually)

1. Download the latest release of the [NoOps Accelerator](https://github.com/Azure/NoOpsAccelerator/releases) to your local system.  This demonstration uses **c:\anoa** as the root directory containing the downloaded and unzipped release from GitHub

## Before we Begin

You will be making modifications to several .json files for the deployment which require knowing several sensitive pieces of information.  You will also create a group in your Azure Active Directory, and you will need that group's object id.  Finally, you will be creating an application registration in Azure Active Directory and will need the client id and secret.

This demonstration has several **optional** steps that are not required for success, but demonstrate additional functionality and context when using the NoOps Accelerator.

## Using PowerShell

Saving data as variables for use while executing this demonstration will greatly ease your implementation.  This will make executing the commands through PowerShell simpler.

``` PowerShell
# Connect to your Environment.  Use Get-AzEnvironment for a complete list.
Connect-AzAccount -Environment [AzureChinaCloud | AzureGermanCloud | AzureCloud | AzureUSGovernment]

# Store Context as a variable to simplify use in Bicep commands
$context = Get-AzContext

# Store your location in a variable to simplify use in Bicep commands.  Use Get-AzLocation | Select-Object -Property DisplayName,Location for a complete list
$location = [your region]
```

## Part 1: Create Management Groups

---

> **Note:** You must meet the following requirements before you can create management groups:
>
> 1. A user that is Global Admin in the Azure Active Directory
>
> 1. Elevation of privileges of this user which grants him/her the “User Access Administrator” permission at the tenant root scope
>
> 1. An explicit roleAssignment (RBAC) made at the tenant root scope via CLI or PowerShell (Note: There’s no portal UX to make this roleAssignment)
>
> See [Azure NoOps Accelerator Prerequisites](https://github.com/Azure/NoOpsAccelerator/blob/main/docs/Pre-requisites.md) for more information.

1. Open PowerShell and change to your directory containing the NoOps Accelerator, this demonstration uses **c:\anoa**

1. Issue the command `Connect-AzAccount -Environment [AzureChinaCloud | AzureGermanCloud | AzureCloud | AzureUSGovernment]` to log into your tenant

1. Issue `$context = Get-AzContext`

1. Issue `$location = \<your Azure region\>` where Azure region is a region from `Get-AzLocation | Select-Object -Property DisplayName,Location`

1. While in the **c:\anoa** directory in your PowerShell session, issue `code .` to open Visual Studio Code

1. Navigate to the **/src/bicep/overlays/management-groups/** directory

1. Open the **/parameters/deploy.parameters.json** file and make the following changes:

    - parManagementGroups.value.parentMGName: **$context.Tenant.Id**

    - parSubscriptions.value.subscriptionId: **$context.Subscription.Id**

    - parTenantId.value: **$context.Tenant.Id**

1. In your PowerShell session issue `Set-Location -Path 'c:\anoa\src\bicep\overlays\management-groups'`

1. Issue the command updating the location parameter to the region you wish to deploy to:

    **PowerShell with Azure PowerShell Module**

    ``` PowerShell
    New-AzManagementGroupDeployment -Name 'deploy-enclave-mg' -TemplateFile '.\deploy.bicep' -TemplateParameterFile '.\parameters\deploy.parameters.json' -ManagementGroupId $context.Tenant.Id -Location $location -Verbose
    ```

    > **Warning:** If you receive the following error:
    >
    > New-AzManagementGroupDeployment: Error: Code=MultipleErrorsOccurred; Message=Multiple error occurred: Conflict. Please see details. New-AzManagementGroupDeployment: The deployment validation failed.
    >
    > Add the **-WhatIf** parameter to your command to inspect the details.  Usually, this error indicates that you already have a management group structure in your tenant.

    > **Note:** This operation will move your subscription to the **management** management group in the structure.  If you plan to delete the structure remember to **MOVE** your subscription from the **management** management group to your tenant root

## Part 2:  Create Roles

---

1. In your PowerShell session Issue `Set-Location -Path 'c:\anoa\src\bicep\overlays\roles'`

1. Open the **parameters/deploy.parameters.all.json** file and make the following changes:

    - parAssignableScopeManagementGroupId: **ANOA** (if you are not using the default, change to the name of your intermediate management group)

1. Issue the command below and be sure to update the **--management-group-id** parameter of the command to your intermediate management group name or **ANOA** if you are using the default

    **PowerShell with Azure PowerShell Module**

    ``` PowerShell
   New-AzManagementGroupDeployment -Name 'deploy-scus-enclave-roles' -TemplateFile '.\deploy.bicep' -TemplateParameterFile '.\parameters\deploy.parameters.all.json' -ManagementGroupId 'ANOA' -Location $location -Verbose
    ```

    > **Note:** You can verify your role creation using the following PowerShell command: `Get-AzRoleDefinition | Where-Object -FilterScript {$_.Name -like 'Custom -*'} | Format-Table Name,Description`

    > **Hint:** Use `Get-AzRoleDefinition | Where-Object -FilterScript {$_.Name -like 'Custom -*'} | Format-Table Name,Id` to get your roles with the Object ID for use with other .json files in your deployments

## Part 3: Delpoy NIST 800.53 R5 Policy

---

1. In your PowerShell session Issue `Set-Location -Path 'c:\anoa\src\bicep\overlays\policy\builtin\assignments'`

1. Open the **policy-nist80053r5.parameters.json** file and make the following changes:

    - parPolicyAssignmentManagementGroupId: **ANOA** (if you are not using the default, change to the name of your intermediate management group)

1. Issue the command below and be sure to update the **--management-group-id** parameter of the command to your intermediate management group name or **ANOA** if you are using the default

    **PowerShell with Azure PowerShell Module**

    ``` PowerShell
    New-AzManagementGroupDeployment -Name 'deploy-scus-policy-nistr5' -TemplateFile '.\policy-nist80053r5.bicep' -TemplateParameterFile '.\policy-nist80053r5.parameters.json' -ManagementGroupId 'ANOA' -Location $location -Verbose
    ```

## Part 4: Deploy 3-Spoke Platform

---

1. In your PowerShell session Issue `Set-Location -Path 'c:\anoa\src\bicep\platforms\lz-platform-scca-hub-3spoke'`

1. Open the **parameters/deploy.parameters.json** file and make the following changes:

    - parRequired.value.orgPrefix: **ANOA** (if you are not using the default, change to the name of your intermediate management group)

    - parTags.value.organization: **ANOA** (if you are not using the default, change to the name of your intermediate management group)

    - parTags.value.region: **$location**

    - parHub.value.subscriptionId: **$context.Subscription.Id**

    - parIdentitySpoke.value.subscriptionId: **$context.Subscription.Id**

    - parOperationsSpoke.value.subscriptionId: **$context.Subscription.Id**

    - parSharedServicesSpoke.value.subscriptionId: **$context.Subscription.Id**

    - parNetworkArtifacts.value.enable: **true**

        > **Note:** Enabling parNetworkArtifacts will create an Azure Key Vault which is used to store the Azure Bastion host credentials.  It is optional, but does secure and simplify access Azure Bastion later.

    - parNetworkArtifacts.value.artifactsKeyVault.keyVaultPolicies.objectId: **x**

        > **Note:** This is an object Id representing an individual or group from your Azure Active Directory who have the permissions assigned for secrets

    - parNetworkArtifacts.value.artifactsKeyVault.keyVaultPolicies.tenantId: **$context.Tenant.Id**

1. Issue the command updating the **--location** parameter to your location

    **Azure CLI**
    ``` PowerShell
    az deployment sub create --name 'deploy-hub3spoke-network' --subscription $context.Subscription.Id --template-file 'deploy.bicep' --location $location --parameters '@parameters/deploy.parameters.json' --only-show-errors
    ```

### Part 5: Deploy Kubernetes Workload

---

##### Create an Azure Active Directory Group

1. Return to your Azure Portal

1. Navigate to your Azure Active Directory

1. Click on **Groups** in the left navigation

1. Click on **New Group** in the top breadcrumb navigation

1. Provide the following information:

    - Group Type: **security**

    - Group Name: **K8S Cluster Administrators**

    - Group Description: **Administrators of Kubernetes Clusters**

    - Owners: **<\< your login \>>**

    - Members: **<\< your login \>>**

    - Click the **Create** button

1. Record the Object Id for the group, this will be used in the workload deployment for Kubernetes

##### Create an App Registration in Azure Active Directory

1. Return to your Azure Portal

1.  Navigate to your Azure Active Directory

1.  Click on **App Registrations** in the left navigation menu

1.  Click on **+New Registration** in the top breadcrumb navigation

1. Provide the following information:

    - Name: **ar-eastus-k8s-anoa-01** or a name of your liking

    - Supported Account Types: **Accounts in this organizational directory only (... - Single Tenant)**

    - Redirect URI (Optional): **do not configure, leave as default**

    - Click the **Register** button

1. Click on **Overview** in the left navigation and record the following information:

    - Application (client) ID:  **<\< client id \>>**

1. Click on **Certificates & Secrets** in the left navigation

1. Click on **+New Client Secret** and provide the following information:

    - Description: Kubernetes App Registration for ANOA

    - Expires: 3 months or choose an appropriate time for your organization

    - Click the **Add** button

1. Copy and record the Secret ID.  You will use this in your Kubernetes workload deployment.

##### Deploy Kubernetes Workload

1. In your PowerShell session Issue **Set-Location -Path 'c:\anoa\src\bicep\workloads\wl-aks-spoke'**

1. Open the **/parameters/deploy.parameters.json** file and make the following changes:

	- parRequired.orgPrefix: **ANOA** or your Intermediate management group name

    - parTags.organization: **ANOA** or your Intermediate management group name

    - parWorkloadSpoke.subscriptionId: **$context.Subscription.Id**

    - parHubSubscriptionId: **$context.Subscription.Id**

    - parHubVirtualNetworkResourceId: **$context.Subscription.Id**

    - parLogAnalyticsWorkspaceResourceId: **$context.Subscription.Id**

    - parKubernetesCluster.aksClusterKubernetesVersion: **1.24.6**

        > NOTE: Issue the command **az aks get-versions --location eastus --query orchestrators[-1].orchestratorVersion --output tsv** to retrieve your regions highest version

    - parKubernetesCluster.aadProfile.aadProfileTenantId: **$context.Tenant.Id**

    - parKubernetesCluster.aadProfile.aadProfileAdminGroupObjectIds: **the Object ID from the K8S Cluster Administrators group**

    - parKubernetesCluster.addonProfiles.config.logAnalyticsWorkspaceResourceId: **$context.Subscription.Id**

    - parKubernetesCluster.servicePrincipalProfile.clientId: **<<your app registration application (client) ID >>**

    - parKubernetesCluster.servicePrincipalProfile.secret: **<<your app registration application (client) ID’s secret>>**

1.  Issue the command updating the **--subscription** parameter with your subscription id and the **--location** parameter to your location

    **Azure CLI**
    ``` PowerShell
    az deployment sub create --name 'deploy-aks-network' --template-file 'deploy.bicep' --parameters '@parameters/deploy.parameters.json' --location $location --subscription $context.Subscription.Id --only-show-errors
    ```

##### References
---
[Deploying Management Groups with the NoOps Accelerator](https://github.com/Azure/NoOpsAccelerator/tree/main/src/bicep/overlays/management-groups)
[Deploying Roles with the NoOps Accelerator](https://github.com/Azure/NoOpsAccelerator/tree/main/src/bicep/overlays/roles)
[Deploying Policy for Guardrails with the NoOps Accelerator](https://github.com/Azure/NoOpsAccelerator/tree/main/src/bicep/overlays/Policy)
[Deploying SCCA Compliant Hub and 1-Spoke using the NoOps Accelerator](https://github.com/Azure/NoOpsAccelerator/tree/main/src/bicep/platforms/lz-platform-scca-hub-1spoke)
[Deploying a Kubernetes Private Cluster Workload using the NoOps Accelerator](https://github.com/Azure/NoOpsAccelerator/tree/main/src/bicep/workloads/wl-aks-spoke)
