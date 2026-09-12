resource "proxmox_virtual_environment_container" "this" {

  dynamic "mount_point" {
    for_each = var.mount_points

    content {
      volume = mount_point.value.volume
      path = mount_point.value.path
      read_only = mount_point.value.read_only
      shared = mount_point.value.shared
    }
  }

  node_name = var.node_name
  vm_id     = var.vm_id

  description  = var.description
  unprivileged = var.unprivileged

  features {
    nesting = true
  }

  cpu {
    cores = var.cpu_core
  }

  memory {
    dedicated = var.dedicated_memory
    swap      = var.swap
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }

  operating_system {
    type             = "debian"
    template_file_id = var.template_file_id
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.gateway
      }
    }

    user_account {
      keys     = var.ssh_public_keys
      password = var.root_password
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }
}
