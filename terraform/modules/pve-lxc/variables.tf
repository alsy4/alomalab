variable "node_name" {
  type        = string
  description = "Name displayed on pve gui"
}

variable "hostname" {
  type        = string
  description = "Hostname as per node"
}

variable "vm_id" {
  type        = number
  description = "VM Id"
}

variable "description" {
  type        = string
  description = "What is the VM for?"
  default     = "Managed by Terraform"
}

variable "template_file_id" {
  type        = string
  description = "Volume ID for LXC template"
}

variable "datastore_id" {
  type = string
  default = "local-lvm"
}

variable "disk_size" {
  type        = number
  description = "Size of the disk in Gi"
  default     = 8 #Gi
}

variable "cpu_core" {
  type    = number
  default = 1
}

variable "dedicated_memory" {
  type    = number
  default = 1024
}

variable "floating_memory" {
  type    = number
  default = 1024
}

variable "swap" {
  type = number
  default = 0
}

variable "bridge" {
  type = string
  description = "Network interfaces"
  default = "vmbr0"
}

variable "ipv4_address" {
  type = string
  default = "dhcp"
}

variable "gateway" {
  type = string
  description = "IPv4 Gateway"
  default = null
}

variable "ssh_public_keys" {
  type = list(string)
  default = []
}

variable "root_password" {
  type = string
}

variable "unprivileged" {
  type = bool
  default = true
}

variable "mount_points" {
  type = list(
    object({
      volume = string
      path = string
      read_only = optional(bool, false)
    })
  )

  default = []
}