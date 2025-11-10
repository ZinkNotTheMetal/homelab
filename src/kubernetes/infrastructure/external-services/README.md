# External Services Routing

This directory contains Kubernetes resources for routing to external services (outside the cluster) via Traefik ingress.

**Note**: These are one-off deployments and are NOT managed by Flux. They must be applied manually using `kubectl` or the install script.

## Services

### Synology NAS (`nas.zinkzone.tech`)
- **Target**: 192.168.1.197:5000
- **Description**: Routes to Synology NAS DSM interface

### Home Assistant (`home.zinkzone.tech`)
- **Target**: 192.168.101.2:8123
- **Description**: Routes to Home Assistant VM

## How It Works

Each service consists of two resources:

1. **External-DNS Service** (`*-external-dns.yaml`)
   - Creates a CNAME DNS record pointing to `traefik.zinkzone.tech`
   - External-DNS watches these services and automatically creates DNS records in Pi-hole
   - Example: `nas.zinkzone.tech` → CNAME → `traefik.zinkzone.tech`

2. **IngressRoute** (`*-ingressroute.yaml`)
   - Traefik IngressRoute that proxies traffic to the actual external service IP:port
   - Includes Service and Endpoints definitions pointing to external IPs
   - Handles SSL termination via Let's Encrypt (Cloudflare DNS challenge)

## Installation

### Install All External Services

```bash
cd src/kubernetes/infrastructure/external-services
./install.sh
```

### Install Individual Services

```bash
# NAS only
kubectl apply -f nas-external-dns.yaml
kubectl apply -f nas-ingressroute.yaml

# Home Assistant only
kubectl apply -f home-external-dns.yaml
kubectl apply -f home-ingressroute.yaml
```

## Prerequisites

- Traefik must be installed and running
- External-DNS must be configured and running
- MetalLB must be providing LoadBalancer IPs

## Verification

### Check DNS Records

```bash
# Wait 1-2 minutes for External-DNS to sync
dig nas.zinkzone.tech
dig home.zinkzone.tech

# Both should return CNAME → traefik.zinkzone.tech
# Which resolves to 192.168.11.240 (Traefik LoadBalancer IP)
```

### Check IngressRoutes

```bash
# List all IngressRoutes
kubectl get ingressroute -n traefik

# Check specific IngressRoute details
kubectl describe ingressroute nas-synology -n traefik
kubectl describe ingressroute home-zinkzone -n traefik
```

### Check External-DNS Logs

```bash
# Look for PUT operations creating the CNAME records
kubectl logs -n external-dns -l app=external-dns --tail=50 | grep -E "nas|home"

# Should see lines like:
# PUT nas.zinkzone.tech IN CNAME -> traefik.zinkzone.tech
# PUT home.zinkzone.tech IN CNAME -> traefik.zinkzone.tech
```

### Test Access

```bash
# Test NAS
curl -k https://nas.zinkzone.tech

# Test Home Assistant
curl -k https://home.zinkzone.tech
```

## Adding New External Services

To add a new external service (e.g., `service.zinkzone.tech` → `192.168.x.x:port`):

1. **Create External-DNS Service** (`service-external-dns.yaml`):
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: service-external-dns
     namespace: traefik
     annotations:
       external-dns.alpha.kubernetes.io/hostname: service.zinkzone.tech
   spec:
     type: ExternalName
     externalName: traefik.zinkzone.tech
     ports:
       - port: 80
         protocol: TCP
         name: http
   ```

2. **Create IngressRoute** (`service-ingressroute.yaml`):
   ```yaml
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: service-backend
     namespace: traefik
   spec:
     type: ClusterIP
     clusterIP: None
     ports:
       - port: <target-port>
         targetPort: <target-port>
         protocol: TCP
         name: http
   ---
   apiVersion: v1
   kind: Endpoints
   metadata:
     name: service-backend
     namespace: traefik
   subsets:
     - addresses:
         - ip: <target-ip>
       ports:
         - port: <target-port>
           name: http
   ---
   apiVersion: traefik.io/v1alpha1
   kind: IngressRoute
   metadata:
     name: service
     namespace: traefik
   spec:
     entryPoints:
       - websecure
     routes:
       - match: Host(`service.zinkzone.tech`)
         kind: Rule
         services:
           - name: service-backend
             port: <target-port>
     tls:
       certResolver: cloudflare
   ```

3. Apply the resources:
   ```bash
   kubectl apply -f service-external-dns.yaml
   kubectl apply -f service-ingressroute.yaml
   ```

## Troubleshooting

### DNS Not Resolving

```bash
# Check External-DNS logs
kubectl logs -n external-dns -l app=external-dns --tail=100

# Verify service has correct annotation
kubectl get svc service-external-dns -n traefik -o yaml | grep external-dns

# Check Pi-hole DNS records in web UI
# Navigate to: Local DNS → DNS Records
```

### 404 Error / Not Routing

```bash
# Check IngressRoute is created
kubectl get ingressroute -n traefik

# Check service and endpoints exist
kubectl get svc,endpoints -n traefik | grep service-name

# Check Traefik logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=50
```

### Can't Connect to External Service

```bash
# Test from a pod in the cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- sh
# Inside the pod:
curl -v http://<target-ip>:<target-port>

# If this fails, the external service might not be reachable from the cluster network
```

## Uninstall

```bash
# Remove all external service routes
kubectl delete -f home-external-dns.yaml
kubectl delete -f home-ingressroute.yaml
kubectl delete -f nas-external-dns.yaml
kubectl delete -f nas-ingressroute.yaml
```
