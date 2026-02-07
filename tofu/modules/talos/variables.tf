variable "api_url" {
  description = "The Proxmox API URL"
  type        = string
}

variable "api_token_id" {
  description = "The Proxmox API Toke ID"
  type        = string
}

variable "api_token_secret" {
  description = "The Proxmox API Toke Secret"
  type        = string
}

variable "vm_details" {
  description = "VM generic settings"
  type = object({
    agent_number        = optional(number)
    socket_number       = optional(number)
    skip_ipv6           = optional(bool, true)
    talos_template_name = optional(string)
    scsihw              = optional(string)
    qemu_os             = optional(string)
    start_at_node_boot              = optional(bool, true)
    storage             = optional(string)
    gateway = optional(string)
    nameserver1          = optional(string)
    nameserver2          = optional(string)
  })
}

variable "talos_cluster_details" {
  description = "The Talos cluster details"
  type = object({
    name = string
    version            = string
    schematic_id_amd64       = string
    schematic_id_arm       = string
    virtual_ip = string
  })
}

variable "nodes" {
    description = "Specification of a Talos node"
    type = map(object({
        target_node = string
        schematic_id = string
        iso_name            = optional(string)
        id = number
        vmodel = string
        hdd_capacity = list(string)
        vmid         = number
        vnetwork     = string
        vcores       = number
        vram         = number
        ip_addr = string
    }))
}