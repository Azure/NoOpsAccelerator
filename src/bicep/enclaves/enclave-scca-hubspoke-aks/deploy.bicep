/*
SUMMARY: Module Example to deploy the Full Hub/ 1 Spoke Enclave with AKS Workload
DESCRIPTION: The following components will be options in this deployment
            * Managment Groups
            * Policy (Network, IAM, Data Protection, Monitoring, AKS)
            * Roles
            * Hub Virtual Network (VNet)              
              * Operations Artifacts (Optional)
              * Bastion Host (Optional)
              * DDos Standard Plan (Optional)
              * Microsoft Defender for Cloud (Optional)              
            * Spokes
             * Operations (Tier 1)
            * Logging
              * Azure Sentinel
              * Azure Log Analytics            
            * Azure Firewall
            * Private DNS Zones - Details of all the Azure Private DNS zones can be found here --> [https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration) 
            * Workload: (Tier 3) - Azure Kubernetes Service
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

/*
  PARAMETERS
  Here are all the parameters a user can override.
  These are the required parameters that Network does not provide a default for:    
    - parDeployEnvironment
*/

// **Scope**
targetScope = 'managementGroup'

// REQUIRED PARAMETERS
// Example (JSON)
// -----------------------------
// "parRequired": {
//   "value": {
//     "orgPrefix": "anoa",
//     "templateVersion": "v1.0",
//     "deployEnvironment": "mlz"
//   }
// }
@description('Required values used with all resources.')
param parRequired object

// REQUIRED TAGS
// Example (JSON)
// -----------------------------
// "parTags": {
//   "value": {
//     "organization": "anoa",
//     "region": "eastus",
//     "templateVersion": "v1.0",
//     "deployEnvironment": "platforms",
//     "deploymentType": "NoOpsBicep"
//   }
// }
@description('Required tags values used with all resources.')
param parTags object

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

// SUBSCRIPTIONS

// HUB NETWORK
// Example (JSON)
// -----------------------------
@description('The object for the Hub Network and resources. It defaults to the deployment subscription.')
param parHub object

// OPERATIONS SPOKE NETWORK 
// Example (JSON)
// -----------------------------
@description('The object for the Operations Spoke Network and resources. It defaults to the deployment subscription.')
param parOperationsSpoke object

// OPERATIONS NETWORK ARTIFACTS
// Example (JSON)
// -----------------------------
// "parNetworkArtifacts": {
//   "value": {
//     "enable": false,
//     "artifactsKeyVault": {
//       "keyVaultPolicies": {
//         "objectId": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx",
//         "permissions": {
//           "keys": [
//             "get",
//             "list",
//             "update"
//           ],
//           "secrets": [
//             "all"
//           ]
//         },
//         "tenantId": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx"
//       }
//     }
//   }
// }
@description('Enables Operations Network Artifacts Resource Group with KV and Storage account for the ops subscriptions used in the deployment.')
param parNetworkArtifacts object

//DDOS PARAMETERS

@description('Enables DDOS deployment on the Hub Network.')
param parDdosStandard object

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

@description('The current date - do not override the default value')
param dateUtcNow string = utcNow('yyyy-MM-dd HH:mm:ss')

// FIREWALL PARAMETERS

@description('Switch which allows Azure Firewall deployment to be disabled. Default: true')
param parAzureFirewall object

// LOGGING PARAMETERS
// Logging
// Example (JSON)
// -----------------------------
// "parLogging": {
//   "value": {
//     "enableSentinel": "true",     When set to "true", enables Microsoft Sentinel within the Log Analytics Workspace
//     "logAnalyticsWorkspaceCappingDailyQuotaGb": -1,     The daily quota for Log Analytics Workspace logs in Gigabytes. The default is "-1" for no quota.
//     "logAnalyticsWorkspaceRetentionInDays": 30,     The number of days to retain Log Analytics Workspace logs. The default is "30"
//     "logAnalyticsWorkspaceSkuName": "PerGB2018",     [Free/Standard/Premium/PerNode/PerGB2018/Standalone] The SKU for the Log Analytics Workspace.
//     "logStorageSkuName": "Standard_GRS"      The Storage Account SKU to use for log storage. The default is "Standard_GRS".
//   }
// }
@description('Enables logging parmeters and Microsoft Sentinel within the Log Analytics Workspace created in this deployment.')
param parLogging object

