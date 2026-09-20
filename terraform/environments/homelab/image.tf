resource "proxmox_download_file" "ubuntu_jammy" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_node

  url       = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  file_name = "jammy-server-cloudimg-amd64.qcow2"
}
resource "proxmox_download_file" "debian_trixie" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_node

  url       = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  file_name = "debian-trixie-genericcloud-amd64.qcow2"
}
