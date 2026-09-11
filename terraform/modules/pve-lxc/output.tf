output "vm_id" {
  description = "Container VM ID"
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "hostname" {
  description = "Container hostname"
  value       = var.hostname
}

output "node_name" {
  description = "Proxmox node hosting the container"
  value       = var.node_name
}

