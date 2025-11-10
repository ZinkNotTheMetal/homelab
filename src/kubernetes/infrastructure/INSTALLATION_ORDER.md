# Kubernetes Infrastructure Installation Order

This document outlines the correct order to install infrastructure components.

## Prerequisites

- K3S cluster running (control plane + workers)
- kubectl configured with `homelab-production-cluster` context
- MetalLB installed and configured

## Installation Steps

### Step 1: Prepare Pi-hole

Before deploying External-DNS, we need to update Pi-hole's configuration.

1. SSH to your DNS/Apps server:
   ```bash
   ssh user@192.168.11.169
   ```

2. Edit the local DNS configuration:
   ```bash
   # Find your Pi-hole data directory (likely /opt/docker/pi-hole or similar)
   sudo nano /path/to/docker-data/pi-hole/etc-dnsmasq.d/02-local-dns.conf
   ```

3. Remove or comment out the wildcard entry:
   ```bash
   # BEFORE:
   address=/*.zinkzone.tech/192.168.86.40
   
   # AFTER (comment it out):
   # address=/*.zinkzone.tech/192.168.86.40
   ```

4. Restart Pi-hole:
   ```bash
   docker restart pihole
   ```

5. Verify the change:
   ```bash
   docker logs pihole | grep zinkzone
   ```

### Step 2: Deploy External-DNS

External-DNS will automatically create DNS records in Pi-hole for K8S services.

1. Create the Pi-hole password secret:
   ```bash
   cd src/kubernetes/infrastructure/external-dns
   cp pihole-secret.sample.yaml pihole-secret.secret.yaml
   
   # Edit and add your Pi-hole admin password
   nano pihole-secret.secret.yaml
   ```

2. Verify the Pi-hole server URL in `deployment.yaml`:
   ```bash
   # Should point to your Pi-hole container IP
   --pihole-server=http://192.168.86.40
   ```

3. Install External-DNS:
   ```bash
   ./install.sh
   ```

4. Verify it's running:
   ```bash
   kubectl logs -n external-dns -l app=external-dns -f
   ```

### Step 3: Deploy Longhorn Storage System

Longhorn provides distributed block storage with ReadWriteMany (RWX) support for shared volumes.

**Prerequisites**: `open-iscsi` must be installed on all K3S nodes (automatically handled by the K3S Ansible role).

1. Install Longhorn:
   ```bash
   cd src/kubernetes/infrastructure/longhorn
   ./install.sh
   ```

2. Wait for all Longhorn pods to be ready (this may take a few minutes):
   ```bash
   kubectl get pods -n longhorn-system
   ```

3. Verify storage classes are available:
   ```bash
   kubectl get storageclass
   ```
   Should show `longhorn` as the default storage class (local-path will be disabled).

4. Verify Longhorn UI is accessible:
   ```bash
   # Check DNS record
   dig longhorn.zinkzone.tech
   
   # Should return: 192.168.11.240 (Traefik LoadBalancer IP)
   ```
   Then access: https://longhorn.zinkzone.tech

### Step 4: Deploy Traefik Ingress Controller

Traefik will handle incoming HTTP/HTTPS traffic and request SSL certificates.

**Note**: Traefik is configured to use Longhorn storage with ReadWriteMany (RWX) access mode, allowing multiple replicas.

1. Ensure Cloudflare secret is configured:
   ```bash
   cd src/kubernetes/infrastructure/traefik
   ls -la cloudflare-secret.secret.yaml
   ```

2. Install Traefik (or upgrade if already installed):
   ```bash
   # New installation
   ./install.sh
   
   # OR upgrade existing installation to use Longhorn
   ./upgrade.sh
   ```

3. Get the LoadBalancer IP:
   ```bash
   kubectl get svc -n traefik traefik
   ```
   Should show: `192.168.11.240` (from MetalLB)

4. Verify External-DNS created the DNS record:
   ```bash
   # From your workstation or any machine using Pi-hole DNS
   dig traefik.zinkzone.tech
   
   # Should return: 192.168.11.240
   ```

5. Test Traefik dashboard:
   ```bash
   # Wait a few minutes for DNS propagation
   curl -v https://traefik.zinkzone.tech/dashboard/
   
   # First request may take 30-60 seconds while Let's Encrypt issues cert
   ```

6. Verify multiple replicas are running:
   ```bash
   kubectl get pods -n traefik
   # Should show 2 traefik pods running
   ```

### Step 5: Configure Home Service Routing (Optional)

If you want to route `home.zinkzone.tech` to your Docker Traefik instance:

1. Apply the home IngressRoute:
   ```bash
   cd src/kubernetes/infrastructure/traefik
   kubectl apply -f home-ingressroute.yaml
   ```

2. Verify DNS was created:
   ```bash
   dig home.zinkzone.tech
   # Should return: 192.168.11.240
   ```

3. Test routing:
   ```bash
   curl -v https://home.zinkzone.tech
   # Should proxy to 192.168.101.2 (your Docker Traefik)
   ```

## Troubleshooting

### Longhorn not ready

```bash
# Check Longhorn pods status
kubectl get pods -n longhorn-system

# Check Longhorn manager logs
kubectl logs -n longhorn-system -l app=longhorn-manager

# Verify storage class
kubectl get storageclass longhorn
```

### External-DNS not creating records

```bash
# Check External-DNS logs
kubectl logs -n external-dns -l app=external-dns

# Check if service has annotation
kubectl get svc -n traefik traefik -o yaml | grep external-dns
```

### DNS not resolving

```bash
# Check Pi-hole DNS records
# Go to Pi-hole web UI → Local DNS → DNS Records
# Should see: traefik.zinkzone.tech → 192.168.11.240

# Test from workstation
dig @192.168.86.40 traefik.zinkzone.tech
```

### SSL certificates not working

```bash
# Check Traefik logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# Common issues:
# 1. DNS not propagated yet (wait 5-10 minutes)
# 2. Cloudflare API token invalid
# 3. acme.json permissions incorrect (should be 600)

# Check acme.json permissions
kubectl exec -n traefik deploy/traefik -- ls -la /data/acme.json
```

## Architecture Overview

```
Internet / Home Network
         ↓
    Pi-hole DNS (192.168.86.40)
    - Managed by External-DNS
    - Records: *.zinkzone.tech → 192.168.11.240
         ↓
    MetalLB (192.168.11.240)
         ↓
    Traefik Ingress (K8S)
    - Handles HTTPS termination
    - Routes to K8S services
    - ACME certs stored on Longhorn (RWX)
    - Can proxy to external services (Docker Traefik)
         ↓
    K8S Services / Pods
         ↓
    Longhorn Storage (Distributed Block Storage)
```

## Key Files

- `external-dns/deployment.yaml` - External-DNS configuration
- `external-dns/pihole-secret.secret.yaml` - Pi-hole password (gitignored)
- `longhorn/install.sh` - Longhorn storage installation script
- `traefik/values.yaml` - Traefik Helm values with Longhorn RWX storage
- `traefik/cloudflare-secret.secret.yaml` - Cloudflare API token (gitignored)
- `traefik/middleware.yaml` - HTTPS redirect and security headers
- `traefik/home-ingressroute.yaml` - Routes to Docker Traefik
