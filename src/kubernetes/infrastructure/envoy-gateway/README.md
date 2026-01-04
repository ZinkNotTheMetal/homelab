# Envoy Gateway with cert-manager

This directory contains the configuration for Envoy Gateway as the ingress controller, replacing Traefik. It uses cert-manager for automatic TLS certificate management with a wildcard certificate for `*.zinkzone.tech`.

## Components

| Component | Description | Namespace |
|-----------|-------------|-----------|
| **cert-manager** | Certificate management controller | `cert-manager` |
| **Envoy Gateway** | Gateway API controller (Envoy-based) | `envoy-gateway-system` |
| **ClusterIssuer** | Let's Encrypt certificate issuer | Cluster-scoped |
| **Wildcard Certificate** | `*.zinkzone.tech` TLS certificate | `envoy-gateway-system` |
| **Gateway** | Main entry point for all traffic | `envoy-gateway-system` |
| **HTTPRoutes** | Route definitions for each service | Various namespaces |

## Architecture

```
Internet / Home Network
         ↓
    Pi-hole DNS
    - Managed by External-DNS
    - Records: *.zinkzone.tech → Gateway LoadBalancer IP
         ↓
    MetalLB (192.168.11.24x)
         ↓
    Envoy Gateway
    - TLS termination (wildcard cert)
    - HTTP → HTTPS redirect
    - Routes to K8S services
         ↓
    K8S Services / Pods
```

## Prerequisites

1. **MetalLB** installed and configured
2. **Flux** GitOps configured
3. **Longhorn** storage class (for Prometheus/Grafana in monitoring)
4. **Cloudflare** API token with DNS edit permissions

## Installation

### Step 1: Create Cloudflare Secret

The secret file `cloudflare-secret.secret.yaml` should already exist with your API token. If not:

```bash
cd src/kubernetes/infrastructure/envoy-gateway

# Copy sample and edit
cp cloudflare-secret.sample.yaml cloudflare-secret.secret.yaml
nano cloudflare-secret.secret.yaml
```

### Step 2: Apply Resources in Order

```bash
# 1. Create namespaces
kubectl apply -f namespace.yaml

# 2. Apply Cloudflare secret (for cert-manager)
kubectl apply -f cloudflare-secret.secret.yaml

# 3. Install cert-manager (wait for it to be ready)
kubectl apply -f cert-manager-release.yaml
kubectl wait --for=condition=Ready helmrelease/cert-manager -n cert-manager --timeout=5m

# 4. Create ClusterIssuer (after cert-manager CRDs are installed)
kubectl apply -f cluster-issuer.yaml

# 5. Install Envoy Gateway
kubectl apply -f envoy-gateway-release.yaml
kubectl wait --for=condition=Ready helmrelease/envoy-gateway -n envoy-gateway-system --timeout=5m

# 6. Create wildcard certificate
kubectl apply -f wildcard-certificate.yaml

# 7. Create Gateway
kubectl apply -f gateway.yaml

# 8. Create external service HTTPRoutes
kubectl apply -f external-services.yaml

# 9. Update External-DNS for Gateway API support
kubectl apply -f ../external-dns/deployment.yaml

# Note: HTTPRoutes for apps are deployed via Flux with each app
# They are located in: flux/apps/<app>/httproute.yaml
```

### Step 3: Verify Certificate

```bash
# Check certificate status
kubectl get certificate -n envoy-gateway-system

# Check certificate details
kubectl describe certificate wildcard-zinkzone-tech -n envoy-gateway-system

# Check if secret was created
kubectl get secret wildcard-zinkzone-tech-tls -n envoy-gateway-system
```

Certificate issuance typically takes 1-2 minutes.

### Step 4: Verify Gateway

```bash
# Check Gateway status
kubectl get gateway -n envoy-gateway-system

# Check Gateway has an IP assigned
kubectl get gateway homelab-gateway -n envoy-gateway-system -o jsonpath='{.status.addresses[0].value}'

# Check HTTPRoutes
kubectl get httproute -A
```

### Step 5: Test Access

```bash
# Test a service
curl -v https://grafana.zinkzone.tech

# Check DNS resolution
dig grafana.zinkzone.tech
```

## Migrating from Traefik

### Before Migration

