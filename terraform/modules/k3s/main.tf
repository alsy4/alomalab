resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name        = var.name
  description = var.description
  tags        = var.tags
  node_name   = var.proxmox_node
  vm_id       = var.vm_id

  timeout_create = 600
  agent {
    enabled = true
  }

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
    import_from = proxmox_download_file.latest_ubuntu_22_jammy_qcow2_img.id
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

resource "proxmox_download_file" "latest_ubuntu_22_jammy_qcow2_img" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = "jammy-server-cloudimg-amd64.qcow2"
}