# AlomaLab Homelab

AlomaLab is infrastructure-as-code for a small Proxmox homelab. Terraform
declares virtual machines, LXC containers, storage mounts, and a reserved SDN;
Ansible configures the K3s cluster and the services hosted by the containers.

![AlomaLab K3s architecture: DNS, Caddy, Traefik and Glance](docs/architecture-diagram/k3s-architecture.svg)

## What is managed

- A three-VM K3s topology on the Proxmox host: one control plane at
  `192.168.0.200` and two workers at `192.168.0.201–202`.
- K3s `v1.36.3+k3s1`, installed through the `k3s-ansible` collection after the
  VMs have been provisioned.
- A NAS LXC with an authenticated Samba share and a Syncthing service target.
- A Jellyfin LXC with Jellyfin, optional qBittorrent and Radarr playbooks,
  Syncthing, and host-backed media/shared mounts.
- Piloma at `192.168.0.14`, an existing Raspberry Pi outside Proxmox. It runs
  Pi-hole DNS and Caddy for internal HTTPS. It is outside the intended K3s
  topology; a stale `NotReady` node record remains in the live API.
- A Proxmox SDN (`k3szone`, `k3svnet`, and `vmbr20`) for
  `192.168.20.0/24`. It remains declared, but the current K3s VMs use `vmbr0`
  and `192.168.0.0/24` instead.

## Kubernetes application access

- Glance in namespace `glance-dashboard`: two Deployment replicas, a
  ClusterIP Service, Traefik Ingress, and two ConfigMaps mounted as files.
- Caddy forwards `glance.apps.alomalab.internal` to the Traefik HTTP NodePort
  at `192.168.0.200:32041`. Pi-hole currently returns `.200` for this name;
  the Caddy HTTPS route requires DNS to return Piloma at `.14`.

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

The intended cluster consists of the three Proxmox VMs. All three were Ready
on 2026-09-18; the retired Pi record `pi-worker-1` was NotReady. Piloma runs
Caddy on a separate host, so its ports 80/443 do not conflict with the VMs.

For workload deployment and Caddy/DNS checks, follow the
[Glance runbook](kube/glance-dashboard/README.md).

## Documentation

- [Architecture and ownership boundaries](docs/architecture.md)
- [Repository structure](docs/structure.md)
- [Ansible commands and service notes](ansible/README.md)
- [Implementation log](docs/LOGS.md)
- [Homelab infrastructure overview](docs/architecture-diagram/alomalab-homelab.architecture-redraw.html)
- [Current K3s architecture SVG](docs/architecture-diagram/k3s-architecture.svg)
- [K3s diagram with evidence notes](docs/architecture-diagram/k3s-architecture.html)
