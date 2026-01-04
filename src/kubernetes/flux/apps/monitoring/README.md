# Monitoring Stack

Complete observability solution for the homelab Kubernetes cluster with metrics, dashboards, and log aggregation.

## Components

| Component | Description | URL |
|-----------|-------------|-----|
| **Prometheus** | Metrics collection | https://prometheus.zinkzone.tech |
| **Grafana** | Visualization and dashboards | https://grafana.zinkzone.tech |
| **Loki** | Log aggregation (internal) | N/A |
| **Promtail** | Log collection agent | N/A (DaemonSet) |

## Resource Summary

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage |
|-----------|-------------|-----------|----------------|--------------|---------|
| Prometheus | 200m | 2000m | 1Gi | 4Gi | 50Gi |
| Grafana | 100m | 1000m | 256Mi | 1Gi | 10Gi |
| Loki | 100m | 1000m | 256Mi | 2Gi | 30Gi |
| Promtail | 50m | 200m | 64Mi | 256Mi | - |
| Node Exporter | 50m | 200m | 30Mi | 100Mi | - |
| Kube State Metrics | 50m | 200m | 64Mi | 256Mi | - |

**Total Storage Required**: ~90Gi (Longhorn)

## Prerequisites

1. **Longhorn** storage class configured
2. **Envoy Gateway** configured with Gateway API
3. **External-DNS** configured with Pi-hole and Gateway API support

## Installation

### 1. Create Grafana Admin Secret

```bash
cd src/kubernetes/flux/apps/monitoring

# Copy sample secret
cp grafana-secret.sample.yaml grafana-secret.secret.yaml

# Generate a strong password
openssl rand -base64 24

# Edit the secret file with your password
nano grafana-secret.secret.yaml
```

### 2. Deploy via Flux

If Flux is managing this directory, just commit and push:

```bash
git add .
git commit -m "Add monitoring stack"
git push
```

Or apply manually:

```bash
kubectl apply -k src/kubernetes/flux/apps/monitoring/
```

### 3. Wait for Deployment

```bash
# Watch HelmReleases
flux get helmreleases -n monitoring --watch

# Check pods
kubectl get pods -n monitoring -w
```

Initial deployment takes 5-10 minutes as Prometheus downloads all dashboards.

## Accessing Services

### Grafana

- **URL**: https://grafana.zinkzone.tech
- **Username**: `admin`
- **Password**: (from `grafana-secret.secret.yaml`)

### Prometheus

- **URL**: https://prometheus.zinkzone.tech
- No authentication by default

## Pre-installed Dashboards

### Kubernetes Dashboards (built-in)
- Kubernetes / API server
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods)
- Kubernetes / Compute Resources / Namespace (Workloads)
- Kubernetes / Compute Resources / Node (Pods)
- Kubernetes / Compute Resources / Pod
- Kubernetes / Compute Resources / Workload
- Kubernetes / Kubelet
- Kubernetes / Networking / Cluster
- Kubernetes / Networking / Namespace (Pods)
- Kubernetes / Networking / Namespace (Workload)
- Kubernetes / Persistent Volumes
- Kubernetes / Proxy
- Kubernetes / Scheduler
- Kubernetes / StatefulSets

### Custom Dashboards (auto-provisioned)
- **Node Exporter Full** (ID: 1860) - Detailed node metrics
- **Kubernetes Cluster Monitoring** (ID: 7249) - Cluster overview
- **Envoy Global** (ID: 11022) - Envoy Gateway metrics
- **Envoy Clusters** (ID: 11021) - Envoy cluster/upstream metrics
- **Longhorn** (ID: 16888) - Storage metrics
- **Loki Logs** (ID: 13639) - Log exploration
- **Container Logs** (ID: 16966) - Container log viewer
- **Flux Cluster** (ID: 16714) - GitOps status
- **Flux Control Plane** (ID: 16715) - Flux controllers
- **PostgreSQL** (ID: 9628) - Database metrics (CNPG)

## Using Loki for Log Exploration

### In Grafana

