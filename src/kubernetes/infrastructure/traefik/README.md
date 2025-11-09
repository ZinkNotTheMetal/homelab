# Traefik Ingress Controller

Traefik routes external traffic (*.zinkzone.tech) to services in your K3S cluster.

## Features

- ✅ LoadBalancer service (gets IP from MetalLB: 192.168.11.240)
- ✅ Automatic Let's Encrypt SSL certificates (via Cloudflare DNS challenge)
- ✅ HTTP → HTTPS redirect
- ✅ Security headers
- ✅ Rate limiting
- ✅ Traefik dashboard
- ✅ Routes home.zinkzone.tech → home VM (192.168.101.2)

## Prerequisites

- [x] MetalLB installed and working
- [x] Cloudflare API token configured
- [x] DNS managed by Cloudflare (zinkzone.tech)
- [x] Helm installed on your workstation

## Installation

### Install Helm (if not already installed)

```bash
# macOS
brew install helm

# Or download from https://helm.sh/docs/intro/install/
```

### Setup Cloudflare Secret

First, make sure you have the Cloudflare secret file:

```bash
# If cloudflare-secret.secret.yaml doesn't exist, create it
cp cloudflare-secret.yaml cloudflare-secret.secret.yaml

# Edit with your token
# (This file is gitignored via *.secret.yaml pattern)
```

### Install Traefik

```bash
cd /Users/william/Work/Personal/homelab/src/kubernetes/infrastructure/traefik
./install.sh
```

This will:
1. Create traefik namespace
2. Create Cloudflare API secret
3. Add Traefik Helm repo
4. Install Traefik with custom values
5. Apply middleware (HTTPS redirect, security)
6. Create IngressRoute for home.zinkzone.tech

## Configuration

### Traefik Service

- **Type:** LoadBalancer
- **IP:** 192.168.11.240 (assigned by MetalLB)
- **Ports:**
  - 80 (HTTP) → redirects to 443
  - 443 (HTTPS) → SSL termination

### Let's Encrypt

- **Email:** williamdzink@gmail.com
- **Challenge:** DNS-01 (via Cloudflare)
- **Resolver:** cloudflare
- **Storage:** /data/acme.json (persistent volume)

### Home VM Routing

- **Domain:** home.zinkzone.tech
- **Target:** 192.168.101.2:80 (Docker ipvlan on 192.168.10.246)
- **SSL:** Automatic (Let's Encrypt wildcard cert)

## DNS Configuration

Update Cloudflare DNS:

```
Type    Name                  Target              TTL
A       *.zinkzone.tech       192.168.11.240      Auto
A       zinkzone.tech         192.168.11.240      Auto
```

Or use Cloudflare's proxied mode (orange cloud):
- Pros: DDoS protection, CDN
- Cons: Let's Encrypt HTTP challenge won't work (that's why we use DNS challenge)

## Verification

### Check Traefik is running

```bash
# Check pods
kubectl get pods -n traefik

# Should see:
# NAME                      READY   STATUS    RESTARTS   AGE
# traefik-xxxxxxxxx-xxxxx   1/1     Running   0          2m
# traefik-xxxxxxxxx-yyyyy   1/1     Running   0          2m

# Check service
kubectl get svc -n traefik

# Should see:
# NAME      TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
# traefik   LoadBalancer   10.43.xxx.xxx   192.168.11.240   80:xxxxx/TCP,443:xxxxx/TCP   2m

# Check IngressRoutes
kubectl get ingressroute -n traefik

# Should see:
# NAME            AGE
# home-zinkzone   1m
# traefik-dashboard   1m
```

### Test home.zinkzone.tech

```bash
# From your Mac (after DNS is updated)
curl -I https://home.zinkzone.tech

# Should see:
# HTTP/2 200
# (and lots of headers from your home VM)

# Or visit in browser:
open https://home.zinkzone.tech
```

### Access Traefik Dashboard

```bash
# Visit: https://traefik.zinkzone.tech/dashboard/
# (Note the trailing slash!)

# You should see Traefik's dashboard with:
# - Services
# - Routers
# - Middlewares
# - EntryPoints
```

## Adding New Services

To expose a new service via Traefik:

```yaml
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: myapp
  namespace: default
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`myapp.zinkzone.tech`)
      kind: Rule
      services:
        - name: myapp-service
          port: 80
      middlewares:
        - name: https-redirect
          namespace: traefik
        - name: security-headers
          namespace: traefik
  tls:
    certResolver: cloudflare
```

## Troubleshooting

### Traefik not getting LoadBalancer IP

```bash
# Check MetalLB is running
kubectl get pods -n metallb-system

# Check MetalLB speaker logs
kubectl logs -n metallb-system -l component=speaker

# Check service events
kubectl describe svc -n traefik traefik
```

### SSL Certificate not generating

```bash
# Check Traefik logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# Look for ACME/Let's Encrypt errors
kubectl logs -n traefik -l app.kubernetes.io/name=traefik | grep -i acme

# Check Cloudflare API token is valid
kubectl get secret -n traefik cloudflare-api-token -o jsonpath='{.data.token}' | base64 -d
```

### home.zinkzone.tech not working

```bash
# Check if endpoints exist
kubectl get endpoints -n traefik home-vm-service

# Should show:
# NAME              ENDPOINTS           AGE
# home-vm-service   192.168.101.2:80    5m

# Test connectivity from cluster to home VM
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- curl http://192.168.101.2

# If that fails, check:
# 1. Is home VM running?
# 2. Is Docker ipvlan 192.168.101.2 configured?
# 3. Can K3S nodes reach 192.168.101.2?
```

### DNS not resolving

```bash
# Check DNS from your Mac
dig home.zinkzone.tech

# Should return 192.168.11.240

# If not, check Cloudflare DNS settings
```

## Uninstall

```bash
# Delete Traefik
helm uninstall traefik -n traefik

# Delete resources
kubectl delete -f home-ingressroute.yaml
kubectl delete -f middleware.yaml
kubectl delete secret cloudflare-api-token -n traefik
kubectl delete namespace traefik
```

## References

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Traefik Helm Chart](https://github.com/traefik/traefik-helm-chart)
- [Let's Encrypt DNS Challenge](https://doc.traefik.io/traefik/https/acme/#dnschallenge)
- [Cloudflare API Tokens](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
