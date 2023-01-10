# Azure NoOps Accelerator Archive

## /BICEP

The BICEP version of the Azure NoOps Accelerator was the initial language implementation of the framework.
While in development, we found a large number of customers that had trained their people on Terraform.
This led us to the decision to try implementing a Terraform version.
The conversion to Terraform was successful, but our refactoring efforts guided us to a different folder structure than initially implemented in the BICEP code.

Refactoring the BICEP code to match the new structure is possible, but it is a non-trivial undertaking.
To quickly move the Terraform version to wider use, we have decided to move the ```BICEP``` code to an ```Archive``` folder until we have the time to refactor it to match the new design.  

> NOTE: The BICEP code here is in a working state, it simply doesn't conform to the updated folder structure or project strategy.  Please feel free to pull from it for your own purposes.