1. Document all working Traefik IngressRoutes
2. Note any custom middleware configurations
3. Ensure all secrets are backed up

### Migration Steps

1. **Deploy Envoy Gateway** (this guide)
2. **Verify all HTTPRoutes work** with the new Gateway
3. **Update DNS** to point to the new Gateway LoadBalancer IP
4. **Remove Traefik** after verification

### Uninstall Traefik

After confirming Envoy Gateway works:

```bash
# Uninstall Traefik Helm release
helm uninstall traefik -n traefik

# Delete Traefik namespace
kubectl delete namespace traefik

# Remove old IngressRoute CRDs (optional, if no longer needed)
kubectl delete crd ingressroutes.traefik.io
kubectl delete crd ingressroutetcps.traefik.io
kubectl delete crd ingressrouteudps.traefik.io
kubectl delete crd middlewares.traefik.io
kubectl delete crd middlewaretcps.traefik.io
kubectl delete crd serverstransports.traefik.io
kubectl delete crd tlsoptions.traefik.io
kubectl delete crd tlsstores.traefik.io
kubectl delete crd traefikservices.traefik.io
```

### Cleanup Repository Files

After Traefik is uninstalled and Envoy Gateway is confirmed working, delete the old files:

```bash
# Remove old Traefik infrastructure directory
rm -rf src/kubernetes/infrastructure/traefik/

# Remove old Traefik IngressRoute files from external-services
rm src/kubernetes/infrastructure/external-services/*-ingressroute.yaml
```

**Files to Delete:**
- `src/kubernetes/infrastructure/traefik/` (entire directory)
  - `cloudflare-secret.sample.yaml`
  - `cloudflare-secret.secret.yaml`
  - `dashboard-ingressroute.yaml`
  - `install.sh`
  - `middleware.yaml`
  - `namespace.yaml`
  - `README.md`
  - `values.yaml`
- `src/kubernetes/infrastructure/external-services/` (old IngressRoute files)
  - `esphome-ingressroute.yaml`
  - `home-ingressroute.yaml`
  - `nas-ingressroute.yaml`
  - `nodered-ingressroute.yaml`
  - `traccar-ingressroute.yaml`
  - `zwavejs-ingressroute.yaml`

**Keep** the following files (used for external-dns annotations, may be obsolete after migration):
- `src/kubernetes/infrastructure/external-services/*-external-dns.yaml` 

> **Note**: The external-dns YAML files in `external-services/` may also be obsolete since External-DNS now reads from Gateway API HTTPRoutes directly. Verify that DNS records are created correctly from HTTPRoutes before deleting.

## HTTPRoutes Overview

Routes are co-located with their respective applications for better maintainability:

### Application Routes (in `flux/apps/<app>/httproute.yaml`)

| Hostname | Service | Location |
|----------|---------|----------|
| `sonarr.zinkzone.tech` | sonarr:8989 | `flux/apps/sonarr/httproute.yaml` |
| `radarr.zinkzone.tech` | radarr:7878 | `flux/apps/radarr/httproute.yaml` |
| `prowlarr.zinkzone.tech` | prowlarr:9696 | `flux/apps/prowlarr/httproute.yaml` |
| `overseerr.zinkzone.tech` | overseerr:5055 | `flux/apps/overseerr/httproute.yaml` |
| `qbittorrent.zinkzone.tech` | qbittorrent:8080 | `flux/apps/qbittorrent/httproute.yaml` |
| `flaresolverr.zinkzone.tech` | flaresolverr:8191 | `flux/apps/flaresolverr/httproute.yaml` |
| `authentik.zinkzone.tech` | authentik-release-server:80 | `flux/apps/authentik/httproute.yaml` |
| `grafana.zinkzone.tech` | grafana:80 | `flux/apps/monitoring/httproute.yaml` |
| `prometheus.zinkzone.tech` | prometheus:9090 | `flux/apps/monitoring/httproute.yaml` |
| `pgadmin.zinkzone.tech` | pgadmin:80 | `flux/apps/pgadmin/httproute.yaml` |
| `pdf.zinkzone.tech` | stirling-pdf:8080 | `flux/apps/stirling-pdf/httproute.yaml` |
| `hoarder.zinkzone.tech` | karakeep:3000 | `flux/apps/karakeep/httproute.yaml` |
| `longhorn.zinkzone.tech` | longhorn-frontend:80 | `infrastructure/longhorn/httproute.yaml` |

