locals {
  home_hostname     = "home"
  home_vm_cpu_cores = 2
  home_vm_memory_mb = 6144
  home_disk_size_gb = 130
}

resource "proxmox_virtual_environment_vm" "home_vm" {
  name        = local.home_hostname
  vm_id       = 104
  description = "SmartHome Linux VM - Managed by Terraform"
  tags        = ["debian", "home"]

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

  cpu {
    cores = local.home_vm_cpu_cores
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = local.home_vm_memory_mb
  }

  disk {
    datastore_id = local.datastores.vm_raid_storage_id
    interface    = "scsi0"
    size         = local.home_disk_size_gb
  }

  network_device {
    bridge  = local.vm_network_bridge
    vlan_id = local.vlan_ids.iot_open
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  usb {
    host = "1-1.2"
    usb3 = false
  }

  usb {
    host = "1-10"
    usb3 = false
  }

  boot_order = ["scsi0", "ide3", "net0"]

}
