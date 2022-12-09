[![Good First Issues](https://img.shields.io/github/issues/Azure/NoOpsAccelerator/good%20first%20issue?color=important&label=good%20first%20issue&style=flat)](https://github.com/Azure/NoOpsAccelerator/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
[![Needs Feedback](https://img.shields.io/github/issues/Azure/NoOpsAccelerator/needs%20feedback?color=blue&label=needs%20feedback%20&style=flat)](https://github.com/Azure/NoOpsAccelerator/issues?q=is%3Aopen+is%3Aissue+label%3A%22needs+feedback%22)

# Azure NoOps Accelerator

> **"NoOps automates platform administration and broaden communication between developers, cyber, and operations to achieve mission success**." - *John Spinella, Creator of the Azure NoOps Accelerator*

**Azure NoOps Accelerator** is a flexible foundation
that enables US Department of Defense and other Public Sector customers
to quickly develop and maintain
opinionated, policy-driven, and self-service
enclaves in their Azure environments.

Delivered as a collection of infrastructure as code (IaC) [module templates](https://github.com/Azure/NoOpsAccelerator/tree/main/src/bicep) written in Bicep, the NoOps Accelerator is intended to empower organizations on their journey towards a continuous deployment and governance model for their cloud infrastructure.

Learn more about the NoOps movement and philosphy here - *[What is NoOps?](https://github.com/Azure/NoOpsAccelerator/tree/main/docs/wiki/What-is-NoOps.md)*.

## Quickstart

While the NoOps Accelerator can be used to build all sorts of useful solutions, a simple place to start is deploying a workload platform.
You can use the NoOps Accelerator to deploy [SCCA-compliant landing zones](./src/bicep/platforms/) based on Microsoft's [SACA implementation guidance][saca] and [Mission Landing Zone][mlz] architecture.

### Deploy a SCCA-compliant Landing Zone (SCCA Hub with 3 Spokes) using the Azure CLI

These steps walk through how to use NoOps to deploy a hub and spoke architecture. At the conclusion, you will have five resource groups mapped to the following:

* Hub: SCCA-compliant networking hub (1 vnet, 1 resource group)
* Tier 0 (T0): Identity & Authorization (1 vnet, 1 resource group)
* Tier 1 (T1): Infrastructure Operations, and Logging (1 vnet, 2 resource groups)
* Tier 2 (T2): DevSecOps & Shared Services (1 vnet, 1 resource group)

> **Note:** The deployment requires Bicep CLI version 0.11.1 (030248df55) or later. You can check your version by running `bicep --version`. You can upgrade by running `az bicep upgrade`.

Steps:

1. Clone the repository down and change directory to the `lz-platform-scca-hub-3spoke` directory

    ```plaintext
    git clone https://github.com/Azure/NoOpsAccelerator.git
    cd NoOpsAccelerator/src/bicep/platforms/lz-platform-scca-hub-3spoke
    ```

1. Deploy the landing zone with the `az deployment sub create` command.
For a quickstart, we suggest a test deployment into the current AZ CLI subscription using these parameters:

    * `--name`: (optional) The deployment name, which is visible in the Azure Portal under Subscription/Deployments.
    * `--location`: (required) The Azure region to store the deployment metadata.
    * `--template-file`: The file path to the `deploy.bicep` template.
    * `--parameters`: The file path to the `parameters/deploy.parameters.json` file, preceded by `@`.
        Individual parameters can be overwritten using `<parameter>=<value>` format as well.
    * `--subscription`: The GUID for the subscription to deploy into.
        Multiple subscriptions may be configured (*i.e.*, to have separate subscriptions for each 'tier' in the MLZ architecture) in the `parameters/deploy.parameters.json`

> **IMPORTANT**: All values will need to be updates in the `parameters/deploy.parameters.json`. This allows for consistency in the parameters.  

    Here is an example that deploys into a single subscription in the EastUS region of Azure Commercial:

    ```plaintext
    # Replace with your test Azure Subscription ID
    AZ_SUBSCRIPTION="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

    az login
    cd src/bicep
    cd platforms/lz-platform-scca-hub-3spoke
    az deployment sub create \
        --name deploy-scca-hub-with-3-spokes \
        --location EastUS \
        --template-file deploy.bicep \
        --parameters @parameters/deploy.parameters.json \
        --subscription $AZ_SUBSCRIPTION
    ```

1. After a successful deployment, see the **[enclaves](./src/bicep/enclaves/)** folder for examples of complete, outcome-driven solutions built using the NoOps Accelerator. Also, be sure to take a look through our **[workloads](.src/bicep/workloads)** and **[overlays](./src/bicep/overlays)** folders to get a sense of the available pieces you can put together with the **platform** you just deployed to solve your mission challenges.

1. Don't forget to **clean-up your environment** by removing all of the resource groups created by the deployment when you are done with this Quickstart.

> Don't have Azure CLI? Here's how to get started with Azure Cloud Shell in your browser: <https://docs.microsoft.com/en-us/azure/cloud-shell/overview>

<!-- For more detailed deployment instructions, see our deployment guides for [Bicep](docs/deployment-guide-bicep.md) and [Terraform](docs/deployment-guide-terraform.md). -->

## Goals and Non-Goals of the Azure NoOps Accelerator Project

### Goals

* Design for US Government mission customers, with a specific focus on the US Department of Defense and Military Departments.
* Provide reusable and composable IaC modules that hyper-automate infrastructure deployment using Microsoft's best practices.
* Simplify compliance management through automated audit, reporting, and remediation.
* Deliver example [Platform modules](./src/bicep/platforms/) that implement SCCA controls and  follow [Microsoft's SACA implementation guidance](https://aka.ms/saca).
* Support deployment to Azure Commercial, Azure Government, Azure Government Secret, and Azure Government Top Secret clouds.
* Accelerate the US Government's use of Azure by easing the onboarding of mission workloads, spanning mission applications, data, artificial intelligence, and machine learning.

### Non-Goals

* The NoOps Accelerator cannot automate the approval for Authority to Operate (ATO), though it will enable Customers to collect, customize, and submit for ATO based on their departmental requirements.
* The NoOps Accelerator will not strive for 100% compliance on all deployed Azure Policies for reference implementations. Customers must review [Microsoft Defender for Cloud Regulatory Compliance dashboard](TBD) and apply appropriate exemptions.

<!--
* Compliant on all Azure Policies when the reference implementation is deployed. This is due to the shared responsibility of cloud and customers can choose the Azure Policies to exclude. For example, using Azure Firewall is an Azure Policy that will be non-compliant since majority of the DOD/Public Sector customers use Network Virtual Appliances. 
-->

## Getting Started

Definitions of NoOps primitives.

<!--

Full deployment of a workload that is Secure Cloud Computing
Architecture, SCCA compliant Monitoring, policy, governance, a
workload, and role based access control (RBAC) will be
implemented.

-->

### Architecture

| Primitive | Definition |
| :---------------| :--------- |
| **AzResources** | Wrap [Azure Resource Providers](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-services-resource-providers) so that they understand how to fit and work together. The most basic building blocks in NoOps. |
| **Overlays** | Extend *AzResources* with specific configurations or combine them to create more useful objects.<BR/><BR/>For example, one could use the `kubernetesCluster` overlay to deploy a Private AKS Cluster rather than using the `Microsoft.ContainerService/managedClusters` AzResource to deploy a vanilla AKS cluster.<BR/><BR/>Similarly, one could create a `virtualMachine` overlay that combines the deployment of a `Microsoft.Network/networkInterfaces` with a `Microsoft.Compute/virtualmachine` since you will rarely if ever deploy a VM without an associated NIC. |
| **Platforms** | Combine *Overlays* and *AzResources* to lay the networking required to support mission workloads. NoOps is provided with two SCCA-compliant hub-and-spoke landing zone platforms. The [Quickstart](#quickstart) above walks through the deployment of a SCCA-compliant hub-and-3-spoke platform.
| **Workloads** | Combine *Overlays* and *AzResources* to create solutions that achieve mission and operational goals. For example, one could mix a `kubernetesCluster` overlay (Private AKS Cluster) with a `Microsoft.ContainerRegistry` AzResource to create a **Dev Environment** Workload.<BR/><BR/>Workloads can be deployed into either a new or an existing hub-peered virtual network.|
| **Enclaves** | Bring it all together -- combining a single *Platform* with one or more *Workloads*, and mixing in Zero Trust governance and RBAC -- to enable the rapid, repeatable, auditable, and authorizable deployment of outcome-driven infrastructure. |

<!-- markdownlint-disable MD033 -->
<!-- allow html for images so that they can be sized -->
<img src="docs/media/NoOpsPrimitives.png" alt="A diagram that depicts the relationships between the NoOps Primitives, with AzResources on the bottom, flowing through Overlays into both Platforms and Workloads, and finally Enclaves on top." width="800" />
<!-- markdownlint-enable MD033 -->

### Telemetry

Microsoft can identify the deployments of the Azure Resource Manager and Bicep templates with the deployed Azure resources. Microsoft can correlate these resources used to support the deployments. Microsoft collects this information to provide the best experiences with their products and to operate their business.  The telemetry is collected through [customer usage attribution](https://docs.microsoft.com/azure/marketplace/azure-partner-customer-usage-attribution). The data is collected and governed by Microsoft's privacy policies, located at [https://www.microsoft.com/trustcenter](https://www.microsoft.com/trustcenter).

If you don't wish to send usage data to Microsoft, you can set the `customerUsageAttribution.enabled` setting to `false` in `global/telemetry.json`.

Project Bicep [collects telemetry in some scenarios](https://github.com/Azure/bicep/blob/main/README.md#telemetry) as part of improving the product.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Feedback, Support, and How to Contact Us

Please see the [Support and Feedback Guide](https://github.com/Azure/NoOpsAccelerator/blob/update-repo/SUPPORT.md). To report a security issue please see our [security guidance](https://github.com/Azure/NoOpsAccelerator/blob/update-repo/SECURITY.md).

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.

## Special Thanks and Liner Notes

This project is greatly influenced by and owes a debt of gratitude to the following:

* [Common Azure Resource Modules Library](aka.ms/carml)
* [Azure Landing Zones for Canadian Public Sector](https://github.com/azure/canadapubsecalz)
* [Mission Landing Zone][mlz]

<!-- Below this line is old content for salvaging

-------------------------------------------------------------------------------------------

Azure NoOps Accelerator Architecture supported up to IL6 (Top Secret) - Cloud Only Applications. This flexible foundation is applicable to Infrastructure as a Service (IaaS) and Platform as a Service (PaaS) with characteristics:

* Cloud-based services hosting sensitive (up to IL6 (Top Secret)) information
* No direct system to system network interconnections required with data centers

This implementation is specific to DOD/Public Sector organizations.



## Requirements for Successful NoOps

### Tenets of NoOps

1. Streamline End-to-End Platform/Workload Automation.
2. Automate Security & Governance at Scale
3. Continuous Real Time Observability, Telemetry, and Monitoring.
4. Process and Automation is Top Priority.

### DevOps Mindset

Driving the DevOps mindset will prepare your team to handle collaboration, change control and the continuous deployment. Much of this is common to your developers but maybe new to cyber & operations.

### Roles & Skillsets

To have success with NoOps, you will need:

* Development staff that is capable with modern DevOps practices & tools such as source control (Git), & Continuous Integration/Delivery (CI/CD).

* Cyber Security Staff would take ownership of policy-oriented development in coordination with the Development staff.

* Operations staff to define architecture that meets the policy needs which is coded by the Development staff.

### Shared Responsibility Model

Even though development, cyber & operations team members have specific roles and responsibilities, it is the collaboration between these three groups that will make NoOps successful.

### Leadership Support

Policy-driven governance is a core tenet of NoOps that requires direct leadership input. Many operations organizations do not have development staff which is necessary for NoOps success therefore leadership should be aware of the potential staffing gap.

## What are we solving for with the NoOps Accelerator?

### Mission Outcome Success

All in one solution that takes the best practices from Mission Landing Zone architecture and creates a full ATO compliant enclave.

### Security & Governance at Scale

Policy-Driven guardrails using in-band and out-of-band polices ensure that deployed workloads and applications are compliant with your command’s cyber-security and compliance requirements, and therefore a securing a path on driving mission outcomes. Policy-driven governance is one of the key design principles of this accelerator.

### Streamlined End-to-End Platform/Workload Automation

Using pre-configured templates and policy-driven resources where core systems administration tasks are fully automated allows developers to focus on driving mission outcomes.

## Architecture

See [architecture documentation](docs/NoOpsAccelerator-Architecture.md) for detailed walkthrough of design.

Deployment to Azure is supported using GitHub Actions and can be adopted for other automated deployment systems like Gitlab, Jenkins, etc.

The automation is built with Azure Bicep and Azure Resource Manager template.

## Bicep Modules

In the [src\bicep](src/bicep) directory contains all of the modules required to deploy NoOps Accelerator components.

## Product Roadmap

See the Projects page for the release timeline and feature areas.

Here's a summary of what NoOps Accelerator deploys of as of December 2021:

image

-->

[//]: # (************************)
[//]: # (INSERT LINK LABELS BELOW)
[//]: # (************************)

[mlz]:                            https://github.com/Azure/missionlz "Mission Landing Zone GitHub Repo"
[saca]:                                        https://aka.ms/saca "Microsoft Secure Azure Computing Architecture (SACA) Guidance"
