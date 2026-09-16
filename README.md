# AlomaLab Homelab

AlomaLab is infrastructure-as-code for a small Proxmox homelab. Terraform
declares virtual machines, LXC containers, storage mounts, and a reserved SDN;
Ansible configures the K3s cluster and the services hosted by the containers.

![AlomaLab homelab and K3s architecture](docs/architecture-diagram/alomalab-homelab.architecture-redraw.svg)

## What is managed

- A three-VM K3s topology on the Proxmox host: one control plane at
  `192.168.0.200` and two workers at `192.168.0.201–202`.
- K3s `v1.36.3+k3s1`, installed through the `k3s-ansible` collection after the
  VMs have been provisioned.
- A NAS LXC with an authenticated Samba share and a Syncthing service target.
- A Jellyfin LXC with Jellyfin, optional qBittorrent and Radarr playbooks,
  Syncthing, and host-backed media/shared mounts.
- Piloma at `192.168.0.14`, an existing Raspberry Pi outside Proxmox. It runs
  Caddy as the reverse proxy for internal services and is not a Kubernetes
  node.
- A Proxmox SDN (`k3szone`, `k3svnet`, and `vmbr20`) for
  `192.168.20.0/24`. It remains declared, but the current K3s VMs use `vmbr0`
  and `192.168.0.0/24` instead.

## Provisioning outline

1. Supply the Proxmox endpoint, account credentials, SSH public key, LXC
   template ID, and root password through an uncommitted
   `terraform/environments/homelab/terraform.tfvars` file.
2. Provision the Proxmox resources:

   ```bash
   terraform -chdir=terraform/environments/homelab init
   terraform -chdir=terraform/environments/homelab plan
   terraform -chdir=terraform/environments/homelab apply
   ```

3. Install the Ansible collection and configure K3s:

   ```bash
   ansible-galaxy collection install -r ansible/requirements.yml
   ansible-playbook -i ansible/inventory/homelab.yml \
     ansible/playbooks/k3s/setup-k3s.yml
   ```

The Kubernetes cluster consists only of the three Proxmox VMs. Piloma remains
outside the cluster so Caddy can retain the host's HTTP and HTTPS entry points.

## Documentation

- [Architecture and ownership boundaries](docs/architecture.md)
- [Repository structure](docs/structure.md)
- [Ansible commands and service notes](ansible/README.md)
- [Implementation log](docs/LOGS.md)
- [Standalone architecture diagram](docs/architecture-diagram/alomalab-homelab.architecture-redraw.html)