// STORAGE ACCOUNTS RBAC

// Storage Account RBAC
// Example (JSON)
// -----------------------------
// "parStorageAccountAccess": {
//   "value": {
//     "enableRoleAssignmentForStorageAccount": true,
//     "principalIds": [
//       "xxxxxx-xxxxx-xxxxx-xxxx-xxxxxxx"
//     ],
//     "roleDefinitionIdOrName": "Group"
//   }
// },  
@description('Account for access to Storage')
param parStorageAccountAccess object

// MICROSOFT DEFENDER PARAMETERS

// Microsoft Defender for Cloud
// Example (JSON)
// -----------------------------
// "parSecurityCenter": {
//   "value": {
//       "enableDefender: true,
//       "emailSecurityContact": "anoa@microsoft.com",
//       "phoneSecurityContact": "5555555555"
//   }
// }
@description('Microsoft Defender for Cloud.  It includes email and phone.')
param parSecurityCenter object

// REMOTE ACCESS PARAMETERS

// Bastion Host (Remote Access)
// Example (JSON)
// -----------------------------
// "parRemoteAccess": {
//   "value": {
//     "enable": true,
//     "enableJumpBoxes": true,
//     "bastion": {
//       "sku": "Standard",
//       "subnetAddressPrefix": "10.0.100.160/27",
//       "publicIPAddressAvailabilityZones": [],
//       "linux": {
//         "vmAdminUsername": "azureuser",
//         "enableVmPasswordAuthentication": true,
//         "vmAuthenticationType": "password",
//         "vmAdminPasswordOrKey": "Rem0te@2020246",
//         "vmSize": "Standard_B2s",
//         "vmOsDiskCreateOption": "FromImage",
//         "vmOsDiskType": "Standard_LRS",
//         "vmImagePublisher": "Canonical",
//         "vmImageOffer": "UbuntuServer",
//         "vmImageSku": "18.04-LTS",
//         "vmImageVersion": "latest",
//         "networkInterfacePrivateIPAddressAllocationMethod": "Dynamic"
//       },
//       "windows": {
//         "vmAdminUsername": "azureuser",
//         "VmAdminPassword": "Rem0te@2020246",
//         "vmSize": "Standard_DS1_v2",
//         "vmOsDiskCreateOption": "FromImage",
//         "VmStorageAccountType": "StandardSSD_LRS",
//         "vmImagePublisher": "MicrosoftWindowsServer",
//         "vmImageOffer": "WindowsServer",
//         "vmImageSku": "2019-datacenter",
//         "vmImageVersion": "latest",
//         "networkInterfacePrivateIPAddressAllocationMethod": "Dynamic"
//       }
//     }
//   }
// }
@description('When set to "true", provisions Azure Bastion Host. It defaults to "false".')
param parRemoteAccess object

// MANAGEMENT GROUPS PARAMETERS

