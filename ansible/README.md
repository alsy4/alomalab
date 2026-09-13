# Ansible

## Samba

`playbooks/nas/samba-setup.yml` installs Samba on the `nas` host, uses the
existing `/mnt/shared` directory as the default authenticated share, and configures a Samba user. Supply
the password at runtime (or store it encrypted with Ansible Vault):

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/nas/samba-setup.yml \
  --extra-vars 'samba_username=alice samba_password=change-me'
```

Add further shares by overriding `samba_shares`, for example in a Vault or vars
file:

```yaml
samba_shares:
  - name: share
    path: /mnt/shared
  - name: media
    path: /mnt/media
    comment: Media library
    read_only: true
```

Every configured share is limited to `samba_username`; its backing directory is
created with group-writable permissions for that account. Do not put a real
password directly in a committed variables file.

To remove Samba while preserving `/mnt/shared` and every uploaded file, run:

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/nas/samba-teardown.yml \
  --extra-vars 'samba_username=alice'
```

This removes Samba, its configuration, and its dedicated account, but does not
delete any share directory or data. Reinstall by rerunning `nas/samba-setup.yml`
with the desired username and password.

## Jellyfin and reverse proxy

`playbooks/setup-jellyfin.yml` uses the `jellyfin` and `reverse_proxy` host
groups in `inventory/homelab.yml` to:

1. Install and start Jellyfin on `jellyfin` (`192.168.0.103`), listening on its
   standard port `8096`.
2. SSH to `piloma` (`192.168.0.14`) and add a Jellyfin reverse-proxy site to its
   existing `/etc/caddy/Caddyfile`. Caddy supports Jellyfin's WebSocket and
   streaming connections automatically.

Both hosts must be Debian-based and reachable by SSH with the credentials in the
inventory. Run it from the repository root:

```bash
ansible-playbook -i ansible/inventory/homelab.yml ansible/playbooks/setup-jellyfin.yml
```

Create a DNS record for `jellyfin.alomalab.internal` that points to Piloma's IP,
`192.168.0.14`. Caddy serves this `.internal` hostname over HTTPS using its
local CA; clients must trust that CA.

## qBittorrent

`playbooks/qbittorrent-setup.yml` installs the headless Debian
`qbittorrent-nox` package on the `jellyfin` host and manages it with systemd.
It listens on port `8080` by default and stores downloads under
`/var/lib/qbittorrent/downloads`. The existing `/mnt/media` bind mount is
read-only, so override `qbittorrent_download_dir` only after making another
target writable for the `qbittorrent` user.

Run it from the repository root:

```bash
ansible-playbook -i ansible/inventory/homelab.yml \
  ansible/playbooks/qbittorrent-setup.yml
```

Check `journalctl -u qbittorrent` for the initial Web UI credentials, then
change the password immediately. The Web UI address and port can be overridden
with `qbittorrent_webui_address` and `qbittorrent_webui_port`.
