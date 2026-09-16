# Architecture

![AlomaLab homelab and K3s architecture](architecture-diagram/alomalab-homelab.architecture-redraw.svg)

The [standalone diagram](architecture-diagram/alomalab-homelab.architecture-redraw.html)
contains the same topology with implementation notes. An
[interactive architecture view](architecture-diagram/alomalab-homelab.architecture.html)
is generated from the tracked
[Archify source](architecture-diagram/alomalab-homelab.architecture.json).

## Current topology

| Component | Address / ID | Repository ownership | Confirmed role |
| --- | --- | --- | --- |
| Proxmox node | `192.168.0.20` | Existing host in Ansible inventory | Runs the Terraform-managed VMs and LXC containers. |
| K3s control plane | VMID `20100`, `192.168.0.200` | Terraform VM; Ansible `server` host | Ubuntu Jammy VM with 2 vCPUs, 2 GiB dedicated memory, 512 MiB floating memory, and a 10 GiB disk. |
| K3s worker 01 | VMID `20101`, `192.168.0.201` | Terraform VM; Ansible `agent` host | Ubuntu Jammy worker with 1 vCPU, 1 GiB dedicated memory, 512 MiB floating memory, and an 8 GiB disk. |
| K3s worker 02 | VMID `20102`, `192.168.0.202` | Terraform VM; Ansible `agent` host | Second worker with the same VM sizing as worker 01. |
| Raspberry Pi reverse proxy (Piloma) | `192.168.0.14` | Existing physical host; Ansible `reverse_proxy` host | Runs Caddy outside Kubernetes and forwards internal service traffic. It is not a K3s node. |
| NAS LXC | VMID `102`, `192.168.0.102` | Terraform LXC; Ansible `nas` host | Samba and Syncthing target. Proxmox `/mnt/hdd/shared` is mounted at `/mnt/shared`. |
| Jellyfin LXC | VMID `103`, `192.168.0.103` | Terraform LXC; Ansible `jellyfin` host | Jellyfin, optional qBittorrent and Radarr, and Syncthing. It receives writable media/shared bind mounts. |
| Reserved K3s SDN | `k3szone`, `k3svnet`, `vmbr20`, `192.168.20.0/24` | Terraform | Declared Proxmox SDN and bridge. No current K3s VM is attached to it. |

## Kubernetes lifecycle

Terraform downloads the current Ubuntu Jammy cloud image, imports it into the
Proxmox `local` datastore, and creates the control-plane VM plus two worker VMs
on the `proxmox` node. The reusable VM module defaults to the `vmbr0` bridge;
`k3s.tf` assigns the three VMs addresses `192.168.0.200–202/24` with
`192.168.0.1` as their gateway.

Ansible then installs K3s through the Git-sourced `k3s-ansible` collection:

- `k3s-cp-01` is the sole host in `server` and supplies the API endpoint.
- `k3s-worker-01` and `k3s-worker-02` are the hosts in `agent`.
- `setup-k3s.yml` pins `k3s_version` to `v1.36.3+k3s1` and imports
  `k3s.orchestration.site`.

Piloma is not part of the cluster. The current Kubernetes membership is the
control-plane VM and the two worker VMs declared in the Ansible inventory.
Keeping Caddy outside Kubernetes gives the Raspberry Pi sole responsibility
for the LAN-facing HTTP and HTTPS entry points. The repository also contains no
Kubernetes manifests, Helm releases, ingress configuration, storage classes,
or workloads.

`playbooks/k3s/update-debian.yml` targets `k3s_nodes`, a group that does not
exist in the inventory. A syntax check succeeds but Ansible selects no hosts;
the target must be aligned before that maintenance playbook is operational.

## Network and communication

1. Terraform communicates with the configured Proxmox API to create the three
   VMs, two LXC containers, their disks, and the separate SDN resources.
2. Ansible reaches the inventory hosts over SSH. Cluster agents use the control
   plane at `192.168.0.200` as their K3s API endpoint.
3. The active VMs and containers use `vmbr0` on `192.168.0.0/24`. The declared
   `vmbr20`/`192.168.20.0/24` SDN is currently a disconnected reserved path;
   the configuration does not declare routing, DHCP, DNS, or firewall policy
   for it.
4. Caddy on Piloma forwards `jellyfin.alomalab.internal` to
   `192.168.0.103:8096` with `tls internal`. DNS for that name and client trust
   of Caddy's local CA are outside this repository.
5. The NAS and Jellyfin containers consume host-backed bind mounts. Samba
   exposes `/mnt/shared`; Jellyfin receives `/mnt/media`, `/mnt/shared`, and
   `/mnt/media-2`.

## Service configuration boundaries

Ansible can install Jellyfin on port `8096`, qBittorrent-nox on port `8080`,
and Radarr on port `7878`. Only Jellyfin has a declared Caddy route. The
qBittorrent playbook currently defaults to `/mnt/hdd/shared/torrents` inside
the LXC, which is not the Terraform bind-mount target `/mnt/shared`; choose an
intentional writable download directory during operation.

The Syncthing playbook creates and starts a separate `syncthing` service on the
NAS and Jellyfin LXCs and waits for each local administration interface on port
`8384`. Device IDs, shared folders, and the relationship between the instances
are not encoded in this repository.

## Documentation automation

The tracked `documentation-agent.yml` workflow runs for qualifying pushes to
`main` and for manual dispatch. It installs Archify, updates the authorized
documentation files, validates/renders the JSON architecture source, and can
publish a documentation branch and pull request using the
`DOCUMENTATION_PR_TOKEN` secret. The diagram-design HTML and SVG are maintained
alongside that interactive artifact for direct README/docs embedding.
