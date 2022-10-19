# Overlays:   NoOps Accelerator - Auotmation Account

## Overview

This overlay module deploys an Platform Landing Zone compatible Azure Automation account, with diagnostic logs pointed to the Platform Landing Zone Log Analytics Workspace (LAWS) instance.

## About Azure Auotmation Account

The docs on Azure Bastion: <https://docs.microsoft.com/en-us/azure/bastion/bastion-overview>

Some particulars about Bastion:

* Azure Bastion Host requires a subnet of /27 or larger
* The subnet must be titled AzureBastionSubnet
* Azure Bastion Hosts require a public IP address

## Deploy Virtual Machine

This add-on module also deploys two virtual machines into a new subnet in the existing Hub virtual network to serve as jumpboxes.

The docs on Virtual Machines: <https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachines?tabs=json>

## Pre-requisites

* A Mission LZ deployment (a deployment of anoa.mlz.bicep)

See below for information on how to use the appropriate deployment parameters for use with this overlay:

Deployment Output Name | Description
-----------------------| -----------
parHubResourceGroupName | The resource group that contains the Hub Virtual Network and deploy the virtual machines into
parHubVirtualNetworkName | The resource to deploy a subnet configured for Bastion Host
parHubSubnetResourceId | The resource ID of the subnet in the Hub Virtual Network for hosting virtual machines
parHubNetworkSecurityGroupResourceId | The resource ID of the Network Security Group in the Hub Virtual Network that hosts rules for Hub Subnet traffic

## Deploy the Service

Once you have the Mission LZ output values, you can pass those in as parameters to this deployment.

For example, deploying using the `az deployment group create` command in the Azure CLI:

```bash

```