// Management Groups
// Example (JSON)
// -----------------------------
// "parManagementGroups": {
//   "value": [
//     {
//       "name": "anoa",
//       "displayName": "ANOA",
//       "parentMGName": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx"
//     },
//     {
//       "name": "anoa-lzs",
//       "displayName": "anoa-lzs",
//       "parentMGName": "anoa"
//     },
//     {
//       "name": "anoa-lzs-sandbox",
//       "displayName": "anoa-lzs-sandbox",
//       "parentMGName": "anoa-lzs"
//     },
//     {
//       "name": "anoa-lzs-workloads",
//       "displayName": "anoa-lzs-workloads",
//       "parentMGName": "anoa-lzs"
//     },
//     {
//       "name": "anoa-lzs-internal",
//       "displayName": "anoa-lzs-internal",
//       "parentMGName": "anoa-lzs-workloads"
//     },
//     {
//       "name": "anoa-lzs-internal-dev",
//       "displayName": "anoa-lzs-internal-nonprod",
//       "parentMGName": "anoa-lzs-internal"
//     },
//     {
//       "name": "anoa-lzs-internal-prod",
//       "displayName": "anoa-lzs-internal-prod",
//       "parentMGName": "anoa-lzs-internal"
//     },
//     {
//       "name": "anoa-platform",
//       "displayName": "anoa-platform",
//       "parentMGName": "anoa"
//     },
//     {
//       "name": "anoa-transport",
//       "displayName": "anoa-transport",
//       "parentMGName": "anoa-platform"
//     },
//     {
//       "name": "anoa-management",
//       "displayName": "anoa-management",
//       "parentMGName": "anoa-platform"
//     },
//     {
//       "name": "anoa-identity",
//       "displayName": "anoa-identity",
//       "parentMGName": "anoa-platform"
//     }
//   ]
// },
// "parSubscriptions": {
//   "value": [
//     {
//       "subscriptionId": "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxx",
//       "managementGroupName": "anoa-management"
//     }
//   ]
// }
@description('These are the landing zone management groups.')
param parManagementGroups object

// POLICY PARAMETERS

// Policy
// Example (JSON)
// -----------------------------
// "parPolicy": {
//   "value": {
//       "bulitInPolicy": {
//           "policies": [
//               {
//                   "enabled": false,
//                   "name": "Location",
//                   "policyAssignmentManagementGroupId": "anoa",
//                   "enforcementMode": "Default",
//                   "allowedLocations": [
//                       "EastUS"
//                   ]
//               },
//               {
//                   "enabled": false,
//                   "name": "NIST SP 800-53 R5",
//                   "policyAssignmentManagementGroupId": "anoa",
//                   "enforcementMode": "Default",
//                   "requiredRetentionDays": "30"
//               },
//               {
//                   "enabled": false,
//                   "name": "FedRAMP Moderate",
//                   "policyAssignmentManagementGroupId": "anoa",
//                   "enforcementMode": "Default",
//                   "requiredRetentionDays": "30"
//               }
//           ]
//       },
//       "customPolicy": {
//           "value": {
//               "policies": [
//                   {
//                       "enabled": true,
//                       "name": "Custom - Compute Governance Initiative",
//                       "policyDefinitionManagementGroupId": "anoa",
//                       "policyAssignmentManagementGroupId": "anoa",
//                       "policySource": "ANOA",
//                       "policyCategory": "Compute"
//                   },
//                   {
//                       "enabled": true,
//                       "name": "Custom - Data Protection Governance Initiative",
//                       "policyDefinitionManagementGroupId": "anoa",
//                       "policySource": "ANOA",
//                       "policyCategory": "Data Protection"
//                   },
//                   {
//                       "enabled": true,
//                       "name": "Custom - Identity Governance Initiative",
//                       "policyDefinitionManagementGroupId": "anoa",
//                       "policySource": "ANOA",
//                       "policyCategory": "IAM"
//                   },
//                   {
//                       "enabled": true,
//                       "name": "Custom - Key Vault Governance Initiative",
//                       "policyDefinitionManagementGroupId": "anoa",
//                       "policySource": "ANOA",
//                       "policyCategory": "Key Vault"
//                   },
//                   {
//                       "enabled": true,
//                       "name": "Custom - Network Governance Initiative",
//                       "policyDefinitionManagementGroupId": "anoa",
//                       "policySource": "ANOA",
//                       "policyCategory": "Network"
//                   },
//                   {
//                       "enabled": true,
//                       "name": "Custom - Security Governance Initiative",
//                       "policyDefinitionManagementGroupId": "anoa",
//                       "policySource": "ANOA",
//                       "policyCategory": "Security"
//                   },
//                   {
//                       "enabled": true,
//                       "name": "Custom - SQL Governance Initiative",
//                       "policyDefinitionManagementGroupId": "anoa",
//                       "policySource": "ANOA",
//                       "policyCategory": "SQL"
//                   },
//                   {
//                       "enabled": true,
//                       "name": "Custom - Storage Governance Initiative",
//                       "policyDefinitionManagementGroupId": "anoa",
//                       "policySource": "ANOA",
//                       "policyCategory": "Storage"
//                   },
//                   {
//                       "enabled": true,
//                       "name": "Custom - Tagging Governance Initiative",
//                       "policyDefinitionManagementGroupId": "anoa",
//                       "policySource": "ANOA",
//                       "policyCategory": "Tagging"
//                   }
//               ]
//           }
//       }
//   }
// }        
@description('These are BulitIn/Custom Policies for the landing zone management groups and resources.')
param parPolicy object

