# Ansible

Run commands from the repository root with
`-i ansible/inventory/homelab.yml`. The inventory contains the two Debian LXC
hosts, the Proxmox host, Piloma, and the three Terraform-managed K3s VMs.

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
The K3s playbook targets only the three Proxmox VMs listed above. A live
inspection on 2026-09-18 found a retired `pi-worker-1` record still NotReady.

`playbooks/k3s/update-debian.yml` currently targets a `k3s_nodes` group that is
not present in the inventory. Ansible therefore warns and selects no hosts.
Align that playbook with `k3s_cluster` (or add an intentional aggregate group)
before using it for cluster maintenance.

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

Glance is deployed separately using [Kubernetes manifests](../kube/glance-dashboard/README.md).
Caddy and Pi-hole both run on Piloma. Glance's HTTPS site forwards to
`http://192.168.0.200:32041` (Traefik's observed HTTP NodePort), preserving
`glance.apps.alomalab.internal` for the Ingress host match. Its local DNS record
must point to Piloma `192.168.0.14`; inspection still returned `192.168.0.200`.

The live Glance block was found **inside the Jellyfin Ansible-managed markers**.
Move the Glance block outside those markers before rerunning
`setup-jellyfin.yml`: its `blockinfile` task replaces that whole region with
only the Jellyfin site. The playbook does not manage Glance, Pi-hole DNS,
Caddy CA distribution, or the legacy `127.0.0.1:32759` HTTP fallback.

See [architecture evidence and discrepancies](../docs/architecture.md#current-operational-discrepancies).
