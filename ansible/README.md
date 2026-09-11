# Ansible

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
