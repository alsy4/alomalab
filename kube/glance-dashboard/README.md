# Glance deployment

Argo CD's Application in `../argocd/applications/glance.yml` watches the
`kube` branch of `https://github.com/alsy4/alomalab.git` and builds this
directory with Kustomize. Push configuration changes to that branch to deploy.

## Proxmox authorization

Rebuilding K3s does not invalidate a token stored in Proxmox. Reuse an existing
monitoring token if its secret is available and its permissions are appropriate.
If the secret is lost, create a new token: Proxmox only displays the secret once.
Prefer a dedicated read-only token over an infrastructure administrator token.

To create one in the Proxmox UI:

1. Under Datacenter > Permissions > Users, add user `glance@pve` (Proxmox VE
   authentication realm).
2. Under Datacenter > Permissions, add a User Permission for `glance@pve`:
   path `/`, role `PVEAuditor`, Propagate enabled.
3. Under Datacenter > Permissions > API Tokens, add a token for `glance@pve`
   with token ID `dashboard`. Keep Privilege Separation enabled and save the
   displayed secret in your password manager.
4. Under Datacenter > Permissions, add an API Token Permission for
   `glance@pve!dashboard`: path `/`, role `PVEAuditor`, Propagate enabled.
   Both the user and token need permissions because their effective privileges
   are the intersection of the two.

The complete authorization header value is:

```text
PVEAPIToken=glance@pve!dashboard=YOUR_TOKEN_SECRET
```

On a machine with kubectl configured for the intended cluster, run the following
in Bash. Paste the complete header value at the hidden prompt. It is passed
through stdin rather than saved in Git or included in a command-line argument.

```bash
kubectl create namespace glance-dashboard --dry-run=client -o yaml | kubectl apply -f -
(
  set -euo pipefail
  read -r -s -p 'Proxmox authorization header: ' proxmox_authorization
  printf '\n'
  printf '%s' "$proxmox_authorization" |
    kubectl -n glance-dashboard create secret generic glance-proxmox \
      --from-file=authorization=/dev/stdin --dry-run=client -o yaml |
    kubectl apply --server-side -f -
)
```

The Deployment reads the Secret's `authorization` key as
`PROXMOX_AUTHORIZATION`. No `ca.crt` key is required. If Glance is already
running, restart it to load a changed token:

```bash
kubectl -n glance-dashboard rollout restart deployment/glance-dashboard
kubectl -n glance-dashboard rollout status deployment/glance-dashboard
```

## TLS and routing

`config/proxmox.yml` sets `allow-insecure: true` for the Proxmox API at
`https://192.168.0.20:8006`. HTTPS is still used, but the certificate is not
verified for this widget. This option does not change Proxmox server settings.

For browser access, DNS for `glance.apps.alomalab.internal` should point to
Piloma/Caddy at `192.168.0.14`. Caddy forwards to Traefik on the K3s nodes.
After a cluster rebuild, check `kubectl -n kube-system get svc traefik` and
ensure Caddy's upstream uses the current HTTP NodePort (previously `32041`).

## Verification

```bash
kubectl -n argocd get application glance
kubectl -n glance-dashboard get pods,svc,ingress
```

Expect Argo CD to report Synced/Healthy and the widget to show Proxmox resources.
HTTP 401 generally indicates an invalid token/header; HTTP 403 or an empty
resource list calls for checking both user and token permissions.

References: [Proxmox user management](https://pve.proxmox.com/pve-docs/chapter-pveum.html)
and [Glance configuration](https://github.com/glanceapp/glance/blob/main/docs/configuration.md).
