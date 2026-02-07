terraform {
  required_version = ">= 1.8.1"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
  }
}

provider "proxmox" {
  pm_api_url          = file(var.api_url)
  pm_api_token_id     = file(var.api_token_id)
  pm_api_token_secret = file(var.api_token_secret)
  pm_tls_insecure     = true
}

provider "helm" {
  kubernetes = {
    host                   = module.talos-cluster.kubernetes_client_configuration.host
    client_certificate     = base64decode(module.talos-cluster.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(module.talos-cluster.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(module.talos-cluster.kubernetes_client_configuration.ca_certificate)
  }
}

provider "kubernetes" {
  host                   = module.talos-cluster.kubernetes_client_configuration.host
  client_certificate     = base64decode(module.talos-cluster.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos-cluster.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos-cluster.kubernetes_client_configuration.ca_certificate)
}