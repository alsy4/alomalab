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
| Piloma | `192.168.0.14` | Existing reverse-proxy host in Ansible's `reverse_proxy` group. |

The LXC module uses the `bpg/proxmox` provider, a Debian template supplied by
`template_file_id`, and `vmbr0` networking. The Terraform configuration does
not establish the underlying physical network, Proxmox storage, DNS service,
or the current runtime state of these hosts.

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

## Documentation automation

GitHub Actions runs the repository-local Codex documentation agent for
qualifying pushes to `main` and for manual dispatch. When documentation changes
are ready to publish, the workflow uses the `DOCUMENTATION_PR_TOKEN` repository
secret to authenticate `gh pr create`. The workflow verifies that the secret is
present before attempting to create the pull request.

## Diagram

No architecture diagram is included. The required Archify skill is unavailable
in this environment, so no replacement diagram was created.
