locals {
  proxmox_node_name = "proxmox001"
  vm_network_bridge = "vmbr1"
  default_username  = "william"

  datastores = {
    vm_raid_storage_id = "swat1"
    local_1tb_proxmox  = "local"
    synology_proxmox   = "NAS-Proxmox-10GB"
  }

  vlan_ids = {
    default    = 1
    iot_open   = 10
    iot_closed = 20
    cameras    = 30
    guest      = 999
  }
}
