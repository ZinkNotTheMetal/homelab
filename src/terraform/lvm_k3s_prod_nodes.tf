# ============================================================================
# PRODUCTION CLUSTER - Worker Nodes
# ============================================================================
# Purpose: Production K8S workers that run all application workloads
# Count: 2 workers for HA and load distribution
# Resources: 28GB RAM each (56GB total), 150GB disk for media/app storage
# Math: 94GB total - 20GB existing VMs - 12GB CP - 6GB buffer = 56GB / 2 workers
# ============================================================================

locals {
  k3s_prod_node_hostname_prefix = "k3s-prod-node"
  k3s_prod_node_count           = 2

  k3s_prod_node_cpu_cores      = 4
  k3s_prod_node_memory_mb      = 28672 # 28GB
  k3s_prod_node_disk_size_gb   = 180
  k3s_prod_node_starting_vm_id = 202 # 302, 303
}

resource "proxmox_virtual_environment_vm" "k3s_prod_node_vm" {
  for_each = { for i in range(local.k3s_prod_node_count) : i + 1 => i + 1 }

  name        = "${local.k3s_prod_node_hostname_prefix}-${each.key}"
  vm_id       = local.k3s_prod_node_starting_vm_id + each.key - 1
  description = "K3S Production Worker Node ${each.key} - Managed by Terraform"
  tags        = ["debian", "k3s", "production", "worker"]

  agent {
    enabled = true
  }

  node_name       = var.proxmox_name
  stop_on_destroy = true

  # Start after control plane
  startup {
    order      = "2"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = local.k3s_prod_node_cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = local.k3s_prod_node_memory_mb
  }

  boot_order = ["scsi0"]

  # Main disk - using the uploaded cloud image
  # Larger disk for local storage, media caching, and container images
  disk {
    datastore_id = local.datastores.vm_raid_storage_id
    interface    = "scsi0"
    file_id      = "${local.datastores.synology_proxmox}:import/debian-13-genericcloud-amd64.qcow2"
    file_format  = "raw"
    discard      = "on"
    size         = local.k3s_prod_node_disk_size_gb
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

    user_data_file_id = proxmox_virtual_environment_file.cloud_config_file["${local.k3s_prod_node_hostname_prefix}-${each.key}"].id
  }
}

output "k3s_prod_node_ips" {
  value = {
    for vm_key, vm in proxmox_virtual_environment_vm.k3s_prod_node_vm :
    vm.name => try(vm.ipv4_addresses[1][0], "IP N/A - Retry after Cloud-Init")
  }
}
