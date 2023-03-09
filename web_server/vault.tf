######################################################################
# Provision Vault
######################################################################
# Read the secret from vault server
data "vault_generic_secret" "read_vault" {
  path = "demo/${var.username}"
}