# NoOps Accelerator - AzResources Bicep Module Templates Folders

Module Tested on:

* Azure Commercial ✔️
* Azure Government ✔️
* Azure Government Secret ✔️
* Azure Government Top Secret ❔

> ✔️ = tested,  ❔= currently testing

## Overview

## Hub Spoke Folder

Hub/ Spoke Core is the basis on creating a modular Hub/Spoke network design. This core is used in Platform creations. Each module in the core is designed to be deploy together or individually. 

## Modules Folder

In the context of the NoOps Accelerator, a module is described as a reusable, template-based building component(block) for Azure resource deployments using infrastructure as code. Each template should be able to accommodate as many resource-specific scenarios as is practical without limiting the user by presuming anything about them. 

This folder contains select bicep modules influenced from the [CARML](https://aka.ms/CARML) library 

## Policy Folder

Modules folder houses the Common use cases for Azure Policy include implementing governance for resource consistency, regulatory compliance, security, cost, and management.
