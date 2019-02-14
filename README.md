# Azure Short Intro Demonstration For AS Specialists  <!-- omit in toc -->


# Table of Contents  <!-- omit in toc -->
- [Introduction](#introduction)
- [Azure Solution](#azure-solution)
- [Terraform Code](#terraform-code)
- [Terraform Modules](#terraform-modules)
  - [VNET Module](#vnet-module)
  - [VM Module](#vm-module)
- [Terraform Backend](#terraform-backend)
- [Demo Application](#demo-application)
- [Demonstration Manuscript](#demonstration-manuscript)
- [Suggestions to Continue this Demonstration](#suggestions-to-continue-this-demonstration)



# Introduction

This demonstration has been created for our Application Service unit's purposes to be used in training new cloud specialists.

This project demonstrates basic aspects how to create cloud infrastructure using code. The actual infra is very simple: just one virtual machine (VM). We create a virtual network ([vnet](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview), a private subnet into which we create the VM, and a load balancer that is exposed to the internet and forwards traffic to the VM. There is also one security group in the private subnet that allows traffic only from the load balancer. I tried to keep this demonstration as simple as possible but at the same time realistic - a real simple system could use this architecture. The main purpose is not to provide an example how to create a cloud system (e.g. not recommending VMs over containers) but to provide an example of infrastructure code and tooling related creating the infra.


# Azure Solution

The diagram below depicts the main services / components of the solution.

![Azure Intro Demo Architecture](docs/azure-intro-demo.png?raw=true "Azure Intro Demo Architecture")


# Terraform Code

I am using [Terraform](https://www.terraform.io/) as a [infrastructure as code](https://en.wikipedia.org/wiki/Infrastructure_as_code) (IaC) tool. Terraform is very much used both in AWS and Azure side and one of its strenghts compared to cloud native tools (AWS / [CloudFormation](https://aws.amazon.com/cloudformation) and Azure / [ARM template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates)) is that you can use Terraform with many cloud providers, you have to learn just one infra language and syntax, and Terraform language (hcl) is pretty powerful and clear. When deciding the actual infra code tool you should consult the customer if there is some tooling already decided. Otherwise you should evaluate ARM template and Terraform which one is more appropriate to your cloud project.

If you are new to infrastructure as code (IaC) and terraform specifically let's explain the high level structure of the terraform code first. Project's terraform code is hosted in [terraform](terraform) folder.

It is a cloud best practice that you should modularize your infra code and also modularize it so that you can create many different (exact) copies of your infra as you like re-using the infra modules. I use a common practice to organize terraform code in three levels:

1. **Environment parameters**. In [envs](terraform/envs) folder we host the various environments. In this demo we have only the dev environment, but this folder could have similar environment parameterizations for qa, perf, prod environments etc. 
2. **Environment definition**. In [env-def](terraform/modules/env-def) folder we define the modules that will be used in every environment. The environments inject the environment specific parameters to the env-def module which then creates the actual infra using those parameters by calling various infra modules and forwarding environment parameters to the infra modules.
3. **Modules**. In [modules](terraform/modules) folder we have the modules that are used by environment definition (env-def, a terraform module itself also). There are modules for the main services used in this demonstration: [vnet](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) and [vm](https://azure.microsoft.com/en-us/services/virtual-machines/).


# Terraform Modules

In this chapter we walk through the terraform modules a bit deeper.

## VNET Module

TODO

## VM Module

TODO


# Terraform Backend

In a small project like this in which you are working alone you don't actually need a Terraform backend but let's use it in this demonstration to make a more realistic demonstration. You should use Terraform backend in any project that has more than one developer. The reason for using a Terraform backend is to store and lock your terraform state file so that many developers cannot concurrently make conflicting changes to the infrastructure.

TODO: More explanations here regarding Azure Storage...


# Demo Application

The demo application used in this demonstration is a simple Java REST application that simulates a CRM system. The application is hosted in a different Git repository since we are using the demo app in many cloud demonstrations: [java-simple-rest-demo-app](https://github.com/tieto-pc/java-simple-rest-demo-app). The demo application is baked into the VM image as a golden image (i.e. we don't install any software or touch the VM in any way after it is deployed into the infra).


# Demonstration Manuscript

You need an Azure subscription for this demonstration. You can order a private Azure subscription or you can contact your line manager if there is an Azure development subscription in your unit that you can use for self-study purposes to learn how to use Azure. **NOTE**: Watch for costs! Always finally destroy your infrastructure once you are ready (never leave any resources to run indefinitely in your subscription to generate costs).

1. Install [Terraform](https://www.terraform.io/). 
2. TODO: Install Azure command line interface TODO.
3. Clone this project. 
5. Login to Azure:
   1. ```az login```.
   2. ```az account list --output table``` => Check which Azure accounts you have."
   3. ```az account set -s \"<your-azure-account-name>\"``` => Set the right azure account."
6. Configure the terraform backend. Use script [create-azure-storage-account.sh](scripts/create-azure-storage-account.sh) to create a Terraform backend for your project. TODO. If you have a Windows machine I ask someone to make a bat or Powershell script later.
7. Open console in [dev](terraform/envs/dev) folder. Give commands
   1. ```terraform init``` => Initializes the Terraform backend state.
   2. ```terraform get``` => Gets the terraform modules of this project.
   3. ```terraform plan``` => Gives the plan regarding the changes needed to the 
   4. ```terraform apply``` => Creates the delta between current state in the infrastructure and your new state in the Terraform configuration files.
8. Open Azure Portal and browse different views to see what entities were created:
   1. TODO.
   2. TODO
9. Test the demo application by hitting to the load balancer with a http GET: 
   1. TODO: Get LB DNS here.
   2. TODO: curl command here.


# Suggestions to Continue this Demonstration

We could add e.g. scale set to this demonstration but let's keep this demonstration as short as possible so that it can be used as an Azure introduction demonstration. If there are some improvement suggestions that our AS developers would like to see in this demonstration let's create other small demonstrations for those purposes, e.g.:
- A scale set for VMs.
- Logs to Log Analytics.
- Use container instead of VM.