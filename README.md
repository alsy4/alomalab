# AlomaLab Homelab

AlomaLab is infrastructure-as-code for a small Proxmox homelab. Terraform
declares Debian LXC containers for network-attached storage and media services;
Ansible configures those containers and the reverse proxy that publishes
Jellyfin inside the home network.

## What is managed

- A NAS container with an authenticated Samba share.
- A Jellyfin container, with optional qBittorrent and Radarr setup playbooks.
- Syncthing service provisioning on the NAS and Jellyfin containers; devices and
  shared folders are paired and configured after provisioning.
- A Caddy reverse-proxy configuration for `jellyfin.alomalab.internal`.

Terraform uses the `bpg/proxmox` provider to manage Proxmox LXC containers.
Ansible configures Debian-based hosts and services.

Start with the [repository structure](docs/structure.md), then review the
[implemented architecture](docs/architecture.md). Service-specific Ansible
commands are in [ansible/README.md](ansible/README.md), and confirmed changes
are recorded in [the implementation log](docs/LOGS.md).
