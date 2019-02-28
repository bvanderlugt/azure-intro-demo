# Azure Short Intro Demonstration For Tieto Specialists  <!-- omit in toc -->


# Table of Contents  <!-- omit in toc -->
- [Introduction](#introduction)
- [Azure Solution](#azure-solution)
- [Terraform Code](#terraform-code)
- [Terraform File Types](#terraform-file-types)
- [Terraform Env and Modules](#terraform-env-and-modules)
  - [Env Parameters](#env-parameters)
  - [Env-def Module](#env-def-module)
  - [Resource-group Module](#resource-group-module)
  - [Vnet Module](#vnet-module)
  - [Vm Module](#vm-module)
- [Azure Tags](#azure-tags)
- [Terraform Backend](#terraform-backend)
- [Demonstration Manuscript](#demonstration-manuscript)
- [Demonstration Manuscript for Windows Users](#demonstration-manuscript-for-windows-users)
- [Suggestions How to Continue this Demonstration](#suggestions-how-to-continue-this-demonstration)




# Introduction

This demonstration can be used in training new cloud specialists who don't need to have any prior knowledge of Azure but who want to start working on Azure projects and building their Azure competence.

This project demonstrates basic aspects how to create cloud infrastructure using code. The actual infra is very simple: just one virtual machine (VM). We create a virtual network ([vnet](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) and an application subnet into which we create the [VM](https://azure.microsoft.com/en-us/services/virtual-machines/). There is also one [security group](https://docs.microsoft.com/en-us/azure/virtual-network/security-overview) in the application subnet that allows inbound traffic only using ssh port 22. The infra creates private/public keys and installs the public key to the VM - you get the private key for connecting to the VM once you have deployed the infra.

I tried to keep this demonstration as simple as possible. The main purpose is not to provide an example how to create a cloud system (e.g. not recommending VMs over containers) but to provide a very simple example of infrastructure code and tooling related creating the infra. I have provided some suggestions how to continue this demonstration at the end of this document - you can also send me email to my corporate email and suggest what kind of Azure or AWS POCs you need in your AS team - I can help you to create the POCs for your customer meetings.

NOTE: There is an equivalent AWS demonstration - [aws-intro-demo](https://github.com/tieto-pc/aws-intro-demo) - compare the terraform code between these AWS and Azure infra implementations and you realize how similar they are.


# Azure Solution

The diagram below depicts the main services / components of the solution.

![Azure Intro Demo Architecture](docs/azure-intro-demo.png?raw=true "Azure Intro Demo Architecture")

So, the system is extremely simple (for demonstration purposes): Just one application subnet and one VM doing nothing in the subnet. Subnet security group which allows only ssh traffic to the VM. 


# Terraform Code

I am using [Terraform](https://www.terraform.io/) as an [infrastructure as code](https://en.wikipedia.org/wiki/Infrastructure_as_code) (IaC) tool. Terraform is very much used both in the AWS and Azure sides and one of its strenghts compared to cloud native tools (AWS / [CloudFormation](https://aws.amazon.com/cloudformation) and Azure / [ARM template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates)) is that you can use Terraform with many cloud providers, you have to learn just one infra language and syntax, and Terraform language (hcl) is pretty powerful and clear. When deciding the actual infra code tool you should consult the customer if there is some tooling already decided. Otherwise you should evaluate ARM template and Terraform and then decide which one is more appropriate for the needs of your Azure cloud project.

If you are new to infrastructure as code (IaC) and terraform specifically let's explain the high level structure of the terraform code first. Project's terraform code is hosted in [terraform](terraform) folder.

It is a cloud best practice that you should modularize your infra code and also modularize it so that you can create many different (exact or as exact as you like) copies of your infra  re-using the infra modules. I use a common practice to organize terraform code in three levels:

1. **Environment parameters**. In [envs](terraform/envs) folder we host the various environments. In this demo we have only the dev environment, but this folder could have similar env parameterizations for qa, perf, prod environments etc. 
2. **Environment definition**. In [env-def](terraform/modules/env-def) folder we define the modules that will be used in every environment. The environments inject the environment specific parameters to the env-def module which then creates the actual infra using those parameters by calling various infra modules and forwarding environment parameters to the infra modules.
3. **Modules**. In [modules](terraform/modules) folder we have the modules that are used by environment definition (env-def, a terraform module itself also). There are modules for the main services used in this demonstration: [vnet](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) and [vm](https://azure.microsoft.com/en-us/services/virtual-machines/), and [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview#resource-groups) which gathers the infra resources into one view.

# Terraform File Types

There are basically three types of Terraform files in this demonstration:
- The actual infra definition file with the same name as the module folder.
- Variables file. You use variables file to declare variables that are used in that specific module.
- Outputs file. You can use outputs file as a mechanism to print certain interesting infra values. Outputs are also a mechanism to transfer infra information from one module to another.

I encourage the reader to read more about Terraform in [Terraform documentation](https://www.terraform.io/docs/index.html).

# Terraform Env and Modules

In this chapter we walk through the terraform modules a bit deeper.

## Env Parameters

You can find all parameters related to dev env in file [dev.tf](terraform/envs/dev/dev.tf). Open the file.

This file starts with the provider definition (azure apparently in the case of this Azure demonstration). Then there is the terraform backend configuration. More about it later but let's remind you right away that if you want to deploy this demo to your Azure subscription you have to change the ```storage_account_name```, and the name must be unique in all Azure - so try to figure out some unique name like ```jesse-demo``` etc. (**NOTE**: In Azure side you should keep the prefix rather short since I noticed that there are some restrictions in certain Azure resource names - if you have a long prefix and add the Env and resource name to it you may exceed e.g. some 15 character limit in VM names).

After that we have the terraform locals definition - these are provided for this context and we use them to inject the parameter values to the env-def module which follows right after the locals definition.


## Env-def Module

All right! In the previous file we injected dev env parameters to the [env-def.tf](terraform/modules/env-def/env-def.tf) module. Open this file now.

You see that this module defines three other modules. The idea is that this env-def - Environment definition - can be re-used by all envs, like ```dev```, ```qa```, ```perf``` and ```prod``` etc - they all just inject their env specific parameters to the same environment definition which gives a more detailed definition what kind of modules there are in this infrastructure.

So, this environment defition defines three modules: a resource group, virtual network (vnet) and a virtual machine (vm). Let's walk through those modules next.


## Resource-group Module

The [resource-group](terraform/modules/resource-group) module just defines the main resource group that we are using with all resources in this infra. The resource groups are used in the Azure cloud used for providing a view to a set of resources and it is also easy manually to destroy a set of resources just by deleting the resource group.

## Vnet Module

The [vnet](terraform/modules/vnet) module is a bit longer. First it defines a virtual network (vnet). We inject a [cidr address space](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) for the virtual network. All our resources will be using this address space. Then we define a subnet for making the security group rules easier. 

After the vnet and subnet we have a security group definition, and then we associate this sg to the subnet. After that we finally have the only rule in this sg - the only inbound traffic that we allow is ssh (port 22).

## Vm Module

The [vm](terraform/modules/vm) module is a also a bit more complex. But let's not be intimidated - I took most of the code from a [Microsoft documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-create-complete-vm). As you can see, you can find infra code examples quite easily in the net - you don't have to invent the wheel again when creating most of the infra code.

So, in the vm module we first create the ssh keys. I later realized that there is some bash inline scripting here - most possibly won't be working if you run terraform in a Windows box (I must test this myself and make this part a bit simpler e.g. injecting the ssh public key manually here). 

After that we define a public ip (pip) and a virtual network interface card (nic) for the VM. This is mostly just some infra boilerplate - don't worry about it. After those entities we finally define the actual VM. Read the infra definition for the VM in more detail if you are interested - should be quite easy to read since terraform is declarative language (tells what to do, not an imperative specific instructions how to do it).

# Azure Tags

In all main resources (that support tagging) I have added some tags. 

- Name: "intro-demo-dev-vnet" - this is the name of the resource.
- Env: "dev" - this is the env (e.g. dev, qa, perf, prod...)
- Environment: "intro-demo-dev" - this is the specific environment for a specific infra, i.e. we are running dev for intro-demo (I realized now that in future demos I might change this tag to "Deployment" not to mix Environment and Env tags).
- Prefix: "intro-demo" - this is the infra without the env postfix. 
- Location: "westeurope" - Azure location.
Terraform: "true" (fixed)


If you figure out some consistent tagging system it is easier for you to find resources using tags. Examples:

- Env = "dev" => All resources in all projects which have deployed as "dev".
- Prefix = "intro-demo" => All intro-demos resources in all envs (dev, perf, qa, prod...)
- Environment = "intro-demo-dev" => The resources of a specific terraform deployment (since each demo has dedicated deployments for all envs)


# Terraform Backend

In a small project like this in which you are working alone you don't actually need a Terraform backend but I have used it in this demonstration to make a more realistic demonstration. You should use Terraform backend in any project that has more than one developer. The reason for using a Terraform backend is to store and lock your terraform state file so that many developers cannot concurrently make conflicting changes to the infrastructure.

I have provided a bash script to create the Azure Storage account and Blob container for the terraform state file: [create-azure-storage-account.sh](scripts/create-azure-storage-account.sh).

After the script has run it prints three important values:
- storage_account_name: You have to add this value to your [dev.tf](terraform/envs/dev/dev.tf) file into the terraform backend section as the storage_account_name value.
- container_name: You have to add this value to your [dev.tf](terraform/envs/dev/dev.tf) file into the terraform backend section as the container_name value.
- access_key: You have to create an environment script which defines  ARM_ACCESS_KEY environment variable - set the value you got as the value of this environment variable. When ever you run terraform commands this environment variable must be defined with the account key value (storage account key) - this way terraform can connect to your terraform backend file which is stored in the Azure [Storage account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview)

So, in a linux box export:

```bash
export ARM_ACCESS_KEY="YOUR-AZURE-STORAGE-ACCESS-KEY"
```

And in a windows box the same (but do not use quotes):

```dos
set ARM_ACCESS_KEY=YOUR-AZURE-STORAGE-ACCESS-KEY
```


# Demonstration Manuscript

NOTE: These instructions are for Linux (most probably should work for Mac as well). Windows instructions are in the next chapter.

Let's finally give detailed demonstration manuscript how you are able to deploy the infra of this demonstration to your Azure subscription. You need an Azure subscription for this demonstration. You can order a private Azure subscription or you can contact your line manager if there is an Azure development subscription in your unit that you can use for self-study purposes to learn how to use Azure. **NOTE**: Watch for costs! Always finally destroy your infrastructure once you are ready (never leave any resources to run indefinitely in your subscription to generate costs).

1. Install [Terraform](https://www.terraform.io/). You might also like to add Terraform support for your favorite editor (e.g. there is a Terraform extension for VS Code).
2. Install [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
3. Clone this project: git clone https://github.com/tieto-pc/azure-intro-demo.git
4. Login to Azure:
   1. ```az login```.
   2. ```az account list --output table``` => Check which Azure accounts you have.
   3. ```az account set -s YOUR-ACCOUNT-ID``` => Set the right azure account. **NOTE**: This is important! Always check which Azure account is your default account so that your demos do not accidentally go to some customer Azure production environment!
5. Configure the terraform backend. Use script [create-azure-storage-account.sh](scripts/create-azure-storage-account.sh) to create a Terraform backend for your project. See more detailed instructions how to configure the backend in Terraform code and how to set the environment variable in chapter "Terraform Backend"
6. Open console in [dev](terraform/envs/dev) folder. Give commands
   1. ```terraform init``` => Initializes the Terraform backend state.
   2. ```terraform get``` => Gets the terraform modules of this project.
   3. ```terraform plan``` => Gives the plan regarding the changes needed to make to your infra. **NOTE**: always read the plan carefully!
   4. ```terraform apply``` => Creates the delta between the current state in the infrastructure and your new state definition in the Terraform configuration files.
7. Open Azure Portal and browse different views to see what entities were created:
   1. Find the resource group.
   2. Click the vnet. Browse subnets etc.
   3. Click pip => see the public ip of the VM.
   4. Click vm => Browse different information regarding the VM, e.g. Networking: here you find the firewall definition for ssh we created earlier.
8. Test to get ssh connection to the VM:
   1. terraform output -module=env-def.vm => You get the public ip of the VM. (If you didn't get an ip, run terraform apply again - terraform didn't get the ip to state file in the first round.)
   2. Open another terminal in project root folder.
   3. ssh -i terraform/modules/vm/.ssh/vm_id_rsa ubuntu@IP-NUMBER-HERE
9. Finally destroy the infra using ```terraform destroy``` command. Check manually also using Portal that terraform destroyed the resource group (if the resource group is gone all the resources are gone also). **NOTE**: It is utterly important that you always destroy your infrastructure when you don't need it anymore - otherwise the infra will generate costs to you or to your unit.


# Demonstration Manuscript for Windows Users

**NOTE**: Sami Huhtiniemi kindly provided the solution for this demonstration how to store the private key in [vm.tf](terraform/modules/vm/vm.tf) so that the key is stored with UTF-8 encoding and that the file permissions are set so that ssh client won't complain about unprotected key file. Thanks Sami!

**NOTE**: I appreciate if some Windows guy sends me a pull request for a dos/powershell version of this bash script: [create-azure-storage-account.sh](scripts/create-azure-storage-account.sh)!

1. Install:
   1.  [Git for Windows](https://git-scm.com/download/win)
   2.  [Terraform for Windows](https://www.terraform.io/downloads.html) + add terraform to your path.
   3.  [Azure Command Line Interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
2. Clone this project: git clone https://github.com/tieto-pc/azure-intro-demo.git
3. Login to Azure:
   1. ```az login```.
   2. ```az account list --output table``` => Check which Azure accounts you have.
   3. ```az account set -s YOUR-ACCOUNT-ID``` => Set the right azure account. **NOTE**: This is important! Always check which Azure account is your default account so that your demos do not accidentally go to some customer Azure production environment!
4. Configure the terraform backend. Use script [create-azure-storage-account-win-version.sh](scripts/create-azure-storage-account-win-version.sh) to create a Terraform backend for your project. See more detailed instructions how to configure the backend in Terraform code and how to set the environment variable in chapter "Terraform Backend".
5. Change the ssh key creation to use Windows style: [dev.tf](terraform/envs/dev/dev.tf) change the value of local variable ```my_workstation_is_linux``` from default value "1" (meaning your workstation is linux/mac) to value "0" (meaning your workstation is windows). This is a bit of a hack but needed for storing the private ssh key automatically to your workstation's local disk to make things easier in this demo (no need to create the ssh keys manually and use it in the infra code).
6. Open console in [dev](terraform/envs/dev) folder. Give commands:
   1. ```terraform init``` => Initializes the Terraform backend state.
   2. ```terraform get``` => Gets the terraform modules of this project.
   3. ```terraform plan``` => Gives the plan regarding the changes needed to make to your infra. **NOTE**: always read the plan carefully!
   4. ```terraform apply``` => Creates the delta between the current state in the infrastructure and your new state definition in the Terraform configuration files.
7. Open Azure Portal and browse different views to see what entities were created:
   1. Find the resource group.
   2. Click the vnet. Browse subnets etc.
   3. Click pip => see the public ip of the VM.
   4. Click vm => Browse different information regarding the VM, e.g. Networking: here you find the firewall definition for ssh we created earlier.
8. Test to get ssh connection to the VM:
   1. terraform output -module=env-def.vm => You get the public ip of the VM. (If you didn't get an ip, run terraform apply again - terraform didn't get the ip to state file in the first round.)
   2. Open another terminal in project root folder.
   3. ssh -i YOUR-PATH/vm_id_rsa ubuntu@IP-NUMBER-HERE 
9.  Finally destroy the infra using ```terraform destroy``` command. Check manually also using Portal that terraform destroyed the resource group (if the resource group is gone all the resources are gone also). **NOTE**: It is utterly important that you always destroy your infrastructure when you don't need it anymore - otherwise the infra will generate costs to you or to your unit.


# Suggestions How to Continue this Demonstration

We could add e.g. scale set to this demonstration but let's keep this demonstration as short as possible so that it can be used as an Azure introduction demonstration. If there are some improvement suggestions that our AS developers would like to see in this demonstration let's create other small demonstrations for those purposes, e.g.:
- Create a custom Linux image that has the Java app baked in.
- A scale set for VMs.
- Logs to Log Analytics.
- Use container instead of VM.