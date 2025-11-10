# ============================================================================
# TEST CLUSTER - Single Node (On-Demand)
# ============================================================================
# Purpose: Testing K8S configurations before deploying to production
# Domain: *.k3s.internal (self-signed certs)
# Usage: Start manually when needed, stop when done to save resources
# ============================================================================

locals {
  k3s_test_hostname          = "k3s-test-cp-1"
  k3s_test_node_cpu_cores    = 2
  k3s_test_node_memory_mb    = 6144 # 6GB
  k3s_test_node_disk_size_gb = 40
}

resource "proxmox_virtual_environment_vm" "k3s_test_vm" {
  name        = local.k3s_test_hostname
  vm_id       = 301
  description = "K3S Test Cluster (Single Node) - Managed by Terraform - START MANUALLY WHEN NEEDED"
  tags        = ["debian", "k3s", "test", "manual-start"]

  agent {
    enabled = true
  }

  node_name = var.proxmox_name

  # IMPORTANT: Keep stopped by default - only start when testing
  started         = false
  stop_on_destroy = true

  # Don't auto-start on Proxmox boot
  startup {
    order      = "99" # Last in order (manual start only)
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = local.k3s_test_node_cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = local.k3s_test_node_memory_mb
  }

  boot_order = ["scsi0"]

  disk {
    datastore_id = local.datastores.vm_raid_storage_id
    interface    = "scsi0"
    file_id      = "${local.datastores.synology_proxmox}:import/debian-13-genericcloud-amd64.qcow2"
    file_format  = "raw"
    discard      = "on"
    size         = local.k3s_test_node_disk_size_gb
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

    user_data_file_id = proxmox_virtual_environment_file.cloud_config_file["${local.k3s_test_hostname}"].id
  }
}

output "k3s_test_ipv4_address" {
  value = try(
    proxmox_virtual_environment_vm.k3s_test_vm.ipv4_addresses[1][0],
    "IP N/A - VM is stopped or Cloud-Init not ready. Start VM manually to get IP."
  )
}
