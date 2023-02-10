# Terraform demo project with Ansible and Hashicorp Vault
This is the demo project for integrating Ansible and Hashicrop Vault with Terraform on AWS. In this project, you will be deploying following contents to your AWS account:

- A VPC with 1 public&1 private subnet

- Two security groups

- One EC2 instance called ‘web-server’

    - Ansible will be installed on this instance and provision nginx server

- One EC2 instance called ‘web-server’ (optional)

## Prerequisites
- Vaild AWS account with full EC2 and VPC access

- An Unsealed Hashicorp Vault server with url and token

- Terraform installed locally

## Start the project
```
export VAULT_ADDR=<your vault server url>
export VAULT_TOKEN=<your vault server token>
```
We use environment variables to connect Vault and Terraform because in this way you won’t need to hardcode anything into terraform code and the credentials won’t be stored in terraform state.
```
terraform init
terraform plan
terraform apply
```