// ROLES PARAMETERS

// Bastion Host (Remote Access)
// Example (JSON)
// -----------------------------
// {
//   "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
//   "contentVersion": "1.0.0.0",
//   "parameters": { 
//     "parRoleDefinitionInfo": {
//       "value": {
//         "definitions": [
//           {
//             "roleID": "6f0b9662-992a-523e-a58d-6a91804f2f29",
//             "roleName": "Custom - VM Operator",
//             "roleDescription": "Start and Stop Virtual Machines and reader",
//             "actions": [
//               "Microsoft.Compute/virtualMachines/read",
//               "Microsoft.Compute/virtualMachines/start/action",
//               "Microsoft.Compute/virtualMachines/restart/action",
//               "Microsoft.Resources/subscriptions/resourceGroups/read",
//               "Microsoft.Compute/virtualMachines/deallocate/action",
//               "Microsoft.Compute/virtualMachineScaleSets/deallocate/action",
//               "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/deallocate/action",
//               "Microsoft.Compute/virtualMachines/powerOff/action"
//             ],
//             "notActions": [],
//             "dataActions": [],
//             "notDataActions": [],
//             "scopeType": "ManagementGroup",
//             "scopeName": "anoalz"
//           },
//           {
//             "roleID": "72dd118f-5398-5835-8432-ced9ab12a3de",
//             "roleName": "Custom - Network Operations (NetOps)",
//             "roleDescription": "Platform-wide global connectivity management: virtual networks, UDRs, NSGs, NVAs, VPN, Azure ExpressRoute, and others.",
//             "actions": [
//               "Microsoft.Network/virtualNetworks/read",
//               "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
//               "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write",
//               "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete",
//               "Microsoft.Network/virtualNetworks/peer/action",
//               "Microsoft.Resources/deployments/operationStatuses/read",
//               "Microsoft.Resources/deployments/write",
//               "Microsoft.Resources/deployments/read"
//             ],
//             "notActions": [],
//             "dataActions": [],
//             "notDataActions": [],
//             "scopeType": "ManagementGroup",
//             "scopeName": "anoalz"
//           },
//           {
//             "roleID": "72dd118f-5398-5835-8432-ced9ab12a3de",
//             "roleName": "Custom - Security Operations (SecOps)",
//             "roleDescription": "Security Administrator role with a horizontal view across the entire Azure estate and the Azure Key Vault purge policy.",
//             "actions": [
//               "*/read",
//               "*/register/action",
//               "Microsoft.KeyVault/locations/deletedVaults/purge/action",
//               "Microsoft.PolicyInsights/*",
//               "Microsoft.Authorization/policyAssignments/*",
//               "Microsoft.Authorization/policyDefinitions/*",
//               "Microsoft.Authorization/policyExemptions/*",
//               "Microsoft.Authorization/policySetDefinitions/*",
//               "Microsoft.Insights/alertRules/*",
//               "Microsoft.Resources/deployments/*",
//               "Microsoft.Security/*",
//               "Microsoft.Support/*"
//             ],
//             "notActions": [],
//             "dataActions": [],
//             "notDataActions": [],
//             "scopeType": "ManagementGroup",
//             "scopeName": "anoalz"
//           },
//           {
//             "roleID": "72dd118f-5398-5835-8432-ced9ab12a3de",
//             "roleName": "Custom - Landing Zone Application Owner",
//             "roleDescription": "Contributor role granted for application/operations team at resource group level.",
//             "actions": [
//               "*"
//             ],
//             "notActions": [
//               "Microsoft.Authorization/*/write",
//               "Microsoft.Network/publicIPAddresses/write",
//               "Microsoft.Network/virtualNetworks/write",
//               "Microsoft.KeyVault/locations/deletedVaults/purge/action"
//             ],
//             "dataActions": [],
//             "notDataActions": [],
//             "scopeType": "ManagementGroup",
//             "scopeName": "anoalz"
//           },
//           {
//             "roleID": "72dd118f-5398-5835-8432-ced9ab12a3de",
//             "roleName": "Custom - Landing Zone Subscription Owner",
//             "roleDescription": "Delegated role for subscription owner generated from subscription Owner role.",
//             "actions": [
//               "*"
//             ],
//             "notActions": [
//               "Microsoft.Authorization/*/write",
//               "Microsoft.Network/vpnGateways/*",
//               "Microsoft.Network/expressRouteCircuits/*",
//               "Microsoft.Network/routeTables/write",
//               "Microsoft.Network/vpnSites/*"
//             ],
//             "dataActions": [],
//             "notDataActions": [],
//             "scopeType": "ManagementGroup",
//             "scopeName": "anoalz"
//           },
//           {
//             "roleID": "bb465e79-5df0-597b-a848-85006554c065",
//             "roleName": "Custom - Storage Operator",
//             "roleDescription": "Custom Storage Operator role for deploying virtual machines.",
//             "actions": [
//               "Microsoft.Authorization/*/read",
//               "Microsoft.Insights/alertRules/*",
//               "Microsoft.Insights/diagnosticSettings/*",
//               "Microsoft.Network/virtualNetworks/subnets/joinViaServiceEndpoint/action",
//               "Microsoft.ResourceHealth/availabilityStatuses/read",
//               "Microsoft.Resources/deployments/*",
//               "Microsoft.Resources/subscriptions/resourceGroups/read",
//               "Microsoft.Storage/storageAccounts/*",
//               "Microsoft.Support/*",
//               "Microsoft.Storage/storageAccounts/listkeys/action"
//             ],
//             "notActions": [],
//             "scopeType": "ManagementGroup",
//             "scopeName": "anoalz"
//           }
//         ]
//       }
//     }
//   }
// }
@description('These are the custom roles for landing zone management groups and resources..')
param parRoleDefinitionInfo object


