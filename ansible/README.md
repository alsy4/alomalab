# Ansible

Run commands from the repository root with
`-i ansible/inventory/homelab.yml`. The inventory contains the two Debian LXC
hosts, the Proxmox host, Piloma, and three Terraform-managed K3s VMs.
The retired `k3s-worker-03` entry has been removed.

## K3s

Install the collection declared in `ansible/requirements.yml`, then run the
wrapper playbook:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/k3s/setup-k3s.yml
```

The wrapper imports `k3s.orchestration.site`, pins K3s to
`v1.36.3+k3s1`, and uses the first host in the `server` group as the API
endpoint. The declared cluster inventory is:

| Group | Host | Address | Provisioning |
| --- | --- | --- | --- |
| `server` | `k3s-cp-01` | `192.168.0.200` | Terraform VM |
| `agent` | `k3s-worker-01` | `192.168.0.201` | Terraform VM |
| `agent` | `k3s-worker-02` | `192.168.0.202` | Terraform VM |

Piloma (`192.168.0.14`) is outside the intended Kubernetes topology. It remains in the
`reverse_proxy` group so Caddy can own the host's HTTP and HTTPS entry points.
Read-only inspection on September 24 found all three nodes Ready.

`playbooks/k3s/update-debian.yml` already targets `k3s_cluster`; the previous
warning about an undefined `k3s_nodes` group was stale documentation. Preview
the three selected hosts with `ansible-playbook -i ansible/inventory/homelab.yml
ansible/playbooks/k3s/update-debian.yml --list-hosts` before maintenance.

## Jellyfin and Caddy

`playbooks/jellyfin/setup-jellyfin.yml` installs Jellyfin on
`jellyfin` (`192.168.0.103`), waits for port `8096`, and adds an Ansible-managed
site block to Piloma's existing `/etc/caddy/Caddyfile`:

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/jellyfin/setup-jellyfin.yml
```

Create a DNS record for `jellyfin.alomalab.internal` that points to
`192.168.0.14`. Caddy uses `tls internal`, so clients must trust its local CA.
The playbook requires Caddy and its configuration file to exist on Piloma; it
does not install Caddy or manage DNS.

## Jellyfin bind mounts

Terraform already declares these writable mounts for VMID `103`:

| Proxmox path | Container path |
| --- | --- |
| `/mnt/hdd/media` | `/mnt/media` |
| `/mnt/hdd/shared` | `/mnt/shared` |
| `/mnt/hdd/media/media-2` | `/mnt/media-2` |

`playbooks/jellyfin/setup-mount-points.yml` is an operational alternative that
uses `pct` on the Proxmox host, refuses to overwrite a different occupied mount
slot, and reboots the container when it adds a mount:

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/jellyfin/setup-mount-points.yml
```

## qBittorrent

`playbooks/jellyfin/qbittorrent-setup.yml` installs `qbittorrent-nox`, creates
a dedicated systemd service, exposes its Web UI on port `8080`, and currently
uses `/mnt/hdd/shared/torrents` as its default download directory:

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/jellyfin/qbittorrent-setup.yml
```

That default is created inside the LXC and is not the Terraform bind-mount
target (`/mnt/shared`). Override `qbittorrent_download_dir` with an intentional
writable path if downloads should land on host-backed storage. Check
`journalctl -u qbittorrent` for the initial credentials and change the password
immediately.

## Radarr

`playbooks/jellyfin/radarr-setup.yml` downloads the stable Radarr build for the
host architecture, installs it under `/opt/Radarr`, and starts it on port
`7878`:

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/jellyfin/radarr-setup.yml
```

The playbook does not configure a movie root, a qBittorrent integration, or a
Caddy route. Complete those application-level settings after installation.

## Samba

`playbooks/nas/samba-setup.yml` installs Samba on `nas`, exposes
`/mnt/shared` as an authenticated share by default, and requires the password
at runtime or through Ansible Vault:

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/nas/samba-setup.yml \
  --extra-vars 'samba_username=alice samba_password=change-me'
```

