locals {
  apps_purpose      = "apps"
  apps_vm_cpu_cores = 4
  apps_vm_memory_mb = 12288
  apps_disk_size_gb = 300
}

resource "proxmox_virtual_environment_vm" "apps_vm" {
  name        = local.apps_purpose
  vm_id       = 103
  description = "Standalone Apps & Traefik for Homelab - Managed by Terraform"
  tags        = ["debian", "applications"]

  node_name = var.proxmox_name

  agent {
    enabled = true
  }

  stop_on_destroy = true

  startup {
    order      = "4"
    up_delay   = "60"
    down_delay = "60"
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = local.apps_vm_cpu_cores
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = local.apps_vm_memory_mb
  }

  disk {
    datastore_id = local.datastores.vm_raid_storage_id
    interface    = "scsi0"
    size         = local.apps_disk_size_gb
  }

  network_device {
    bridge  = local.vm_network_bridge
    vlan_id = local.vlan_ids.iot_open
  }

  serial_device {}

  boot_order = ["scsi0", "net0"]

}

