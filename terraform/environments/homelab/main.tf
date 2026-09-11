module "nas" {
  source = "../../modules/pve-lxc"

  node_name = var.proxmox_node

  vm_id    = 102
  hostname = "nas"

  description = "NAS server - managed by Terraform"

  template_file_id = proxmox_download_file.debian_13_lxc.id
  datastore_id     = var.lxc_datastore

  cpu_core         = 1
  dedicated_memory = 2048
  swap             = 512
  disk_size        = 8

  bridge = "vmbr0"

  unprivileged = true

  ssh_public_keys = [
    var.ssh_public_key
  ]
  root_password = var.root_password
}

resource "proxmox_download_file" "debian_13_lxc" {
  node_name    = var.proxmox_node
  content_type = "vztmpl" #Container templates
  url          = "https://images.linuxcontainers.org/images/debian/trixie/amd64/cloud/20260910_05:24/rootfs.tar.xz"
  datastore_id = var.template_datastore
}