// Module - TAGS
// -----------------------------

var referential = {
  region: parLocation
  deploymentDate: dateUtcNow
}

@description('Resource group tags')
module modTags '../../azresources/Modules/Microsoft.Resources/tags/az.resources.tags.bicep' = {
  name: 'deploy-hubspoke-tags--${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHub.subscriptionId)
  params: {
    tags: union(parTags, referential)
  }
}

// Module - Customer Usage Attribution - Telemetry
// -----------------------------------------------

// Module - Management Groups
// -----------------------------
// The Enclave Management Groups module deploys a management group hierarchy in a tenant under the Tenant Root Group. 
// This is accomplished through a tenant-scoped Azure Resource Manager (ARM) deployment. 
// NOTE: For more information on Management Groups - go to the overlays/management-group/readme.md
// -------------------------------------------------------------------------------------------------------------------
module modManagementGroups '../../overlays/management-groups/deploy.bicep' = {
  name: 'deploy-MG-${parLocation}-${parDeploymentNameSuffix}'
  scope: managementGroup(parManagementGroups.tenantId)
  params: {
    parManagementGroups: parManagementGroups.groups
    parRequireAuthorizationForGroupCreation: parManagementGroups.requireAuthorizationForGroupCreation
    parRootMg: parManagementGroups.rootMg
    parSubscriptions: parManagementGroups.subscriptions
    parTenantId: parManagementGroups.tenantId
  }
}

