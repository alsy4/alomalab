# PostgreSQL monitoring

Argo CD `prometheus-community` watches `main`, renders this `manifests` directory,
and installs kube-prometheus-stack **91.4.1** in namespace `psql`. The database
Cluster is applied separately from `kube/psql/psql.yml` and declares two instances.

`manifests/postgres-podmonitor.yml` owns PodMonitor `psql`. It selects
`cnpg.io/cluster=psql` in namespace `psql`, scraping HTTP `/metrics` on named
port `metrics` (9187) every 30 seconds. The live operator is CloudNativePG
**1.30.0**; its [versioned monitoring documentation](https://github.com/cloudnative-pg/cloudnative-pg/blob/v1.30.0/docs/src/monitoring.md)
recommends a separately managed PodMonitor. Automatic creation is deprecated
and was disabled in the live Cluster. Metrics TLS was not enabled; enabling it
later requires updating this monitor's scheme and TLS configuration together.

The [91.4.1 chart values](https://github.com/prometheus-community/helm-charts/blob/kube-prometheus-stack-91.4.1/charts/kube-prometheus-stack/values.yaml)
and repository `podMonitorSelectorNilUsesHelmValues: false` allow selection
without a release-label restriction. Read-only inspection confirmed live
`podMonitorSelector: {}` and `podMonitorNamespaceSelector: {}`. The monitor also
carries `release: prometheus-community` for compatibility with release-filtered
selection if that policy is restored.

## Baseline and deployment checks

On **2026-09-24**, PostgreSQL had two ready instances, each exposing `metrics`.
Prometheus returned 21 active targets, **zero PostgreSQL targets**. The only
live PodMonitor, `cluster-example`, selected `cnpg.io/cluster=cluster-example`,
which matches neither database Pod. Monitoring was OutOfSync/Progressing.
The new manifest has not been applied as part of this repository maintenance.

After the reviewed change reaches `main` and Argo CD reconciles:

```bash
kubectl -n argocd get application prometheus-community
kubectl -n psql get podmonitor psql -o yaml
kubectl -n psql get pods -l cnpg.io/cluster=psql --show-labels
kubectl -n psql get prometheus prometheus-community-kube-prometheus \
  -o jsonpath='{.spec.podMonitorSelector}{"\n"}{.spec.podMonitorNamespaceSelector}{"\n"}'
kubectl -n psql port-forward svc/prometheus-community-kube-prometheus 9090:9090
```

In another terminal, require two targets, both `up`, with empty errors:

```bash
curl -fsS 'http://127.0.0.1:9090/api/v1/targets?state=active' | jq \
  '[.data.activeTargets[] | select(.scrapePool == "podMonitor/psql/psql/0") | {pod: .labels.pod, health, lastError}]'
```

PromQL `up{namespace="psql",pod=~"psql-[0-9]+"}` should report 1 for each
instance. If discovery is empty, check selectors, Argo reconciliation and
operator events. If targets are down, inspect the exporter port, network policy,
TLS settings and `lastError`; a Ready database does not prove a successful scrape.

Monitoring pruning is disabled. The old `cluster-example` monitor is not adopted
or deleted by this change; remove it only in a separately authorized live cleanup
after confirming the replacement works. A Git revert alone also will not delete
the new monitor because pruning is disabled.