### External Service Routes (in `external-services.yaml`)

| Hostname | Target IP | Port | Description |
|----------|-----------|------|-------------|
| `home.zinkzone.tech` | 192.168.101.2 | 8123 | Home Assistant |
| `nas.zinkzone.tech` | 192.168.1.197 | 5000 | Synology NAS |
| `esphome.zinkzone.tech` | 192.168.101.2 | 6052 | ESPHome |
| `nodered.zinkzone.tech` | 192.168.101.2 | 1880 | Node-RED |
| `zwavejs.zinkzone.tech` | 192.168.101.2 | 8091 | Z-Wave JS |
| `traccar.zinkzone.tech` | 192.168.101.2 | 8082 | Traccar |

**Note**: Update the IP addresses in `external-services.yaml` to match your environment.

## Adding New Routes

### For Cluster Services

Create `httproute.yaml` in your app's Flux directory (e.g., `flux/apps/my-app/httproute.yaml`):

```yaml
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-service
  namespace: my-namespace
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myservice.zinkzone.tech
spec:
  parentRefs:
    - name: homelab-gateway
      namespace: envoy-gateway-system
  hostnames:
    - myservice.zinkzone.tech
  rules:
    - backendRefs:
        - name: my-service
          port: 8080
```

Then add it to your app's `kustomization.yaml`:

```yaml
resources:
  - helmrelease.yaml  # or deployment.yaml
  - httproute.yaml
```

Don't forget to add the namespace to the Gateway's ReferenceGrant in `gateway.yaml` if it's a new namespace.

### For External Services

Add to `external-services.yaml`:

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: my-external-service
  namespace: envoy-gateway-system
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 8080
      protocol: TCP
      targetPort: 8080
---
apiVersion: v1
kind: Endpoints
metadata:
  name: my-external-service
  namespace: envoy-gateway-system
subsets:
  - addresses:
      - ip: 192.168.x.x
    ports:
      - name: http
        port: 8080
        protocol: TCP
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-external
  namespace: envoy-gateway-system
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myexternal.zinkzone.tech
spec:
  parentRefs:
    - name: homelab-gateway
      namespace: envoy-gateway-system
  hostnames:
    - myexternal.zinkzone.tech
  rules:
    - backendRefs:
        - name: my-external-service
          port: 8080
```

## Troubleshooting

### Certificate Not Issuing

```bash
# Check cert-manager logs
kubectl logs -n cert-manager deploy/cert-manager

# Check certificate status
kubectl describe certificate wildcard-zinkzone-tech -n envoy-gateway-system

# Check certificate request
kubectl get certificaterequest -n envoy-gateway-system

# Check challenges (if stuck)
kubectl get challenges -A
kubectl describe challenge -n envoy-gateway-system <challenge-name>
```

### Gateway Not Getting IP

```bash
# Check MetalLB
kubectl get pods -n metallb-system
kubectl logs -n metallb-system -l component=speaker

# Check Gateway status
kubectl describe gateway homelab-gateway -n envoy-gateway-system
```

### HTTPRoute Not Working

```bash
# Check HTTPRoute status
kubectl describe httproute <name> -n <namespace>

# Check if parent Gateway is accepted
kubectl get httproute <name> -n <namespace> -o jsonpath='{.status.parents}'

# Check Envoy Gateway logs
kubectl logs -n envoy-gateway-system deploy/envoy-gateway
```

### DNS Not Resolving

```bash
# Check External-DNS logs
kubectl logs -n external-dns -l app=external-dns

# Verify Gateway API sources are configured
kubectl get deploy -n external-dns external-dns -o yaml | grep source
```

## Certificate Renewal

cert-manager automatically renews certificates 15 days before expiry. Monitor with:

```bash
# Check certificate expiry
kubectl get certificate -n envoy-gateway-system -o jsonpath='{.items[*].status.notAfter}'

# View renewal events
kubectl get events -n envoy-gateway-system --field-selector reason=Issuing
```

## References

- [Envoy Gateway Documentation](https://gateway.envoyproxy.io/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Cloudflare DNS-01 Challenge](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/)
