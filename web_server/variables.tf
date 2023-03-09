variable "region" {
  description = "The aws region"
  type        = string
  default     = "us-east-1"
}

# Instance size
variable "instance_type" {
  default = "t2.micro"
}

variable "username" {
  type        = string
  
}

variable "VPC_name" {
  description = "The name of the vpc"
  type        = string
  default     = "demo-vpc"
}