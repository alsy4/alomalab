provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = "root@pam"
  password = var.proxmox_account_password
}
