# Architecture

## Infrastructure ownership

Terraform provisions Proxmox guests; Ansible configures K3s and LXC services.
Argo CD reconciles selected applications. CloudNativePG reconciles database
Pods, Services, and storage from its Cluster resource.

| Component | Address / ID | Role |
| --- | --- | --- |
| Proxmox | `192.168.0.20` | Existing host for VMs and LXCs |
| `k3s-cp-01` | `.200`, VMID 20100 | Sole control plane |
| `k3s-worker-01` | `.201`, VMID 20101 | Worker |
| `k3s-worker-02` | `.202`, VMID 20102 | Worker |
| Piloma | `.14` | External Raspberry Pi: Pi-hole and Caddy |
| NAS | `.102`, VMID 102 | Samba and Syncthing LXC |
| Jellyfin | `.103`, VMID 103 | Media services and Syncthing LXC |

All abbreviated addresses above are on `192.168.0.0/24`.
Current working-tree Terraform declares 2 vCPUs, 4096 MiB memory, no ballooning,
and a 20 GiB disk for the control plane. Each worker has 2 vCPUs, 1538 MiB
dedicated/floating memory, and a 16 GiB disk. These are configuration values,
not verified applied Proxmox sizing; `k3s.tf` contains local edits.

VMs use Ubuntu Jammy, module `terraform/modules/pve-vm`, bridge `vmbr0`, and
gateway `192.168.0.1`. The reserved `k3szone` / `k3svnet` / `vmbr20`
network (`192.168.20.0/24`) is not attached to these VMs.
Ansible installs K3s `v1.36.3+k3s1` through `k3s.orchestration.site`.

## GitOps reconciliation

Application definitions live in `kube/argocd/applications`. Both use project
`default`, the in-cluster API, and `CreateNamespace=true`.

| Application | Source | Destination | Policy |
| --- | --- | --- | --- |
| `glance` | Git branch `kube`, path `kube/glance-dashboard` | `glance-dashboard` | Automated prune and self-heal |
| `prometheus-community` | Helm `kube-prometheus-stack` 91.4.1 plus Git branch `main` | `psql` | Automated self-heal; prune disabled; server-side apply |

Both Git sources use `https://github.com/alsy4/alomalab.git`.
Monitoring's Helm source reads `$values/kube/monitoring/values.yml` from the
Git source with `ref: values`. That source also renders
`kube/monitoring/manifests`. Its `postgres-podmonitor.yml` is currently empty.
The live PodMonitor named `cluster-example` is not evidence that the new
`psql` database is scraped.

No parent Application, Argo CD installation, or CloudNativePG installation is
defined here. PostgreSQL is manually applied and is outside these Applications.
Local edits deploy only after reaching the respective watched branch.
See the [GitOps runbook](gitops.md).

## Traffic and application configuration

The intended browser path is client → Pi-hole DNS → Caddy on Piloma →
Traefik → application endpoints. Caddy-served hostnames should resolve to
`192.168.0.14`; clients need to trust Caddy's internal CA.
These Applications do not manage Caddy or Pi-hole.

On 2026-09-21, Traefik exposed HTTP NodePort **32546** and HTTPS NodePort
**32055**, advertising `192.168.0.200–202`. The previous HTTP port 32041 is
historical. Caddy's current upstream and DNS records were not reverified.

Glance's Traefik Ingress matches `glance.apps.alomalab.internal` and routes
to Service `glance:8080`. Its Deployment has two replicas without an explicit
spread rule. Kustomize generates hashed ConfigMaps from `glance.yml`,
`home.yml`, `start.yml`, `proxmox.yml`, and `assets/user.css`. They mount
read-only at `/app/config` and `/app/assets`; no PVC is declared.
The standalone `assets-configmap.yml` is not referenced by Kustomize.
Secret `glance-proxmox` supplies `PROXMOX_AUTHORIZATION`; create it separately.
The Proxmox widget disables server certificate verification.
See the [Glance runbook](../kube/glance-dashboard/README.md).

Grafana uses Traefik host `grafana.apps.alomalab.internal`. Monitoring and
PostgreSQL share namespace `psql`. Monitoring values contain local edits;
this review verifies application health, not that every configured Helm key,
dashboard, rule, or scrape target is effective.

## PostgreSQL storage and availability

`kube/psql/psql.yml` declares Cluster `psql`, namespace `psql`, three
instances, and 1 GiB storage per instance. Live PVCs use `local-path`.
Default bootstrap created database/user `app` and Secret `psql-app`.
No backup configuration is declared.

Applications connect to `psql-rw.psql.svc.cluster.local:5432`. The operator
manages `psql-rw`, `psql-ro`, and `psql-r`; deleting those Services alone
does not remove the Cluster and they are recreated.

Local-path data is tied to one node. A replacement Pod cannot attach that
volume on an arbitrary worker. PostgreSQL replicas provide separate copies
and permit promotion of a healthy replica if the primary fails; replication
does not make the disk portable or replace backups. All VMs share one Proxmox
host, so they also share that host's failure domain.

## Current operational discrepancies

Read-only verification on **2026-09-21** found three Ready nodes, both Argo CD
Applications Synced/Healthy, and PostgreSQL healthy with three ready instances,
primary `psql-1`.

- Earlier in this session, the permanently removed `k3s-worker-03` node record
  and eight stale Pods were removed. Old database PVC/PV records cleared and
  the replacement PostgreSQL cluster bootstrapped.
- Ansible still lists worker 03 at `.203`; Terraform and the live node list
  contain only `.200–202`. Exclude it during setup until inventory is corrected.
- Worker 02 disk pressure briefly prevented the third database instance from
  scheduling after cleanup. The subsequent readiness check succeeded.
- The K3s update playbook targets undefined inventory group `k3s_nodes`.
- DNS bypassing Caddy and Glance inside Jellyfin's managed Caddy markers were
  observed on September 18; these historical findings were not reverified here.

## Other services and diagrams

NAS exposes Samba from `/mnt/shared`, backed by Proxmox `/mnt/hdd/shared`.
Jellyfin receives writable `/mnt/media`, `/mnt/shared`, and `/mnt/media-2`.
Ansible can install Jellyfin (8096), qBittorrent (8080), Radarr (7878), and
Syncthing (8384 administration). Pairing Syncthing is manual. qBittorrent's
default download path differs from the shared bind-mount target.
Only Jellyfin's Caddy route is managed by its playbook.
See [Ansible operations](../ansible/README.md).

The tracked `documentation-agent.yml` workflow updates docs and renders
Archify artifacts, with optional publication of a documentation PR.
`docs-agent.yml` is a separate untracked local workflow draft at this review.

The existing [K3s diagram](architecture-diagram/k3s-architecture.html) and
[homelab diagram](architecture-diagram/alomalab-homelab.architecture-redraw.html)
are historical snapshots with older ports, sizing, and node observations.
The prose above is the current architecture reference.
