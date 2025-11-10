# Prowlarr

Prowlarr is an indexer manager/proxy for Sonarr, Radarr, Lidarr, and other *arr applications.

## Deployment Details

- **Namespace**: `media`
- **Chart**: `k8s-at-home/prowlarr` (version 4.x)
- **Image**: `lscr.io/linuxserver/prowlarr:latest`
- **URL**: https://prowlarr.zinkzone.tech

## Configuration

### Storage
- **Config Volume**: 1Gi PVC on Longhorn (RWO)
- **Storage Class**: `longhorn`
- **Retention**: Enabled (data persists if HelmRelease is deleted)

### Resources
- **Requests**: 100m CPU, 256Mi Memory
- **Limits**: 500m CPU, 512Mi Memory

### Environment Variables
- **TZ**: America/New_York (change in `helmrelease.yaml`)
- **PUID**: 1000
- **PGID**: 1000

## Access

- **Internal**: `http://prowlarr.media.svc.cluster.local:9696`
- **External**: https://prowlarr.zinkzone.tech

## DNS

External-DNS automatically creates: `prowlarr.zinkzone.tech` → `traefik.zinkzone.tech` (CNAME)

## Files

- `helmrelease.yaml` - Helm chart deployment configuration
- `ingressroute.yaml` - Traefik routing and External-DNS configuration
- `kustomization.yaml` - Kustomize resource list

**Note**: The `media` namespace is defined centrally in `/flux/namespaces/media.yaml`

## Deployment

After committing and pushing to Git, Flux will automatically deploy Prowlarr within ~1 minute.

### Manual Deployment (if needed)

```bash
# Apply manually
kubectl apply -k src/kubernetes/flux/apps/prowlarr/

# Force Flux reconciliation
flux reconcile kustomization flux-system --with-source
```

### Verify Deployment

```bash
# Check HelmRelease status
flux get helmreleases -n media

# Check pods
kubectl get pods -n media

# Check PVC
kubectl get pvc -n media

# Check IngressRoute
kubectl get ingressroute -n media

# Check DNS record
dig prowlarr.zinkzone.tech
```

## Initial Setup

1. Access https://prowlarr.zinkzone.tech
2. Complete the initial setup wizard
3. Add indexers
4. Configure Sonarr/Radarr/etc. to use Prowlarr

## Troubleshooting

### Pod not starting

```bash
# Check pod logs
kubectl logs -n media -l app.kubernetes.io/name=prowlarr

# Describe pod for events
kubectl describe pod -n media -l app.kubernetes.io/name=prowlarr
```

### Can't access via DNS

```bash
# Check External-DNS logs
kubectl logs -n external-dns -l app=external-dns --tail=50 | grep prowlarr

# Check IngressRoute
kubectl describe ingressroute prowlarr -n media

# Check Traefik routes
kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=50 | grep prowlarr
```

### PVC issues

```bash
# Check PVC status
kubectl describe pvc -n media

# Check Longhorn volumes
kubectl get volumes.longhorn.io -n longhorn-system
```

## Updating

Flux will automatically update Prowlarr when the `tag: latest` image changes (if image automation is enabled).

To change the version manually, edit `helmrelease.yaml`:

```yaml
image:
  tag: "1.10.5"  # Pin to specific version
```

Then commit and push.

## Uninstalling

Delete the app directory from Git, or:

```bash
kubectl delete -k src/kubernetes/flux/apps/prowlarr/
```

**Note**: The PVC will be retained due to `retain: true` in the HelmRelease. Delete manually if needed:

```bash
kubectl delete pvc -n media prowlarr-config
```
