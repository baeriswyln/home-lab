# Define the Initial Image copied from the Talos Factory
locals {
  initial_image_amd64 = "factory.talos.dev/installer/${var.talos_cluster_details.schematic_id_amd64}:${var.talos_cluster_details.version}"
  initial_image_arm = "factory.talos.dev/installer/${var.talos_cluster_details.schematic_id_arm}:${var.talos_cluster_details.version}"
}

# Generate the Talos client configuration
data "talos_client_configuration" "talosconfig" {
  cluster_name = var.talos_cluster_details.name

  client_configuration = talos_machine_secrets.this.client_configuration

  endpoints = [
    for i, v in var.nodes :
    proxmox_vm_qemu.talos_nodes[i].default_ipv4_address
    if can(regex("controller", lower(v.key)))
  ]

  nodes = [
    for i, v in var.nodes :
    proxmox_vm_qemu.talos_nodes[i].default_ipv4_address
    if can(regex("controller", lower(v.key)))
  ]
}

# Generate and instantiate the Controller configuration
data "talos_machine_configuration" "machineconfig" {
  for_each = var.nodes

  cluster_name  = var.talos_cluster_details.name
  talos_version = var.talos_cluster_details.version

  cluster_endpoint = "https://${var.talos_cluster_details.virtual_ip}:6443"
  # cluster_endpoint = "https://${tolist([
  #   for k, v in var.nodes :
  #   proxmox_vm_qemu.talos_nodes[k].default_ipv4_address
  #   if can(regex("controller", lower(k)))
  # ])[0]}:6443"

  machine_secrets = talos_machine_secrets.this.machine_secrets

  machine_type = can(regex("controller", lower(each.key))) ? "controlplane" : "worker"

  config_patches = can(regex("controller", lower(each.key))) ? [
    templatefile("${path.module}/files/init_install_controller.tfmpl", {
      initial_image = "factory.talos.dev/metal-installer/${each.value.schematic_id}:${var.talos_cluster_details.version}"
      virtual_ip = var.talos_cluster_details.virtual_ip
      ip_addr = each.value.ip_addr
      gateway = var.vm_details.gateway
      nameserver1 = var.vm_details.nameserver1
      nameserver2 = var.vm_details.nameserver2
      hostname = "${var.talos_cluster_details.name}-${each.key}"
    }),
    ] : (can(regex("workerCompute", lower(each.key))) ? [
    templatefile("${path.module}/files/init_install_worker_compute.tfmpl", {
      initial_image = "factory.talos.dev/metal-installer/${each.value.schematic_id}:${var.talos_cluster_details.version}"
      ip_addr = each.value.ip_addr
      gateway = var.vm_details.gateway
      nameserver1 = var.vm_details.nameserver1
      nameserver2 = var.vm_details.nameserver2
      hostname = "${var.talos_cluster_details.name}-${each.key}"
    }),
    ] : [
    templatefile("${path.module}/files/init_install_worker_storage.tfmpl", {
      initial_image = "factory.talos.dev/metal-installer/${each.value.schematic_id}:${var.talos_cluster_details.version}"
      ip_addr = each.value.ip_addr
      gateway = var.vm_details.gateway
      nameserver1 = var.vm_details.nameserver1
      nameserver2 = var.vm_details.nameserver2
      hostname = "${var.talos_cluster_details.name}-${each.key}"
    })
  ])
}

# Check Talos cluster healthy state
data "talos_cluster_health" "cluster_health" {
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration

  control_plane_nodes = [
    for k, v in var.nodes :
    split("/", v.ip_addr)[0]
    if can(regex("controller", lower(k)))
  ]
  worker_nodes = [
    for k, v in var.nodes :
    split("/", v.ip_addr)[0]
    if can(regex("worker", lower(k)))
  ]

  endpoints = [
    for k, v in var.nodes :
    split("/", v.ip_addr)[0]
    if can(regex("controller", lower(k)))
  ]


  timeouts = {
    read = "10m"
  }
}