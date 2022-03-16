# terraform_templates

This repository consist of different Terraform modules for provisioning and deploying production grade services in AWS.


Basic command to run when implementing Terraform:

- Main commands:
  - init          Prepare your working directory for other commands
  - validate      Check whether the configuration is valid
  - plan          Show changes required by the current configuration
  - apply         Create or update infrastructure
  - destroy       Destroy previously-created infrastructure

- All other commands:
  - console       Try Terraform expressions at an interactive command prompt
  - fmt           Reformat your configuration in the standard style
  - force-unlock  Release a stuck lock on the current workspace
  - get           Install or upgrade remote Terraform modules
  - graph         Generate a Graphviz graph of the steps in an operation
  - import        Associate existing infrastructure with a Terraform resource
  - login         Obtain and save credentials for a remote host
  - logout        Remove locally-stored credentials for a remote host
  - output        Show output values from your root module
  - providers     Show the providers required for this configuration
  - refresh       Update the state to match remote systems
  - show          Show the current state or a saved plan
  - state         Advanced state management
  - taint         Mark a resource instance as not fully functional
  - test          Experimental support for module integration testing
  - untaint       Remove the 'tainted' state from a resource instance
  - version       Show the current Terraform version
  - workspace     Workspace management
  
  Examples:
  - terraform init 
  - terraform plan -var-file=dev.tfvars 
  - terraform apply -var-file=dev.tfvars 
  - terraform refresh -var-file=dev.tfvars
  - terraform destroy -var-file=dev.tfvars
  
