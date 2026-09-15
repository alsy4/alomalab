# AlomaLab Homelab

AlomaLab is infrastructure-as-code for a small Proxmox homelab. Terraform
declares Debian LXC containers for network-attached storage and media services,
the network for a K3s control-plane VM, and that VM itself. Ansible configures
the containers and the reverse proxy that publishes Jellyfin inside the home
network.

## What is managed

- A NAS container with an authenticated Samba share.
- A Jellyfin container, with optional qBittorrent and Radarr setup playbooks.
- Syncthing service provisioning on the NAS and Jellyfin containers; devices and
  shared folders are paired and configured after provisioning.
- A Proxmox SDN zone, VNet, subnet, and Linux bridge for `192.168.20.0/24`,
  with an Ubuntu VM reserved as the K3s control plane.
- A Caddy reverse-proxy configuration for `jellyfin.alomalab.internal`.

Terraform uses the `bpg/proxmox` provider to manage Proxmox LXC containers and
the K3s control-plane VM. Ansible configures Debian-based hosts and services.

Start with the [repository structure](docs/structure.md), then review the
[implemented architecture](docs/architecture.md). Service-specific Ansible
commands are in [ansible/README.md](ansible/README.md), and confirmed changes
are recorded in [the implementation log](docs/LOGS.md).
