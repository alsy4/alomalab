resource "proxmox_sdn_zone_simple" "k3s" {
  id  = "k3szone"
  mtu = 1500
}

resource "proxmox_sdn_vnet" "k3s" {
  id   = "k3svnet"
  zone = proxmox_sdn_zone_simple.k3s.id
}

resource "proxmox_sdn_subnet" "k3s" {
  vnet = proxmox_sdn_vnet.k3s.id
  cidr = "192.168.20.0/24"
}

resource "proxmox_sdn_applier" "k3s" {
  depends_on = [
    proxmox_sdn_zone_simple.k3s,
    proxmox_sdn_vnet.k3s,
    proxmox_sdn_subnet.k3s,
  ]
}

resource "proxmox_network_linux_bridge" "vmbr20" {
  name = "vmbr20"
  node_name = "proxmox"
  address = "192.168.20.1/24"
}