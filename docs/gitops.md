# GitOps operations

## Bootstrap boundaries

Terraform and Ansible provision infrastructure. Argo CD and the CloudNativePG
operator must already be installed; their installation is not defined here.

Create the Glance credential Secret using the
[Glance runbook](../kube/glance-dashboard/README.md), then register the Applications:

```bash
kubectl apply -f kube/argocd/applications/glance.yml
kubectl apply -f kube/argocd/applications/monitoring.yml
kubectl get applications -n argocd
```

These Application objects are bootstrap resources; no parent Application
manages them in this repository. Reapply their definitions when changing
their sources, destinations, or sync policy.

## Deploy changes

| Change | Edit | Publish to |
| --- | --- | --- |
| Glance configuration, CSS, workload, routing | `kube/glance-dashboard/` | Branch `kube` |
| Monitoring Helm values | `kube/monitoring/values.yml` | Branch `main` |
| Additional monitoring resources | `kube/monitoring/manifests/` | Branch `main` |

Argo CD automatically reconciles these sources. Glance enables pruning;
monitoring does not, so removing a monitoring manifest from Git does not
automatically remove its live resource. Both enable self-heal, so lasting
changes to managed resources should be made in the watched source.

Kustomize generates Glance ConfigMaps from the configuration files and CSS.
Do not manually maintain the unused standalone assets ConfigMap.
Proxmox credentials remain in the separately managed Kubernetes Secret.

## PostgreSQL

The database is currently applied separately:

```bash
kubectl create namespace psql --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f kube/psql/psql.yml
kubectl get clusters.postgresql.cnpg.io,pods,pvc -n psql
```

The manifest declares two instances, matching the two ready live instances
observed on September 24, with local-path storage. The September 21
three-instance observation is historical. See
[storage and failover](architecture.md#postgresql-storage-and-availability).
A missing Pod requires checking Cluster status, operator logs, events, node
health, and PVC ownership; applying a manifest successfully does not mean the
database is ready.

To connect locally, keep this running:

```bash
kubectl port-forward -n psql svc/psql-rw 5433:5432
```

In another terminal, use a PostgreSQL client:

```bash
psql -h localhost -p 5433 -U app -d app -W
```

Use the password from Secret `psql-app`. Do not commit credentials.
Inside Kubernetes use `psql-rw.psql.svc.cluster.local:5432`.

## Verification

```bash
kubectl get applications -n argocd
kubectl get nodes
kubectl get clusters.postgresql.cnpg.io -n psql
kubectl get pods,pvc -n psql -l cnpg.io/cluster=psql
kubectl get ingress -A
kubectl get svc traefik -n kube-system
kubectl get podmonitors -A
```

On September 21, both Applications were Synced/Healthy and PostgreSQL had
three ready instances. Traefik HTTP/HTTPS NodePorts were 32546/32055.
Caddy upstreams must match current ports; the historical 32041 value is stale.

The repository now declares PodMonitor `psql`; the live `cluster-example`
monitor selects the wrong cluster. On September 24 Prometheus had no PostgreSQL
targets and monitoring was OutOfSync/Progressing. After the new manifest reaches
`main` and reconciles, follow the [monitoring checks](../kube/monitoring/README.md)
and require both database targets to be UP. Application health alone does not
validate scraping. No live changes were made during this review.
