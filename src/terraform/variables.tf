variable "proxmox_endpoint" {
  type        = string
  description = "Endpoint connection to connect to Proxmox (i.e. - https://10.0.0.1:8086)"
}

variable "proxmox_username" {
  type        = string
  description = "Username to connect to proxmox for terraform"
}

variable "proxmox_password" {
  type        = string
  description = "Password to connect to proxmox for terraform"
}

variable "proxmox_name" {
  type        = string
  description = "Proxmox node id - (i.e. - Proxmox001)"
}