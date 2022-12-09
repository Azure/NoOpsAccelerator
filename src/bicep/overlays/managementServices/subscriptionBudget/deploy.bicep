// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

/*
SUMMARY: Module Example to deploy the subscription budget to a specifed subscription
DESCRIPTION: The following components will be options in this deployment
              * Hub Virtual Network (VNet)
AUTHOR/S: jspinella
VERSION: 1.x.x
*/

targetScope = 'subscription' //Deploying at Subscription scope to allow resource groups to be created and resources in one deployment

// REQUIRED PARAMETERS

@description('The region to deploy resources into. It defaults to the deployment location.')
param parLocation string = deployment().location

// Subscription Budget
// Example parameter (JSON)
// ---------------------------
// "parSubscriptionBudget": {
//   "value": {
//       "TargetBudgetSubs": [
//          {
//            "subscriptionId": xxxxxx-xxxx-xxxxxxx-xxxxx-xxxxxx 
//            "createBudget": false,
//            "name": "MonthlySubscriptionBudget",
//            "amount": 1000,
//            "contactEmails": [ "joedoe@microsoft.com" ]
//          }
//       ]       
//   }
// }
@description('Subscription budget configuration containing createBudget flag, name, amount, timeGrain and array of contactEmails')
param parSubscriptionBudget object

// RESOURCE NAMING PARAMETERS

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param parDeploymentNameSuffix string = utcNow()

// SUBSCRIPTION BUDGET

module modBudget '../../../azresources/Modules/Microsoft.Consumption/budgets/az.comsumption.sub.budget.bicep' = [for sub in parSubscriptionBudget.TargetBudgetSubs: if (!empty(parSubscriptionBudget) && parSubscriptionBudget.TargetBudgetSubs.createBudget) {
  name: 'deploy-budget-${parLocation}-${parDeploymentNameSuffix}'
  scope: subscription(sub.subscriptionId)
  params: {
    name: sub.name
    amount: sub.amount
    category: 'Cost'      
    contactEmails: sub.contactEmails
  }
}]
