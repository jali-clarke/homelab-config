terraform {
  backend "local" {
    path = ".tfstate"
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.33"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.3"
    }
  }
}

# set using env var `TF_VAR_vault_<username|password>=<...>`
variable vault_username {}
variable vault_password {}

provider "vault" {
  address = "https://vault.jali-clarke.ca"

  auth_login {
    path = "auth/userpass/login/${var.vault_username}"

    parameters = {
      password = var.vault_password
    }
  }
}

data "vault_generic_secret" "terraform" {
  path = "kv/terraform"
}

provider "hcloud" {
  token = data.vault_generic_secret.terraform.data["hcloud_token"]
}

data "vault_generic_secret" "cloudflare" {
  path = "kv/cloudflare"
}

provider "cloudflare" {
  email   = data.vault_generic_secret.cloudflare.data["email"]
  api_key = data.vault_generic_secret.cloudflare.data["api-key"]
}
