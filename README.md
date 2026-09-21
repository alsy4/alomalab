# AlomaLab Homelab

Terraform provisions Proxmox VMs and LXCs. Ansible configures K3s and host
services. Argo CD deploys Glance and monitoring; CloudNativePG manages PostgreSQL.

## Current setup

- Proxmox: `192.168.0.20`; K3s control plane `.200`, workers `.201–202`.
- K3s `v1.36.3+k3s1`, running on Ubuntu Jammy VMs on `vmbr0`.
- Piloma `.14`: external Raspberry Pi running Pi-hole and Caddy.
- NAS LXC `.102`: Samba and Syncthing; Jellyfin LXC `.103`: media services.
- Reserved Terraform SDN `vmbr20` / `192.168.20.0/24` is not used yet by the VMs.

## GitOps applications

Both Applications use `https://github.com/alsy4/alomalab.git`.

| Application | Source                                                                  | Namespace          | Automated policy          |
| ----------- | ----------------------------------------------------------------------- | ------------------ | ------------------------- |
| Glance      | Branch `kube`, `kube/glance-dashboard`, Kustomize                       | `glance-dashboard` | Prune and self-heal       |
| Monitoring  | Helm `kube-prometheus-stack` 91.4.1; branch `main` for values/manifests | `psql`             | Self-heal; prune disabled |

Glance uses two replicas and an externally created Proxmox credential Secret.
Monitoring includes Prometheus, Grafana, Alertmanager, and exporters. Their
Traefik hosts are `glance.apps.alomalab.internal` and
`grafana.apps.alomalab.internal`.

## Provisioning

1. Supply Proxmox credentials, SSH key, template ID, and root password in an
   uncommitted `terraform/environments/homelab/terraform.tfvars`.
2. Run Terraform:

   ```bash
   terraform -chdir=terraform/environments/homelab init
   terraform -chdir=terraform/environments/homelab plan
   terraform -chdir=terraform/environments/homelab apply
   ```

3. Install K3s 

   ```bash
   ansible-galaxy collection install -r ansible/requirements.yml
   ansible-playbook -i ansible/inventory/homelab.yml \
     ansible/playbooks/k3s/setup-k3s.yml \
   ```

4. Follow the [GitOps runbook](docs/gitops.md) for application bootstrap and checks.

## Documentation

- [Architecture and ownership](docs/architecture.md)
- [Repository structure](docs/structure.md)
- [Glance setup and credentials](kube/glance-dashboard/README.md)
- [Ansible operations](ansible/README.md)
- [Implementation log](docs/LOGS.md)

Existing [K3s](docs/architecture-diagram/k3s-architecture.html) and
[homelab diagrams](docs/architecture-diagram/alomalab-homelab.architecture-redraw.html)
are historical snapshots, predating the current GitOps setup. See the
architecture document for current ports, sizing, and deployment ownership.
