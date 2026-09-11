module "nas" {
  source = "../../modules/pve-lxc"

  node_name = var.proxmox_node

  vm_id    = 102
  hostname = "nas"

  description = "NAS server - managed by Terraform"

  template_file_id = var.template_file_id
  datastore_id     = var.lxc_datastore

  cpu_core         = 1
  dedicated_memory = 512
  swap             = 512
  disk_size        = 8


  bridge       = "vmbr0"
  ipv4_address = "192.168.0.102/24"
  gateway      = "192.168.0.1"

  unprivileged = true

  ssh_public_keys = [
    var.ssh_public_key
  ]
  root_password = var.root_password
}

module "jellyfin" {
  source = "../../modules/pve-lxc"

  node_name   = var.proxmox_node
  hostname    = "jellyfin"
  vm_id       = 103
  description = "Jellyfin Server - Managed by Terraform"

  template_file_id = var.template_file_id
  datastore_id     = var.lxc_datastore
  root_password    = var.root_password

  bridge       = "vmbr0"
  ipv4_address = "192.168.0.103/24"
  gateway      = "192.168.0.1"

  cpu_core         = 2
  dedicated_memory = 2048
  swap             = 1024
  disk_size        = 16

  unprivileged = true

  ssh_public_keys = [
    var.ssh_public_key
  ]
}
