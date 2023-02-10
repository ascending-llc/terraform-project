variable "region" {
  description = "The aws region"
  type        = string
  default     = "us-east-1"
}

# Instance size
variable "instance_type" {
  default = "t2.micro"
}

# Vault url
variable "vault_url" {
  default = null
}

# Vault token 
variable "vault_token" {
  default = null
}

###############################################################
# Network Setting Variables
###############################################################
variable "VPC_name" {
  description = "The name of the vpc"
  type        = string
  default     = "demo-vpc"
}
variable "VPC_block" {
  description = "The CIDR range for the VPC. This should be a valid private (RFC 1918) CIDR range."
  type        = string
  default     = "192.168.0.0/16"
}
variable "public_subnet_block" {
  description = "CidrBlock for public subnet within the VPC"
  type        = string
  default     = "192.168.0.0/19"
}
variable "private_subnet_block" {
  description = "CidrBlock for private subnet within the VPC"
  type        = string
  default     = "192.168.32.0/19"
}