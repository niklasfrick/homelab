terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "0.41.3"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "0.15.40"
    }
  }
}

provider "infisical" {
  host = "https://eu.infisical.com"
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}

ephemeral "infisical_secret" "unifi_username" {
  name         = "unifi-username"
  env_slug     = "prod"
  workspace_id = "aa35d54e-a703-4e3d-96dc-58c706ba60a7"
  folder_path  = "/base-infrastructure"
}

ephemeral "infisical_secret" "unifi_password" {
  name         = "unifi-password"
  env_slug     = "prod"
  workspace_id = "aa35d54e-a703-4e3d-96dc-58c706ba60a7"
  folder_path  = "/base-infrastructure"
}

locals {
  unifi_credentials = {
    username = ephemeral.infisical_secret.unifi_username.value
    password = ephemeral.infisical_secret.unifi_password.value
  }
}

provider "talos" {}

provider "unifi" {
  username       = local.unifi_credentials.username
  password       = local.unifi_credentials.password
  api_url        = "https://${var.unifi_hostname}.${var.dns_domain}"
  allow_insecure = true
}