// Module - Custom RBAC Role Definitions 
// --------------------------------------
// The Enclave Roles overlay module deploys a role definitions in a specific `Management Group`.  
// This is accomplished through a managmenent-group-scoped Azure Resource Manager (ARM) deployment.
// --------------------------------------
module modRoles '../../overlays/roles/deploy.bicep' = {
  name: 'deploy-Roles-${parLocation}-${parDeploymentNameSuffix}'
  scope: managementGroup(parManagementGroups.tenantId)
  params:  {
    parLocation: parLocation
    parDefaultManagementGroupIdForRoleDefinitions: ''
    parRoleDefinitionInfo: parRoleDefinitionInfo
  }
}

// Bulit-In/Custom Policy Definitions and Initiatives Into Management Group Hierarchy
// Module - Policy Definitions and Initiatives
// -----------------------------------------------------------------------------------
//
//
//
// -----------------------------------------------------------------------------------
module modPolicy '../../overlays/policy/hub-spoke/deploy.bicep' = {
  name: 'deploy-Policy-${parLocation}-${parDeploymentNameSuffix}'
  scope: managementGroup(parManagementGroups.tenantId)
  params: {
    parLocation: parLocation
    parPolicy: parPolicy
  }
}

// Module - Hub/ 1 Spoke Design - SCCA Compliant
// ----------------------------------------------
//
// ----------------------------------------------
module modHubSpoke '../../platforms/lz-platform-scca-hub-1spoke/deploy.bicep' = {
  name: 'deploy-HubSpoke-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHub.subscriptionId)
  params: {
    // Required Parameters
    parRequired: parRequired
    parLocation: parLocation
    parTags: modTags.outputs.tags

    // Subscriptions
    parHubSubscriptionId: parHub.subscriptionId
    parOperationsSubscriptionId: parOperationsSpoke.subscriptionId
    
    // Artifact Key Vault Parameters
    parNetworkArtifacts: parNetworkArtifacts.artifactsKeyVault.keyVaultPolicies

    // Enable DDOS Protection Plan
    parDdosStandard: parDdosStandard

    // Hub Network Parameters
    parHubVirtualNetworkAddressPrefix: parHub.virtualNetworkAddressPrefix
    parHubSubnetAddressPrefix: parHub.subnetAddressPrefix
    parHubNetworkSecurityGroupDiagnosticsLogs: parHub.networkSecurityGroupDiagnosticsLogs
    parHubNetworkSecurityGroupRules: parHub.networkSecurityGroupRules
    parHubSubnetServiceEndpoints: parHub.subnetServiceEndpoints
    parHubVirtualNetworkDiagnosticsLogs: parHub.virtualNetworkDiagnosticsLogs
    parHubVirtualNetworkDiagnosticsMetrics: parHub.virtualNetworkDiagnosticsMetrics
    
    

    // Operations Network Parameters
    parOperationsNetworkSecurityGroupDiagnosticsLogs: parOperationsSpoke.networkSecurityGroupDiagnosticsLogs
    parOperationsSubnetAddressPrefix: parOperationsSpoke.subnetAddressPrefix
    parOperationsNetworkSecurityGroupRules: parOperationsSpoke.networkSecurityGroupRules
    parOperationsSubnetServiceEndpoints: parOperationsSpoke.subnetServiceEndpoints
    parOperationsVirtualNetworkAddressPrefix: parOperationsSpoke.virtualNetworkAddressPrefix
    parOperationsVirtualNetworkDiagnosticsLogs: parOperationsSpoke.virtualNetworkDiagnosticsLogs
    parOperationsVirtualNetworkDiagnosticsMetrics: parOperationsSpoke.virtualNetworkDiagnosticsMetrics
    parOperationsSourceAddressPrefixes: parOperationsSpoke.sourceAddressPrefixes

    // Logging/Sentinel
    parLogging: parLogging
    

    // Enable Azure FireWall
    parAzureFirewallEnabled: parAzureFirewall.enable
    parFirewallClientSubnetAddressPrefix: parAzureFirewall.clientSubnetAddressPrefix
    parFirewallManagementSubnetAddressPrefix: parAzureFirewall.managementSubnetAddressPrefix

    // Hub Firewall Parameters
    parFirewallSupernetIPAddress: parAzureFirewall.supernetIPAddress
    parFirewallSkuTier: parAzureFirewall.skuTier
    parFirewallThreatIntelMode: parAzureFirewall.threatIntelMode
    parFirewallIntrusionDetectionMode: parAzureFirewall.intrusionDetectionMode
    parFirewallClientPublicIPAddressAvailabilityZones: parAzureFirewall.clientPublicIPAddressAvailabilityZones
    parFirewallClientSubnetName: parAzureFirewall.clientSubnetName
    parFirewallClientSubnetServiceEndpoints: parAzureFirewall.clientSubnetServiceEndpoints
    parFirewallDiagnosticsLogs: parAzureFirewall.diagnosticsLogs
    parFirewallDiagnosticsMetrics: parAzureFirewall.diagnosticsMetrics
    parFirewallManagementPublicIPAddressAvailabilityZones: parAzureFirewall.managementPublicIPAddressAvailabilityZones
    parFirewallManagementSubnetName: parAzureFirewall.managementSubnetName
    parFirewallManagementSubnetServiceEndpoints: parAzureFirewall.managementSubnetServiceEndpoints
    parPublicIPAddressDiagnosticsLogs: parAzureFirewall.publicIPAddressDiagnosticsLogs
    parPublicIPAddressDiagnosticsMetrics: parAzureFirewall.publicIPAddressDiagnosticsMetrics
    parApplicationRuleCollections: []
    parNetworkRuleCollections: []

    // RBAC for Storage Parameters
    parStorageAccountAccess: parStorageAccountAccess

    //
    parSecurityCenter: parSecurityCenter

    //
    parRemoteAccess: parRemoteAccess
  }
}

// Module - AKS Workload
// ----------------------------------------------
//
// ----------------------------------------------
module modAKSWorkload '../../workloads/wl-aks-spoke/deploy.bicep' = {
  name: 'deploy-HubSpoke-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(parHub.subscriptionId)
  params: {
    parLocation: parLocation
    parHubVirtualNetworkResourceId: modHubSpoke.outputs.hub.virtualNetworkResourceId
    parTags: modTags.outputs.tags
    parLogAnalyticsWorkspaceName: modHubSpoke.outputs.logAnalyticsWorkspaceName
    parContainerRegistry: {
    }
    parKubernetesCluster: {
    }
    parHubResourceGroupName: modHubSpoke.outputs.hub.resourceGroupName
    parHubVirtualNetworkName: modHubSpoke.outputs.hub.virtualNetworkName
    parRequired: parRequired
    parFirewallPrivateIPAddress: modHubSpoke.outputs.firewallPrivateIPAddress
    parLogAnalyticsWorkspaceResourceId: modHubSpoke.outputs.logAnalyticsWorkspaceResourceId
    parHubSubscriptionId: parHub.subscriptionId
  }  
}
