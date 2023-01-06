# Demonstration: Incrementally Deploy a Mission Enclave with Azure Kubernetes Services using NoOps
<div class="title">A step-by-step deployment using the NoOps Accelerator to deploy an infrastructure with a private Kubernetes cluster.
</div>

### Setup & Prerequisite Software

1. You must have installed the latest [Git client](https://git-scm.com) for working with source control

1. You must have the latest version of [Visual Studio Code](https://code.visualstudio.com/) for authoring bicep files

1. Installed the [bicep extension](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#vs-code-and-bicep-extension) in Visual Studio Code

1. You must have installed either the the latest version of **AZ CLI**, see [How to install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli), or **Azure PowerShell**, see [Install the Azure Az PowerShell module](https://learn.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-9.0.1) for deploying bicep files

    **PowerShell Quick Installation for Azure CLI**
    ``` PowerShell
    $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
    ```

    **PowerShell Quick Installation for Azure PowerShell**
    ``` PowerShell
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    ```

1. You must have installed the latest version of [Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-powershell)

1. Either clone, fork, or download the [NoOps Accelerator](https://github.com/Azure/NoOpsAccelerator) to your local system.  This demonstration uses **c:\anoa** as the root directory containing the downloaded, cloned, or forked project from GitHub

### Before we Begin

You will be making modifications to several .json files for the deployment which require knowing several sensitive pieces of information.  You will also create a group in Azure Active Directory, and you will need that group's object id.  Finally, you will be creating an application registration in Azure Active Directory and will need the client id and secret.

You can record those values here or, preferred, using your terminal save the values as variables.  Additionally, you can record and save these values in Azure Key Vault if using the Azure NoOps Accelerator on a pipeline or through a automation platform.

#### OPTIONAL

If you choose to save and record your values use the table below.  This is sensitive information and care should be taken.

| Name | Value(s) | How Used |
| --- | --- | --- |
| Tenant ID | <div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div> | When deploying management groups or policies. |
| Subscription ID(s) | <div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div></br><div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div><br/><div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div> | When deploying workloads, overlays, enclaves, or platforms.  You can use multiple subscriptions for your tiers. |
| Principal ID(s) | <div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div><br/><div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div><br/><div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div> | When using either built-in roles or custom deployed ANOA roles for securing resources. |
| Object ID(s) | <div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div><br/><div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div> | When deploying resources that need to use an Active Directory Group for access control. |
| Client ID(s) | <div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div><br/><div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div> | When deploying your Kubernetes cluster for the application registration. |
| Location | <div style="height: 20px;background-color: #CFD8DC;width: 300px;"></div> | When deploying workloads, overlays, enclaves, or platforms (eastus, usgovvirgina, etc..). |

#### OPTIONAL

Saving data as variables for use while executing this demonstration or lab.  This will make executing the commands through PowerShell simpler.

``` PowerShell
az cloud set --name [AzureCloud | AzureUSGovernment]

az login

$context = Get-AzContext

$location = ["eastus" | "usgovvirginia"]
```

### Part 1: Create Management Groups

---

> NOTE: For this demonstration we will be using AZ CLI with PowerShell

1. Open PowerShell and change to your directory containing the NoOps Accelerator, this demonstration uses **c\anoa**

1.  Issue the command **az login** and log into your tenant

1. Issue **$context = Get-AzContext** and record the following values:

    - Tenant ID: **$context.Tenant.Id**

    - Subscription ID: **$context.Subscription.Id**

    > **NOTE**: If more than one value is returned, choose the subscription you are targeting to create the management group structure and choose the tenant id for that subscription.  You can also use **Set-AzContext** to set your current subscription for this session.

1. Open Visual Studio Code in your directory containing the NoOps Accelerator

1. Change to the **/src/bicep/overlays/management-groups/** directory

1. Open the **/parameters/deploy.parameters.json** file and make the following changes:

    - parentMGName: **$context.Tenant.Id**

    - subscriptionId: **$context.Subscription.Id**

    - parTenantId: **$context.Tenant.Id**

1. In your PowerShell session issue **Set-Location -Path 'c:\anoa\src\bicep\overlays\management-groups'**

1. Issue the command updating the location parameter to the region you wish to deploy to:

    **Azure CLI**
    ``` PowerShell
    az deployment mg create --name 'deploy-enclave-mg' --template-file 'deploy.bicep' --parameters '@parameters/deploy.parameters.json' --management-group-id $context.Tenant.Id --location $location --only-show-errors
    ```

    > **NOTE**: This operation will move your subscription to the **management** management group in the structure

    > **WARNING**: If you plan to delete the structure remember to **MOVE** your subscription from the **management** management group to your tenant root

### Part 2:  Create Roles

---

1. In your PowerShell session Issue **Set-Location -Path 'c:\anoa\src\bicep\overlays\roles'**

1. Open the **/parameters/deploy.parameters.all.json** file and make the following changes:

    - parAssignableScopeManagementGroupId: **ANOA** (if you are not using the default, change to the name of your intermediate management group)

1.  Issue the command updating the **--management-group-id** paramter to your intermediate management group name or **ANOA** as the default

    **Azure CLI**
    ``` PowerShell
    az deployment mg create --name 'deploy-enclave-roles' --template-file 'deploy.bicep' --parameters '@parameters/deploy.parameters.all.json' --management-group-id 'ANOA' --location $location --only-show-errors
    ```

### Part 3: Delpoy NIST 800.53 R5 Policy

---

1. In your PowerShell session Issue **Set-Location -Path 'c:\anoa\src\bicep\overlays\policy\builtin\assignments'**

1. Open the **deploy-nist80054r5.parameters.json** file and make the following changes:

    - parPolicyAssignmentManagementGroupId: **ANOA** (if you are not using the default, change to the name of your intermediate management group)

1.  Issue the command updating the **--management-group-id** parameter to your intermediate management group name, or use the default value of  **ANOA**,  and your **--location**

    **Azure CLI**
    ``` PowerShell
    az deployment mg create --name 'deploy-policy-nistr5' --template-file 'policy-nist80053r5.bicep' --parameters 'policy-nist80053r5.parameters.json' --management-group-id 'ANOA' --location $location --only-show-errors
    ```

### Part 4: Deploy 3-Spoke Platform

---

1. In your PowerShell session Issue **Set-Location -Path 'c:\anoa\src\bicep\platforms\lz-platform-scca-hub-3spoke'**

1. Open the **/parameters/deploy.parameters.json** file and make the following changes:

    - parRequired.orgPrefix: **ANOA** (if you are not using the default, change to the name of your intermediate management group)

	- parTags.organization: **ANOA** (if you are not using the default, change to the name of your intermediate management group)
	
    - parHub.subscriptionId: **$context.Subscription.Id**

    - parIdentitySpoke.subscriptionId: **$context.Subscription.Id**
	
    - parOperationsSpoke.subscriptionId: **$context.Subscription.Id**

    - parSharedServicesSpoke.subscriptionId: **$context.Subscription.Id**

1.  Issue the command updating the **--location** parameter to your location

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
