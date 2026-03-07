# Create the controller and worker nodes 
resource "proxmox_vm_qemu" "talos_nodes" {
  for_each = var.nodes

  name          = "${var.talos_cluster_details.name}-${each.key}"
  target_node   = each.value.target_node
  vmid          = each.value.vmid
  agent         = var.vm_details.agent_number
  skip_ipv6     = var.vm_details.skip_ipv6
  agent_timeout = 60
  memory        = each.value.vram
  scsihw        = var.vm_details.scsihw
  qemu_os       = var.vm_details.qemu_os
  start_at_node_boot        = var.vm_details.start_at_node_boot

  cpu {
    cores   = each.value.vcores
    sockets = var.vm_details.socket_number
  }

  disks {
    # ide {
    #   ide0 {
    #     cdrom {
    #       iso = each.value.iso_name
    #     }
    #   }
    # }
    scsi {
      scsi0 {
        disk {
          size    = each.value.hdd_capacity[0]
          storage = var.vm_details.storage
        }
      }
      dynamic "scsi1" {
        for_each = try([each.value.hdd_capacity[1]], [])
        content {
          disk {
            size = each.value.hdd_capacity[1]
            storage = var.vm_details.storage
          }
        }
      }
    }
  }

  network {
    id     = each.value.id
    model  = each.value.vmodel
    bridge = each.value.vnetwork
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      network, disk, target_node
    ]
  }
}