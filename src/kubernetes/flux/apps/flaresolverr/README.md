# FlareSolverr

FlareSolverr is a proxy server to bypass Cloudflare and DDoS-GUARD protection for web scraping applications like Prowlarr.

## Deployment Details

- **Namespace**: `media`
- **Type**: Plain Kubernetes Deployment (no Helm)
- **Image**: `ghcr.io/flaresolverr/flaresolverr:latest`
- **URL**: https://flaresolverr.zinkzone.tech

## Configuration

### Stateless Application
FlareSolverr is stateless and does not require persistent storage.

### Resources
- **Requests**: 100m CPU, 256Mi Memory
- **Limits**: 1000m CPU, 1Gi Memory

**Note**: FlareSolverr uses Chromium internally which can be resource-intensive, especially under load.

### Environment Variables
- **LOG_LEVEL**: info
- **LOG_HTML**: false (don't log full HTML responses)
- **CAPTCHA_SOLVER**: none (no automatic CAPTCHA solving)
- **TZ**: America/New_York

## Access

- **Internal (for Prowlarr)**: `http://flaresolverr.media.svc.cluster.local:8191`
- **External**: https://flaresolverr.zinkzone.tech

## DNS

External-DNS automatically creates: `flaresolverr.zinkzone.tech` → `traefik.zinkzone.tech` (CNAME)

## Files

- `deployment.yaml` - FlareSolverr deployment configuration
- `service.yaml` - ClusterIP service for internal access
- `ingressroute.yaml` - Traefik routing and External-DNS configuration
- `kustomization.yaml` - Kustomize resource list

## Integration with Prowlarr

In Prowlarr, configure FlareSolverr:

1. Go to Settings → Indexers
2. Click "FlareSolverr" under "Indexer Proxies"
3. Add FlareSolverr:
   - **Tags**: Create a tag (e.g., "flaresolverr")
   - **Host**: `http://flaresolverr.media.svc.cluster.local:8191`
4. Apply the tag to indexers that need Cloudflare bypass

## Deployment

After committing and pushing to Git, Flux will automatically deploy FlareSolverr within ~1 minute.

### Verify Deployment

```bash
# Check deployment
kubectl get deployment -n media flaresolverr

# Check pods
kubectl get pods -n media -l app=flaresolverr

# Check service
kubectl get svc -n media flaresolverr

# Check IngressRoute
kubectl get ingressroute -n media flaresolverr

# Check DNS record
dig flaresolverr.zinkzone.tech
```

### Test FlareSolverr

```bash
# Test from within the cluster
kubectl run -it --rm test-flaresolverr --image=curlimages/curl --restart=Never -n media -- \
  curl -L -X POST http://flaresolverr:8191/v1 \
  -H 'Content-Type: application/json' \
  -d '{"cmd": "request.get", "url": "http://www.google.com/"}'

# Or test via external URL
curl https://flaresolverr.zinkzone.tech/
```

## Troubleshooting

### Pod not starting

```bash
# Check pod logs
kubectl logs -n media -l app=flaresolverr

# Describe pod for events
kubectl describe pod -n media -l app=flaresolverr
```

### High memory usage

FlareSolverr runs Chromium which can use significant memory. If you see OOMKilled events:

1. Increase memory limits in `deployment.yaml`
2. Or reduce concurrent requests to FlareSolverr

### Can't access via DNS

```bash
# Check External-DNS logs
kubectl logs -n external-dns -l app=external-dns --tail=50 | grep flaresolverr

# Check IngressRoute
kubectl describe ingressroute flaresolverr -n media
```

## Performance Notes

- FlareSolverr can be slow (5-10 seconds per request) as it runs a full browser
- Only use for indexers that actually need Cloudflare bypass
- Consider increasing replicas if you have many protected indexers:
  ```yaml
  spec:
    replicas: 2  # Increase for better performance
  ```

## Updating

To update FlareSolverr, edit `deployment.yaml` and change the image tag, then commit and push.

## Uninstalling

Delete the app directory from Git, or:

```bash
kubectl delete -k src/kubernetes/flux/apps/flaresolverr/
```
