locals {
  schematic_id_amd64 = "cc493cae44e0bdbbefb5b5d1fb22ff724134cd7c6bb65172fa84e181568be45d"
  schematic_id_arm   = "5560d6c98b97957f1a762d468a3afaa2f1122dc7631334044dba935373e57565"
}

module "talos-cluster" {
  source = "./modules/talos"

  api_url          = var.api_url
  api_token_id     = var.api_token_id
  api_token_secret = var.api_token_secret

  vm_details = {
    agent_number  = 1
    socket_number = 1
    skip_ipv6     = true
    scsihw        = "virtio-scsi-pci"
    qemu_os       = "l26"
    # Ensure the target_node name is defined correctly
    start_at_node_boot = true
    # Ensure the storage name is defined correctly based on your system settings
    storage = "local-lvm"
    # Define the DNS IP Address based on your system settings
    gateway = "172.16.0.1"
    nameserver1 = "172.16.0.10"
    nameserver2 = "172.16.0.1"
  }

  talos_cluster_details = {
    name = "castor"
    version            = "v1.12.2"
    schematic_id_amd64 = local.schematic_id_amd64
    schematic_id_arm   = local.schematic_id_arm
    virtual_ip = "172.16.11.0"
  }

  nodes = {
    "controller01" = {
      target_node  = "hp-node-01"
      id           = 0
      schematic_id = local.schematic_id_amd64
      vmodel       = "virtio"
      hdd_capacity = ["10G"]
      iso_name = "local:iso/talos-metal-amd64.iso"
      vmid         = 101
      vnetwork     = "vmbr0"
      vcores       = 4
      vram         = 2048
      ip_addr     = "172.16.11.1/16"
    },
    "controller02" = {
      target_node  = "hp-node-01"
      id           = 0
      schematic_id = local.schematic_id_amd64
      vmodel       = "virtio"
      hdd_capacity = ["10G"]
      iso_name = "local:iso/talos-metal-amd64.iso"
      vmid         = 102
      vnetwork     = "vmbr0"
      vcores       = 4
      vram         = 2048
      ip_addr     = "172.16.11.2/16"
    },
    "controller03" = {
      target_node  = "hp-node-01"
      id           = 0
      schematic_id = local.schematic_id_amd64
      vmodel       = "virtio"
      hdd_capacity = ["10G"]
      iso_name = "local:iso/talos-metal-amd64.iso"
      vmid         = 103
      vnetwork     = "vmbr0"
      vcores       = 4
      vram         = 2048
      ip_addr     = "172.16.11.3/16"
    },
    "workerStorage01" = {
      target_node  = "hp-node-02"
      id           = 0
      schematic_id = local.schematic_id_amd64
      vmodel       = "virtio"
      hdd_capacity = ["10G", "400G"]
      iso_name = "local:iso/talos-metal-amd64.iso"
      vmid         = 111
      vnetwork     = "vmbr0"
      vcores       = 2
      vram         = 16384
      ip_addr     = "172.16.11.11/16"
    },
    "workerStorage02" = {
      target_node  = "hp-node-03"
      id           = 0
      schematic_id = local.schematic_id_amd64
      vmodel       = "virtio"
      hdd_capacity = ["10G", "400G"]
      iso_name = "local:iso/talos-metal-amd64.iso"
      vmid         = 112
      vnetwork     = "vmbr0"
      vcores       = 2
      vram         = 2048
      ip_addr     = "172.16.11.12/16"
    },
    "workerStorage03" = {
      target_node  = "hp-node-03"
      id           = 0
      schematic_id = local.schematic_id_amd64
      vmodel       = "virtio"
      hdd_capacity = ["10G", "400G"]
      iso_name = "local:iso/talos-metal-amd64.iso"
      vmid         = 113
      vnetwork     = "vmbr0"
      vcores       = 2
      vram         = 2048
      ip_addr     = "172.16.11.13/16"
    }
  }
}


// flux configuration
// Create the  flux-system namespace.
resource "kubernetes_namespace" "flux_system" {
    depends_on = [ module.talos-cluster.kubernetes_client_configuration ]

  metadata {
    name = "flux-system"
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

// Create a Kubernetes secret with the Git credentials
// if a GitHub/GitLab token or GitHub App is provided.
resource "kubernetes_secret" "git_auth" {
  count      =  var.git_token != "" || var.github_app_id != "" ? 1 : 0
  depends_on = [kubernetes_namespace.flux_system]

  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }

  data = {
    username = var.git_token != "" ? "git" : null
    password = var.git_token != "" ? var.git_token : null
    githubAppID = var.github_app_id != "" ? var.github_app_id : null
    githubAppInstallationOwner = var.github_app_installation_owner != "" ? var.github_app_installation_owner : null
    githubAppPrivateKey = var.github_app_pem != "" ? var.github_app_pem: null
  }

  type = "Opaque"
}

resource "kubernetes_secret" "sops-gpg" {
  count      =  var.git_token != "" || var.github_app_id != "" ? 1 : 0
  depends_on = [kubernetes_namespace.flux_system]

  metadata {
    name      = "sops-gpg"
    namespace = "flux-system"
  }

  data = {
    "sops.asc" = base64encode(file(var.gpg_key))
  }

  type = "Opaque"
}

resource "helm_release" "flux_operator" {
  depends_on = [kubernetes_namespace.flux_system]

  name             = "flux-operator"
  namespace        = "flux-system"
  repository       = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart            = "flux-operator"
  wait = true
}

resource "helm_release" "flux_instance" {
  depends_on = [helm_release.flux_operator]

  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"

    set = [
    {
      name  = "instance.distribution.version"
      value = var.flux_version
    },
    {
      name  = "instance.distribution.registry"
      value = var.flux_registry
    },
    {
      name  = "instance.cluster.type"
      value = var.cluster_type
    },
    {
      name  = "instance.cluster.size"
      value = var.cluster_size
    },
    {
      name  = "instance.sync.kind"
      value = "GitRepository"
    },
    {
      name  = "instance.sync.url"
      value = var.git_url
    },
    {
      name  = "instance.sync.path"
      value = var.git_path
    },
    {
      name  = "instance.sync.ref"
      value = var.git_ref
    },
    {
      name  = "instance.sync.provider"
      value = var.github_app_id != "" ? "github" : "generic"
    },
    {
      name  = "instance.sync.pullSecret"
      value = var.git_token != "" || var.github_app_id != "" ? "flux-system" : ""
    },
    {
      name  = "healthcheck.enabled"
      value = "true"
      type  = "auto"
    },
  ]
}