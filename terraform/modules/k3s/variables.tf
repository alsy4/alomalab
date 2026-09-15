variable "name" {
  type        = string
  description = "VM's name"
}

variable "proxmox_node" {
  type        = string
  description = "proxmox node name"
  default     = "proxmox"
}

variable "description" {
  type        = string
  description = "What the vm is for?"
}

variable "tags" {
  type = list(string)
}

variable "vm_id" {
  type = number
}

variable "cores" {
  type        = number
  description = "CPU cores"
}

variable "type" {
  type        = string
  description = "CPU types"
  default     = "x86-64-v2-AES"
}

variable "dedicated_memory" {
  type        = number
  description = "RAM dedicated memory"
}

variable "floating_memory" {
  type        = number
  description = "RAM floating memory, shared across pool"
  default     = 512
}

variable "datastore_id" {
  type        = string
  description = "id for storage datastore"
  default     = "local-lvm"
}

variable "interface" {
  type        = string
  description = "virtual interface for storage"
  default     = "scsi0"
}

variable "image_file_id" {
  type        = string
  description = "Proxmox file ID of the cloud image to import as the VM disk"
}

variable "size" {
  type        = number
  description = "disk size in gb"
}

variable "bridge" {
  type        = string
  description = "network bridge"
  default     = "vmbr0"
}

variable "model" {
  type        = string
  description = "network device model"
  default     = "virtio"
}

variable "address" {
  type        = string
  description = "ip address (without mask)"
}

variable "gateway" {
  type        = string
  description = "default gateway"
}

variable "username" {
  type        = string
  description = "account's username"
}

variable "ssh_public_keys" {
  type        = string
  description = "SSH public keys"
}

variable "root_password" {
  type = string
}
