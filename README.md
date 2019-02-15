# Azure Short Intro Demonstration For AS Specialists  <!-- omit in toc -->


# Table of Contents  <!-- omit in toc -->
- [Introduction](#introduction)
- [Azure Solution](#azure-solution)
- [Terraform Code](#terraform-code)
- [Terraform File Types](#terraform-file-types)
- [Terraform Env and Modules](#terraform-env-and-modules)
  - [Env Parameters](#env-parameters)
  - [Env-dev Module](#env-dev-module)
  - [Resource-group Module](#resource-group-module)
  - [Vnet Module](#vnet-module)
  - [Vm Module](#vm-module)
- [Azure Tags](#azure-tags)
- [Terraform Backend](#terraform-backend)
- [Demonstration Manuscript](#demonstration-manuscript)
- [Demonstration Manuscript for Windows Users](#demonstration-manuscript-for-windows-users)
- [Suggestions to Continue this Demonstration](#suggestions-to-continue-this-demonstration)




# Introduction

This demonstration has been created for our Application Service unit's purposes to be used in training new cloud specialists who don't need to have any prior knowledge of Azure but who want to start working on Azure projects and building their Azure competence.

This project demonstrates basic aspects how to create cloud infrastructure using code. The actual infra is very simple: just one virtual machine (VM). We create a virtual network ([vnet](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) and an application subnet into which we create the [VM](https://azure.microsoft.com/en-us/services/virtual-machines/). There is also one [security group](https://docs.microsoft.com/en-us/azure/virtual-network/security-overview) in the application subnet that allows inbound traffic only using ssh port 22. The infra creates private/public keys and installs the public key to the VM - you get the private key for trying to connect to the VM once you have deployed the infra.

I tried to keep this demonstration as simple as possible. The main purpose is not to provide an example how to create a cloud system (e.g. not recommending VMs over containers) but to provide a very simple example of infrastructure code and tooling related creating the infra. I have provided some suggestions how to continue this demonstration at the end of this document - you can also send me email to my corporate email and suggest what kind of Azure or AWS POCs you need in your AS unit - I can help you to create the POCs for your customer meetings.


# Azure Solution

The diagram below depicts the main services / components of the solution.

![Azure Intro Demo Architecture](docs/azure-intro-demo.png?raw=true "Azure Intro Demo Architecture")

So, the system is extremely simple (for demonstration purposes): Just one application subnet and one VM doing nothing in the subnet. Subnet security group which allows only ssh traffic to the VM. 


# Terraform Code

I am using [Terraform](https://www.terraform.io/) as a [infrastructure as code](https://en.wikipedia.org/wiki/Infrastructure_as_code) (IaC) tool. Terraform is very much used both in AWS and Azure side and one of its strenghts compared to cloud native tools (AWS / [CloudFormation](https://aws.amazon.com/cloudformation) and Azure / [ARM template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates)) is that you can use Terraform with many cloud providers, you have to learn just one infra language and syntax, and Terraform language (hcl) is pretty powerful and clear. When deciding the actual infra code tool you should consult the customer if there is some tooling already decided. Otherwise you should evaluate ARM template and Terraform and then decided which one is more appropriate for the needs of your cloud project.

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

This file starts with the provider definition (azure apparently in the case of this Azure demonstration). Then there is the terraform backend configuration. More about it later but let's remind you right away that if you want to deploy this demo to your Azure subscription you have to change the ```storage_account_name```, and the name must be unique in all Azure - so try to figure out some unique name like ```jesse-testing-terraform-demo``` etc.

After that we have the terraform locals definition - these are provided for this context and we use them to inject the parameter values to the env-def module which follows right after the locals definition.


## Env-dev Module

All right! In the previous file we injected dev env parameters to the [env-def.tf](terraform/modules/env-def/env-def.tf) module. Open this file now.

You see that this module defines three other modules. The idea is that this env-def - Environment definition - can be re-used by all envs, like ```dev```, ```qa```, ```perf``` and ```prod``` etc - they all just inject their env specific parameters to the same environment definition which gives a more detailed definition what kind of modules there are in this infrastructure.

So, this environment defition defines three modules: a resource group, virtual network (vnet) and a virtual machine (vm). Let's walk through those modules next.


## Resource-group Module

The [resource-group](terraform/modules/resource-group) just defines the main resource group that we are using with all resources in this infra. The resource groups are used in the Azure cloud used for providing a view to a set of resources and it is also easy manually to destroy a set of resources just by deleting the resource group.

## Vnet Module

The [vnet](terraform/modules/vnet) is a bit longer. First it defines a virtual network (vnet). We inject a [cidr address space](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) for the virtual network. All our resources will be using this address space. Then we define a subnet for making the security group rules easier. 

After the vnet and subnet we have a security group definition, and then we associate this sg to the subnet. After that we finally have the only rule in this sg - the only inbound traffic that we allow is ssh (port 22).

## Vm Module

The [vm](terraform/modules/vm) is a also a bit more complex. But let's not be intimidated - I took most of the code from a [Microsoft documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-create-complete-vm). As you can see, you can find infra code examples quite easily in the net - you don't have to invent the wheel again when creating most of the infra code.

So, in the vm module we first create the ssh keys. I later realized that there is some bash inline scripting here - most possibly won't be working if you run terraform in a Windows box (I must test this myself and make this part a bit simpler e.g. injecting the ssh public key manually here). 

After that we define a public ip (pip) and a virtual network interface card (nic) for the VM. This is mostly just some infra boilerplate - don't worry about it. After those entities we finally define the actual VM. Read the infra definition for the VM in more detail if you are interested - should be quite easy to read since terraform is declarative language (tells what to do, not an imperative specific instructions how to do it).

# Azure Tags

In main resources I have added some tags. 

- Name: "intro-demo-dev-vnet" - this is the name of the resource.
- Env: "dev" - this is the env (e.g. dev, qa, perf, prod...)
- Environment: "intro-demo-dev" - this is the specific environment for a specific infra, i.e. we are running dev for intro-demo.
- Prefix: "intro-demo" - this is the infra without the env postfix.
- Location: "westeurope" - Azure location.
Terraform: "true" (fixed)


If you figure out some consistent tagging system it is easy for you to find resources using tags. Examples:

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


# Demonstration Manuscript

NOTE: These instructions are for Linux (most probably should work for Mac as well). Windows instructions are in the next chapter.

Let's finally give detailed demonstration manuscript how you are able to deploy the infra of this demonstration to your Azure subscription. You need an Azure subscription for this demonstration. You can order a private Azure subscription or you can contact your line manager if there is an Azure development subscription in your unit that you can use for self-study purposes to learn how to use Azure. **NOTE**: Watch for costs! Always finally destroy your infrastructure once you are ready (never leave any resources to run indefinitely in your subscription to generate costs).

1. Install [Terraform](https://www.terraform.io/). 
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

**NOTE**: If some Windows guy volunteers to test deploying this demonstration using his/her Windows workstation and **native Windows command prompt** (not Git Bash as I used) and converts the [create-azure-storage-account.sh](scripts/create-azure-storage-account.sh) script to bat/powerhell script and writes the Windows instructions in this chapter I promise to give him/her one full hour personal face-to-face Azure training in Keila premises. And honorary mention as the writer of this chapter. 

But until we have better instructions from a Windows specialist I can tell how I tested deploying the infra using (virtual) Windows 10 (NOTE: these are a shortened version of the actual Demonstration Manuscript chapter - read above chapter as well).

1. Install:
   1.  [Git for Windows](https://git-scm.com/download/win)
   2.  [Terraform for Windows](https://www.terraform.io/downloads.html)
   3.  [Azure Command Line Interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
2. With Git for Windows you get a Bash for Git. I'm using it from now on: **Open Git Bash**. Now you have a bash console in Windows. Use Git Bash terminal in the following commands.
3. Clone this project: git clone https://github.com/tieto-pc/azure-intro-demo.git
4. Login to Azure:
   1. ```az login```.
   2. ```az account list --output table``` => Check which Azure accounts you have.
   3. ```az account set -s YOUR-ACCOUNT-ID``` => Set the right azure account. **NOTE**: This is important! Always check which Azure account is your default account so that your demos do not accidentally go to some customer Azure production environment!
5. Configure the terraform backend. Use script [create-azure-storage-account-win-version.sh](scripts/create-azure-storage-account-win-version.sh) to create a Terraform backend for your project. See more detailed instructions how to configure the backend in Terraform code and how to set the environment variable in chapter "Terraform Backend".

Before you continue you have to do stupid Windows change. Git for Bash screws the directory when creating the ssh key and trying to store the private key to local disk. If you are using Git Bash you have to change the [vm.tf](terraform/modules/vm/vm.tf):

```text
      mkdir -p ${path.module}/.ssh
      echo "${tls_private_key.ssh-key.private_key_pem}" > ${path.module}/.ssh/${local.my_private_key}
      chmod 0600 ${path.module}/.ssh/${local.my_private_key}
=>
      mkdir .ssh
      echo "${tls_private_key.ssh-key.private_key_pem}" > .ssh/${local.my_private_key}
```

... this way the VM gets created but terraform still doesn't store the private key to your Windows workstation local disk, luckily terraform prints the private disk, so you can copy-paste it to file (and figure out the file format).

6. With Git Bash go to [dev](terraform/envs/dev) folder. Hopefully you installed terraform some reasonable directory (I installed in: /c/local/terraform_0.11.11/terraform.exe). Give commands:
   1. ```/your-path/terraform init``` => Initializes the Terraform backend state.
   2. ```/your-path/terraform get``` => Gets the terraform modules of this project.
   3. ```/your-path/terraform plan``` => Gives the plan regarding the changes needed to make to your infra. **NOTE**: always read the plan carefully!
   4. ```/your-path/terraform apply``` => Creates the delta between the current state in the infrastructure and your new state definition in the Terraform configuration files.
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



# Suggestions to Continue this Demonstration

We could add e.g. scale set to this demonstration but let's keep this demonstration as short as possible so that it can be used as an Azure introduction demonstration. If there are some improvement suggestions that our AS developers would like to see in this demonstration let's create other small demonstrations for those purposes, e.g.:
- Create a custom Linux image that has the Java app baked in.
- A scale set for VMs.
- Logs to Log Analytics.
- Use container instead of VM.