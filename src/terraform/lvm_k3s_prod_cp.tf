# ============================================================================
# PRODUCTION CLUSTER - Control Plane
# ============================================================================
# Purpose: Production K8S control plane for *.zinkzone.tech services
# Tainted: NoSchedule (no workload pods run here, only control plane)
# Domain: *.zinkzone.tech (Let's Encrypt certs via cert-manager)
# ============================================================================

locals {
  k3s_prod_cp_hostname          = "k3s-prod-cp-1"
  k3s_prod_cp_node_cpu_cores    = 2
  k3s_prod_cp_node_memory_mb    = 6144 # 6GB
  k3s_prod_cp_node_disk_size_gb = 60
}

resource "proxmox_virtual_environment_vm" "k3s_prod_cp_vm" {
  name        = local.k3s_prod_cp_hostname
  vm_id       = 201
  description = "K3S Production Control Plane - Managed by Terraform"
  tags        = ["debian", "k3s", "production", "control-plane"]

  agent {
    enabled = true
  }

  node_name       = var.proxmox_name
  stop_on_destroy = true

  # Start early - workers depend on this
  startup {
    order      = "2"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = local.k3s_prod_cp_node_cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = local.k3s_prod_cp_node_memory_mb
  }

  boot_order = ["scsi0"]

  # Main disk - using the uploaded cloud image
  disk {
    datastore_id = local.datastores.vm_raid_storage_id
    interface    = "scsi0"
    file_id      = "${local.datastores.synology_proxmox}:import/debian-13-genericcloud-amd64.qcow2"
    file_format  = "raw"
    discard      = "on"
    size         = local.k3s_prod_cp_node_disk_size_gb
  }

  network_device {
    bridge  = local.vm_network_bridge
    vlan_id = local.vlan_ids.iot_open
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  initialization {
    datastore_id = local.datastores.vm_raid_storage_id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "william"
      keys     = [trimspace(data.local_file.mac_ssh_public_key.content)]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config_file["${local.k3s_prod_cp_hostname}"].id
  }
}

output "k3s_prod_cp_ipv4_address" {
  value = try(
    proxmox_virtual_environment_vm.k3s_prod_cp_vm.ipv4_addresses[1][0],
    "IP N/A - Retry apply after Cloud-Init setup"
  )
}