1. Go to **Explore** (compass icon in left sidebar)
2. Select **Loki** as the data source
3. Use LogQL to query logs

### Common LogQL Queries

```logql
# All logs from a specific namespace
{namespace="media"}

# All logs from a specific pod
{pod="sonarr-0"}

# All error logs across the cluster
{job="kubernetes-pods"} |= "error"

# Logs from a specific container with level filter
{container="sonarr"} | json | level="error"

# Radarr logs with download information
{namespace="media", app="radarr"} |= "download"

# All Flux reconciliation logs
{namespace="flux-system"} |= "reconcil"

# Envoy Gateway proxy logs
{namespace="envoy-gateway-system"} | json

# PostgreSQL logs
{namespace="pg-database"}
```

### Log Retention

- Logs are retained for **30 days**
- Storage limit: 30Gi
- Adjust in `loki-release.yaml` → `limits_config.retention_period`

## Prometheus Queries

### Common PromQL Queries

```promql
# CPU usage by pod
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)

# Memory usage by namespace
sum(container_memory_usage_bytes) by (namespace)

# HTTP requests per second (Envoy Gateway)
sum(rate(envoy_http_downstream_rq_total[5m])) by (envoy_http_conn_manager_prefix)

# Pod restarts
increase(kube_pod_container_status_restarts_total[1h]) > 0

# Disk usage percentage
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100

# Network traffic in/out
sum(rate(node_network_receive_bytes_total[5m])) by (instance)
sum(rate(node_network_transmit_bytes_total[5m])) by (instance)
```

## Enabling Alerting (Optional)

Alertmanager is disabled by default. To enable it with notifications:

### 1. Edit `kube-prometheus-stack-release.yaml`

```yaml
alertmanager:
  enabled: true
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: longhorn
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 5Gi
  config:
    global:
      resolve_timeout: 5m
    route:
      receiver: 'discord'
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
    receivers:
      - name: 'discord'
        discord_configs:
          - webhook_url: 'https://discord.com/api/webhooks/...'
```

### 2. Add HTTPRoute for Alertmanager

Add to `httproute.yaml` if you want external access.

## Troubleshooting

### HelmRelease Not Ready

```bash
# Check HelmRelease status
flux get helmreleases -n monitoring

# Get detailed error
kubectl describe helmrelease kube-prometheus-stack -n monitoring

# Check Helm controller logs
kubectl logs -n flux-system deploy/helm-controller | grep monitoring
```

### Prometheus Not Scraping Targets

```bash
# Check targets in Prometheus UI
# Go to: https://prometheus.zinkzone.tech/targets

# Check ServiceMonitor
kubectl get servicemonitor -n monitoring

# Check pod annotations
kubectl get pods -n monitoring -o yaml | grep -A5 prometheus.io
```

### Loki Not Receiving Logs

```bash
# Check Promtail pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail

# Check Promtail logs
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail

# Check Loki pods
kubectl logs -n monitoring -l app.kubernetes.io/name=loki
```

### Grafana Dashboard Not Loading

```bash
# Check Grafana pods
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Check sidecar for dashboard provisioning
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -c grafana-sc-dashboard
```

## Upgrades

Flux will automatically upgrade minor versions. For major upgrades:

1. Check release notes for breaking changes
2. Update version constraint in HelmRelease
3. Commit and push

```bash
# Example: Upgrade to specific version
# Edit kube-prometheus-stack-release.yaml
# Change: version: "72.x" to version: "73.x"
```

## Uninstall

```bash
# Remove via Flux
kubectl delete -k src/kubernetes/flux/apps/monitoring/

# Or delete individual resources
flux delete helmrelease kube-prometheus-stack -n monitoring
flux delete helmrelease loki -n monitoring
flux delete helmrelease promtail -n monitoring
kubectl delete namespace monitoring
```

**Warning**: This will delete all metrics history and dashboards!

## References

- [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Grafana Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana)
- [Loki Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/loki)
- [Promtail Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/promtail)
- [LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
- [PromQL Documentation](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
