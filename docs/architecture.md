# Architecture

## Confirmed configuration

Terraform declares two unprivileged Debian LXC containers on the Proxmox node
named `proxmox`. The Ansible inventory assigns that node `192.168.0.20` and
the containers static addresses on `vmbr0`:

| Component | Declared address / ID | Confirmed role |
| --- | --- | --- |
| Proxmox node | `192.168.0.20` | Hosts the Terraform-managed LXC containers. |
| NAS LXC | VMID `102`, `192.168.0.102` | Samba file-share host and Syncthing service target. `/mnt/hdd/shared` is mounted at `/mnt/shared`. |
| Jellyfin LXC | VMID `103`, `192.168.0.103` | Media-service host and Syncthing service target, with host-backed media and shared bind mounts. |
| K3s SDN | `k3szone` / `k3svnet`, `192.168.20.0/24` | A Proxmox simple SDN zone, VNet, and subnet, applied through Terraform; `vmbr20` on `proxmox` is addressed as `192.168.20.1/24`. |
| K3s control-plane VM | VMID `20100`, `192.168.20.100` | Terraform-managed Ubuntu 22.04 VM named `k3s-cp-01`, with two vCPUs, 2 GiB dedicated memory, a 10 GB disk, and a VirtIO NIC on `vmbr20`. |
| Piloma | `192.168.0.14` | Existing reverse-proxy host in Ansible's `reverse_proxy` group. |

The LXC module uses the `bpg/proxmox` provider, a Debian template supplied by
`template_file_id`, and `vmbr0` networking. The Terraform configuration does
not establish the underlying physical network, Proxmox storage, DNS service,
or the current runtime state of these hosts. The K3s VM module downloads the
current Ubuntu Jammy cloud image from Ubuntu's cloud-images service, imports it
into Proxmox's `local` datastore, and attaches it to the VM's disk. Although
the VM and its network are named for K3s, no Kubernetes/K3s installation,
cluster membership, service, or workload is declared in this repository.

Ansible configures Samba on the NAS container. On the Jellyfin container it can
install Jellyfin (port `8096`), qBittorrent-nox (web UI port `8080`), and
Radarr (port `7878`). Its Syncthing playbook installs a separate service
instance on each Debian LXC as the `syncthing` system user, creates its service
home at `/var/lib/syncthing`, enables `syncthing@syncthing.service`, and waits
for the local administration interface on port `8384`. The playbook does not
declare device IDs, shared folders, or a completed synchronization relationship.
The Jellyfin playbook adds a Caddy site on Piloma for
`jellyfin.alomalab.internal` and proxies it to `192.168.0.103:8096` with
`tls internal`.

## Communication and dependencies

1. Terraform connects to the configured Proxmox API endpoint and declares the
   NAS and Jellyfin LXC resources.
2. Ansible connects to inventory hosts over SSH. Its mount-point playbook runs
   Proxmox `pct` commands on the Proxmox node.
3. Caddy on Piloma forwards the internal Jellyfin hostname to the Jellyfin
   service. DNS for that hostname and client trust of Caddy's local CA are
   operational requirements described by the Ansible documentation; this
   repository does not configure either one.
4. The NAS and Jellyfin containers consume host-backed bind mounts declared in
   Terraform. Samba exposes `/mnt/shared` through an authenticated share.
5. The Syncthing playbook manages an instance on each Debian LXC. Pairing those
   instances and selecting folders through the Syncthing UI or API are required
   before they exchange files; neither relationship is configured in this
   repository.
6. Terraform applies the `k3szone` simple SDN zone, `k3svnet`, and
   `192.168.20.0/24` subnet, then creates `vmbr20` on the Proxmox node with
   `192.168.20.1/24`. `k3s-cp-01` depends on that module and receives
   `192.168.20.100/24` with that bridge address as its gateway. The configuration
   does not declare an upstream route, DHCP, DNS, firewall policy, or any
   connectivity from this subnet to `192.168.0.0/24`.

## Documentation automation

GitHub Actions runs the repository-local Codex documentation agent for
qualifying pushes to `main` and for manual dispatch. When documentation changes
are ready to publish, the workflow uses the `DOCUMENTATION_PR_TOKEN` repository
secret to authenticate `gh pr create`. The workflow verifies that the secret is
present before attempting to create the pull request. It then delivers the
repository's Archify architecture source as
`docs/architecture-diagram/alomalab-homelab.architecture.html`; the delivered
artifact is included with the documentation changes when rendering succeeds.

## Diagram

The existing [Archify source](architecture-diagram/alomalab-homelab.architecture.json)
and [interactive HTML diagram](architecture-diagram/alomalab-homelab.architecture.html)
show the pre-K3s LXC topology. They could not be updated in this workspace
because the Archify renderer cannot start under its sandbox restrictions; the
K3s network and VM are documented in the confirmed prose above.
