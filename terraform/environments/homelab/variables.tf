variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
}

variable "proxmox_api_token" {
  description = "APi token"
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "proxmox"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key"
}

variable "template_datastore" {
  type        = string
  description = "Datastore used for LXC templates"
  default     = "local"
}

variable "template_file_id" {
  type        = string
  description = "File id for template file, get it by `pveam list local`"
}

variable "lxc_datastore" {
  type        = string
  description = "Datastore for LXC root fs"
  default     = "local-lvm"
}

variable "root_password" {
  description = "Password for the Proxmox root@pam account and provisioned LXC root accounts"
  type        = string
  sensitive   = true
}

variable "proxmox_account_password" {
  description = "account password"
  type        = string
  sensitive   = true
}
