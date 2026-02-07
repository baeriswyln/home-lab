# Generate machine secrets for Talos clusters
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_cluster_details.version
}

# Apply the machine configuration created in the data section
resource "talos_machine_configuration_apply" "node_config_apply" {
  for_each = { for i, v in proxmox_vm_qemu.talos_nodes : i => v }

  depends_on = [proxmox_vm_qemu.talos_nodes]

  client_configuration = talos_machine_secrets.this.client_configuration

  machine_configuration_input = data.talos_machine_configuration.machineconfig[each.key].machine_configuration
  node                        = each.value.default_ipv4_address
}

# Start the bootstrapping of the clusters
resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [talos_machine_configuration_apply.node_config_apply]

  client_configuration = talos_machine_secrets.this.client_configuration

  # node = var.talos_cluster_details.virtual_ip
  node = tolist([
    for k, v in var.nodes :
    split("/", v.ip_addr)[0]
    if can(regex("controller", lower(k)))
  ])[0]
}

# Collect the kubeconfig of the Talos clusters
resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [talos_machine_bootstrap.bootstrap, data.talos_cluster_health.cluster_health]

  client_configuration = talos_machine_secrets.this.client_configuration

  node = var.talos_cluster_details.virtual_ip
  # node = tolist([
    # for k, v in var.nodes :
    # split("/", v.ip_addr)[0]
    # if can(regex("controller", lower(k)))
  # ])[0]
}