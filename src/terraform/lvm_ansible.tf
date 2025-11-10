locals {
  ansible_hostname     = "ansible"
  ansible_vm_cpu_cores = 1
  ansible_vm_memory_mb = 2048
  ansible_disk_size_gb = 10
}

resource "proxmox_virtual_environment_vm" "ansible_vm" {
  name        = local.ansible_hostname
  description = "Ansible Host Server - Managed by Terraform"
  tags        = ["debian", "ansible"]

  node_name = var.proxmox_name

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = true
  }
  # if agent is not enabled, the VM may not be able to shutdown properly, and may need to be forced off
  stop_on_destroy = true

  startup {
    order      = "4"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = local.ansible_vm_cpu_cores
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = local.ansible_vm_memory_mb
  }

  disk {
    datastore_id = local.datastores.vm_raid_storage_id
    interface    = "scsi0"
    size         = local.ansible_disk_size_gb
  }

  boot_order = ["scsi0", "net0"]

  network_device {
    bridge  = local.vm_network_bridge
    vlan_id = local.vlan_ids.default
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

}
