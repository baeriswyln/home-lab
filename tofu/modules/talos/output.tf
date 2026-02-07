# Collect each kubeconfig per Talos cluster definition
output "kubeconfig" {
  description = "Kubeconfig"
  value = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
}

output "kubernetes_client_configuration" {
  description = "Kubernetes client configuration"
  value = talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration
}

# Collect each client configuration per Talos cluster definition
output "client_configuration" {
  description = "Talos client configuration"
  value = data.talos_client_configuration.talosconfig.client_configuration
}

# Collect each Talos configuration per Talos cluster definition
output "talos_configuration" {
  description = "Full Talos configuration"
  value = data.talos_client_configuration.talosconfig.talos_config
}