Add shares by overriding `samba_shares`. Every configured share is limited to
`samba_username`; its directory is created with group-writable permissions for
that account. Do not commit a real password.

To remove Samba while retaining the share directories and their data:

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/nas/samba-teardown.yml \
  --extra-vars 'samba_username=alice'
```

## Syncthing

`playbooks/nas/setup-syncthing.yml` installs one Syncthing instance on each
host in `debian_lxc`, runs it as the `syncthing` system user, and waits for the
local administration interface on port `8384`:

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/nas/setup-syncthing.yml
```

Device IDs, shared folders, and the relationship between the two instances are
not declared; pair and configure them after provisioning.

## Debian LXC updates

Update both Debian containers with:

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/jellyfin/update-debian.yml
```

This refreshes APT metadata, performs a distribution upgrade, removes unused
packages, and cleans the package cache for the `debian_lxc` group.

## Glance, Pi-hole and Caddy ownership

Glance is reconciled from branch `kube`; see the [Glance runbook](../kube/glance-dashboard/README.md).
Caddy and Pi-hole run on Piloma. On **2026-09-24**, direct Pi-hole DNS queries
resolved Glance, Grafana (the `*.apps.alomalab.internal` names), and Jellyfin to
`192.168.0.14`. The September 18 DNS bypass is historical, not current.
Clients must use Pi-hole and trust Caddy's internal CA.

Live Caddy currently proxies `*.apps.alomalab.internal` to
`http://192.168.0.200:80`. That endpoint and HTTP NodePort **32546** both
returned HTTP 200 for Glance's health endpoint. NodePort 32041 is obsolete;
HTTPS NodePort remains 32055. The repository apps playbook uses the verified
HTTP NodePort 32546 explicitly and preserves the original Host header, as
required by the Traefik Ingress. Recheck the Service before any later run.

The live wildcard block is still **inside Jellyfin's managed markers**.
The Jellyfin playbook now refuses to replace a region containing any extra
site. The new `playbooks/k3s/setup-apps-proxy.yml` owns a separate
`ANSIBLE MANAGED K3S APPS` block and refuses conflicting or nested ownership.
Both validate a candidate Caddyfile before replacing it and keep a backup.
Neither playbook was executed against Piloma during this maintenance review.

### One-time ownership migration (pending live work)

Back up `/etc/caddy/Caddyfile`, then move the existing wildcard block out of
Jellyfin's markers without changing its contents. Give it its own markers.
The relevant excerpt should initially be:

```caddyfile
# BEGIN ANSIBLE MANAGED JELLYFIN
jellyfin.alomalab.internal {
    tls internal
    reverse_proxy 192.168.0.103:8096
}
# END ANSIBLE MANAGED JELLYFIN

# BEGIN ANSIBLE MANAGED K3S APPS
*.apps.alomalab.internal {
    tls internal
    reverse_proxy http://192.168.0.200:80
}
# END ANSIBLE MANAGED K3S APPS
```

Preserve every other site. Validate with `sudo caddy validate --config
/etc/caddy/Caddyfile --adapter caddyfile` before reloading Caddy. Then preview
the independently managed apps route (this proposes switching port 80 to the
verified NodePort):

```bash
kubectl -n kube-system get svc traefik
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/k3s/setup-apps-proxy.yml --check --diff
```

After reviewing the diff, a separately authorized live run can omit
`--check --diff`. Override `traefik_http_upstream` if the Service changes.
Test HTTPS through Piloma and direct DNS queries afterwards. If validation or
routing fails, restore the backup, validate it, and reload Caddy.

Pi-hole DNS, CA distribution, and the live catch-all HTTP fallback
`127.0.0.1:32546` remain outside repository management. Piloma is no longer a
K3s node; that fallback needs a separate review before removal or replacement.
See [current observations](../docs/architecture.md#current-operational-discrepancies).
