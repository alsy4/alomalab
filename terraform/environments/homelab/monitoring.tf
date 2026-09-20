module "monitoring" {
  source = "../../modules/pve-vm"

  name          = "k3s-worker-03"
  description   = "monitoring stack"
  tags          = ["grafana", "prometheus"]
  proxmox_node  = "proxmox"
  depends_on = [ proxmox_virtual_environment_file.worker_bootstrap ]
  vm_id         = 20103
  image_file_id = proxmox_download_file.debian_trixie.id

  cores = 2

  dedicated_memory = 4096

  size = 20

  address = "192.168.0.203"
  gateway = "192.168.0.1"

  username        = "root"
  ssh_public_keys = var.ssh_public_key
  root_password   = var.root_password
  vendor_data_file_id = proxmox_virtual_environment_file.worker_bootstrap.id
}
