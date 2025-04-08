locals {
  ansible_purpose      = "ansible"
  ansible_vm_cpu_cores = 2
  ansible_vm_memory_mb = 2048
  ansible_disk_size_gb = 10
}

resource "proxmox_virtual_environment_vm" "ansible_vm" {
  name        = "${local.ansible_purpose}"
  description = "Managed by Terraform"
  tags        = ["debian", "ansible"]

  node_name = var.proxmox_name

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = false
  }
  # if agent is not enabled, the VM may not be able to shutdown properly, and may need to be forced off
  stop_on_destroy = true

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = local.ansible_vm_cpu_cores
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = local.ansible_vm_memory_mb
    floating  = local.ansible_vm_memory_mb # set equal to dedicated to enable ballooning
  }

  cdrom {
    file_id   = proxmox_virtual_environment_download_file.debian_12_img.id
    interface = "ide3"
  }

  disk {
    datastore_id = local.datastores.vm_raid_storage_id
    interface    = "scsi0"
    size         = local.ansible_disk_size_gb
  }

  network_device {
    bridge  = local.vm_network_bridge
    vlan_id = local.vlan_ids.default
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  boot_order = ["scsi0", "ide3", "net0"]

}
