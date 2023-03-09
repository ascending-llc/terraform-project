provider "aws" {
  region = var.region
}
provider "vault" {
  # Configuration options
  # Recommanded to use environment variables to connect vault
}