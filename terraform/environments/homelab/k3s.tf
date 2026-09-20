module "k3s-cp-01" {
  source     = "../../modules/pve-vm"

  name         = "k3s-cp-01"
  description  = "k3s-control-plane"
  tags         = ["k3s"]
  proxmox_node = "proxmox"
  vm_id        = 20100
  image_file_id = proxmox_download_file.ubuntu_jammy.id

  cores = 2

  dedicated_memory = 2560
  floating_memory = 0

  size = 10

  address = "192.168.0.200"
  gateway = "192.168.0.1"

  username        = "root"
  ssh_public_keys = var.ssh_public_key
  root_password   = var.root_password
}

locals {
  k3s_workers = {
    k3s-worker-01 = {
      vm_id = 20101
      address = "192.168.0.201"
    }
    k3s-worker-02 = {
      vm_id = 20102
      address = "192.168.0.202"
    }
  }
}

module "k3s-worker" {
  for_each = local.k3s_workers
  source     = "../../modules/pve-vm"

  name         = each.key
  description  = "k3s worker node"
  tags         = ["k3s"]
  proxmox_node = "proxmox"
  vm_id        = each.value.vm_id
  image_file_id = proxmox_download_file.ubuntu_jammy.id

  cores = 2

  dedicated_memory = 1538
  # Either worker can host Argo CD; do not balloon them down to 512 MiB.
  floating_memory = 1538

  size = 8

  address = each.value.address
  gateway = "192.168.0.1"

  username        = "root"
  ssh_public_keys = var.ssh_public_key
  root_password   = var.root_password
}
