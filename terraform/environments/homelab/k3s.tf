module "k3s-cp-01" {
  source = "../../modules/k3s"
  depends_on = [ module.vmbr20 ]

  name = "k3s-cp-01"
  description = "k3s-control-plane"
  tags = ["k3s"]
  proxmox_node = "proxmox"
  vm_id = 20100

  cores = 2

  dedicated_memory = 2048
  floating_memory = 512

  size = 10

  bridge = "vmbr20"
  address = "192.168.20.100"
  gateway = "192.168.20.1"

  username = "root"
  ssh_public_keys = var.ssh_public_key
  root_password = var.root_password 
}