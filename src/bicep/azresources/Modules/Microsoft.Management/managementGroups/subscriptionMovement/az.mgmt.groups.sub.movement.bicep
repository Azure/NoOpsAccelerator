/*
SUMMARY: This module moves one or more subscriptions to be a child of the specified management group. Once the subscription(s) are moved under the management group, Azure Policies assigned to the management group or its parent management group(s) will begin to govern the subscription(s).
DESCRIPTION: The following components will be options in this deployment
              Operations Virtual Network (Vnet)
              Subnets 
              Private DNS Zones - Details of all the Azure Private DNS zones can be found here --> https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration     
AUTHOR/S: jspinella

*/

/*
Copyright (c) Microsoft Corporation. Licensed under the MIT license.
*/

targetScope='tenant'

@description('Subscription Id that should be moved to the new management group.')
param parSubscriptionId string

@description('Target management group for the subscription.  This management group must exist.')
param parTargetManagementGroupId string

resource resManagementGroup 'Microsoft.Management/managementGroups@2021-04-01' existing = {
  name: parTargetManagementGroupId
}

resource resSubMovement 'Microsoft.Management/managementGroups/subscriptions@2021-04-01' = {
  parent: resManagementGroup
  name: parSubscriptionId
}


