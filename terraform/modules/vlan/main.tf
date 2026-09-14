resource "proxmox_network_linux_bridge" "k3s" {
  node_name = "proxmox"
  name = "vmbr20"

  address = "192.168.20.1/24"

  comment = "k3s private network"

  autostart = true
}