locals {
  media_purpose      = "media"
  media_vm_cpu_cores = 4
  media_vm_memory_mb = 24576
  media_disk_size_gb = 10
}

resource "proxmox_virtual_environment_vm" "media_vm" {
  name        = "${local.media_purpose}"
  description = "Plex Server - Managed by Terraform"
  tags        = ["debian", "plex"]

  node_name = var.proxmox_name

  agent {
    # read 'Qemu guest agent' section, change to true only when ready
    enabled = true
  }
  # if agent is not enabled, the VM may not be able to shutdown properly, and may need to be forced off
  stop_on_destroy = true

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  machine = "q35,viommu=virtio"

  cpu {
    cores = local.media_vm_cpu_cores
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = local.media_vm_memory_mb
  }

  cdrom {
    file_id   = proxmox_virtual_environment_download_file.debian_12_img.id
    interface = "ide3"
  }

  disk {
    datastore_id = local.datastores.vm_raid_storage_id
    interface    = "scsi0"
    size         = local.media_disk_size_gb
  }

  network_device {
    bridge  = local.vm_network_bridge
    vlan_id = local.vlan_ids.iot_open
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  boot_order = ["scsi0", "ide3", "net0"]

}
