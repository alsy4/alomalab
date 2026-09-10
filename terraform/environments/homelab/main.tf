module "nas" {
  source = "../../modules/proxmox-lxc"

  node_name = var.proxmox_node

  vm_id    = 102
  hostname = "nas"

  description = "NAS server - managed by Terraform"

  template_file_id = var.lxc_template
  datastore_id     = var.lxc_datastore

  cpu_cores = 1
  memory    = 1024
  swap      = 512
  disk_size = 8

  bridge       = "vmbr0"
  ipv4_address = "dhcp"

  unprivileged = true
  nesting      = false

  ssh_public_keys = [
    var.ssh_public_key
  ]
}