resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name        = var.name
  description = var.description
  tags        = var.tags
  node_name   = var.proxmox_node
  vm_id       = var.vm_id

  timeout_create = 600

  cpu {
    cores = var.cores
    type  = var.type
  }

  memory {
    dedicated = var.dedicated_memory
    floating  = var.floating_memory
  }

  disk {
    datastore_id = var.datastore_id
    interface = var.interface
    size = var.size
    import_from = var.image_file_id
  }
  

  network_device {
    bridge = var.bridge
    model = var.model
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = "${var.address}/24"
        gateway = var.gateway
      }
    }

    user_account {
      username = var.username
      keys = [var.ssh_public_keys]
      password = var.root_password
    }
  }

  operating_system {
    type = "l26"
  }

}