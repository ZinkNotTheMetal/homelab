resource "proxmox_virtual_environment_download_file" "debian_12_img" {
  content_type = "iso"
  datastore_id = local.datastores.local_1tb_proxmox
  node_name    = var.proxmox_name
  url          = "https://debian.osuosl.org/debian-cdimage/12.10.0/amd64/iso-dvd/debian-12.10.0-amd64-DVD-1.iso"
}
