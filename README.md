# Terraform demo project with Ansible and Hashicorp Vault

This is the demo project for integrating Ansible and Hashicrop Vault with Terraform on AWS. In this project, you will be deploying following contents to your AWS account:

- A VPC with 1 public&1 private subnet

- Two security groups

- One EC2 instance called ‘web-server’

  - Ansible will be installed on this instance and provision nginx server
  - Will show `Hello` message or `Access Denied` message based on the username and password.

- One EC2 instance called ‘data-server’ (optional)

## Prerequisites

- Vaild AWS account with full EC2 and VPC access

- An Unsealed Hashicorp Vault server with url and token

- Terraform installed locally

## Start the project

First we need to run the shell script to connect to remote Vault server in local environment. The shell script will also ask you to store some username/password pair in the Vault server.

During the demo process, you will need to add at least one username/password pair. The username/password pair will be used to unblock the webpage later. You need to have one username `admin` with password `password` stored in Vault to unlock the webpage. 

```bash
source ./setup_vault.sh 
```

The vault url and token you put in will be set as environment variable and used by terraform.
The shell script process looks like follow:

```bash
Enter Vault server URL:
http://xx.xxxx.xx:8200/
Enter Vault token:
Enter Username:
admin
Enter Password:
== Secret Path ==
kv/data/admin

======= Metadata =======
Key                Value
---                -----
created_time       2023-03-08T21:37:22.329455896Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
Username and password stored in Vault.
Do you want to store another username/password pair?[y/n]
n

```
After we finish running the shell script with no error, we can run the terraform code. It will ask you to type the username during `terraform apply`.

```bash
terraform init
terraform apply
```
