variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type = string
}

variable "proxmox_api_token" {
  description = "API_TOKEN"
  type = string
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type = string
  default = "proxmox"
}

variable "ssh_public_key" {
  type = string
  description = "SSH public key"
}

variable "template_datastore" {
  type = string
  description = "Datastore used for LXC templates"
  default = "local"
}

variable "lxc_datastore" {
  type = string
  description = "Datastore for LXC root fs"
  default = "local-lvm"
}