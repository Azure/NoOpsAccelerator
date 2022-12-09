# Overlays: Management Services

## Overview

Azure NoOps Accelerator management services overlays are module templates that can be used to extend an new or existing Platform Landing Zones or Enclave.

## Management Services Explanations

Service | Description |  Link|
------- | ----------- | -----|
Azure App Service Plan | This overlay module deploys an App Service Plan (AKA: Web Server Cluster) to support simple web accessible linux docker containers.  It also optionally supports the use of dynamic (up and down) scale settings based on CPU percentage up to a max of 10 compute instances. | [Azure App Service Plan](../management-services/app-service-plan/deploy.bicep)
Azure Application Gateway | This overlay module adds an web traffic load balancer that enables you to manage traffic to your web applications. This application gateway is meant to be in the Hub Network. | [Azure Application Gateway](../management-services/applicationGateway/deploy.bicep)
Azure Automation Account | This overlay module deploys an Platform Landing Zone compatible Azure Automation account, with diagnostic logs pointed to the Platform Landing Zone Log Analytics Workspace (LAWS) instance. | [Azure Automation Account](../management-services/automation/deploy.bicep)
Azure Security Center | This overlay module adds a standard/defender sku which enables a greater depth of awareness including more recomendations and threat analytics. | [Azure Security Center](../management-services/azureSecurityCenter/deploy.bicep)
Bastion Host | This overlay module adds a linux and windows virtual machines to the Hub resource group to serve as a jumpbox into the network using Azure Bastion Host as the remote desktop solution without exposing the virtual machine via a Public IP address. | [Bastion Host](../management-services/bastion/deploy.bicep)
Azure Container Registry | This overlay module deploys a premium Azure Container Registry suitable for hosting docker containers. The registry will be deployed to the Hub/Spoke shared services resource group using default naming unless alternative values are provided at run time. | [Azure Container Registry](../management-services/bastion/deploy.bicep)
Azure Data Bricks Workspace (In Progress) | This overlay module deploys a premium Azure Data Bricks Workspace. | [Azure Data Bricks Workspace](../management-services/dataBricksWorkspace/deploy.bicep)
Azure Key Vault | This overlay module deploys a premium Azure Key Vault with RBAC enabled to support secret, key, and certificate management. A premium key vault utilizes hardware security modules to protect key material. | [Azure Key Vault](../management-services/keyvault/deploy.bicep)
Azure Kubernetes Service - Private Cluster | This overlay module deploys a Azure Kubernetes Service - Private Cluster - Kubenet suitable for hosting docker containers apps. The cluster will be deployed to the Hub/Spoke shared services resource group or Tier 3 spoke using default naming unless alternative values are provided at run time. | [Azure Kubernetes Service](../management-services/kubernetesPrivateCluster-Kubnet/deploy.bicep)
Microsoft Service Health Alerts | This overlay module deploys Microsoft Service Health Alerts to the target resource group.| [Microsoft Service Health Alerts](../management-services/service-health/deploy.bicep)
 Azure Storage Account | This overlay module deploys a premium Azure Storage Account with RBAC enabled to support secret, key, and certificate management. | [Azure Storage Account](../management-services/storageAccount/deploy.bicep)
Subscription Budgets | This overlay module adds a standard/defender sku which enables a greater depth of awareness including more recomendations and threat analytics.This overlay module deploys a budget for an Azure Enterprise Agreement (EA) subscription. | [Subscription Budgets](../management-services/subscription-budget/deploy.bicep)
Tier 3 Workload Spoke Network | This overlay module deploys Tier 3 Workload network deployment based on the recommendations from the Azure Mission Landing Zone Conceptual Architecture. | [Tier 3 Workload Spoke Network](../management-services/workloadSpoke/deploy.bicep)

