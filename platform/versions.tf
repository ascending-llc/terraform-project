terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }
    vault = {
      source = "hashicorp/vault"
      version = "3.12.0"
    }
  }
}