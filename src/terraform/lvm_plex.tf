locals {
  plex_hostname     = "plex"
  plex_vm_cpu_cores = 4
  plex_vm_memory_mb = 12488
  plex_disk_size_gb = 75
}

resource "proxmox_virtual_environment_vm" "plex_vm" {
  name        = local.plex_hostname
  vm_id       = 101
  description = "Plex Server - Managed by Terraform"
  tags        = ["debian", "plex"]

  agent {
    enabled = true
  }

  node_name       = var.proxmox_name
  stop_on_destroy = true

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = local.plex_vm_cpu_cores
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = local.plex_vm_memory_mb
  }

  boot_order = ["scsi0"]

  # Main disk - using the uploaded cloud image
  disk {
    datastore_id = local.datastores.vm_raid_storage_id
    interface    = "scsi0"
    file_id      = "${local.datastores.synology_proxmox}:import/debian-13-genericcloud-amd64.qcow2"
    file_format  = "raw"
    discard      = "on"
    size         = local.plex_disk_size_gb
  }

  network_device {
    bridge  = local.vm_network_bridge
    vlan_id = local.vlan_ids.iot_open
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

    user_data_file_id = proxmox_virtual_environment_file.cloud_config_file["plex"].id

  }
}

output "plex_ipv4_address" {
  value = try(proxmox_virtual_environment_vm.plex_vm.ipv4_addresses[1][0], "IP N/A - Enable Agent after startup")
}
