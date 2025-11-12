# qBittorrent with Gluetun VPN

qBittorrent download client with Gluetun VPN sidecar for Private Internet Access.

## Features

- **qBittorrent**: Modern torrent client with excellent WebUI
- **Gluetun VPN**: All traffic routed through PIA VPN
- **Port Forwarding**: Gluetun handles PIA port forwarding automatically
- **Kill Switch**: If VPN drops, qBittorrent loses internet access
- **NFS Storage**: Downloads and media on shared NFS mount

## Setup

### 1. Create PIA Credentials Secret

**Option A: Manually create the secret**
```bash
kubectl create secret generic qbittorrent-vpn -n media \
  --from-literal=VPN_USER='your-pia-username' \
  --from-literal=VPN_PASSWORD='your-pia-password'
```

**Option B: Use the secret file (not recommended for git)**
```bash
# Copy the sample and edit with your credentials
cp secret.sample.yaml secret.yaml
# Edit secret.yaml with your PIA username and password
# Apply it
kubectl apply -f secret.yaml
# Add secret.yaml to .gitignore!
```

### 2. Update HelmRelease

Edit `helmrelease.yaml` and update the Gluetun environment variables:
- Replace `OPENVPN_USER` and `OPENVPN_PASSWORD` with references to the secret, OR
- Use the secret directly in the env section

Current config uses plain text - **change this to use the secret!**

### 3. Deploy

```bash
git add .
git commit -m "Add qBittorrent with Gluetun VPN"
git push
```

Flux will automatically deploy.

## Configuration

### VPN Settings

- **Provider**: Private Internet Access (PIA)
- **Protocol**: OpenVPN
- **Region**: US East (change in helmrelease.yaml)
- **Port Forwarding**: Automatic

### Storage

- **Config**: 1Gi on Longhorn (`/config`)
- **Downloads**: Shared NFS mount (`/downloads`)
- **Media**: Shared NFS mount (`/media`)

### Access

- **URL**: https://qbittorrent.zinkzone.tech
- **Default Credentials**: admin / adminadmin (change immediately!)

### Post-Deploy Configuration

1. Access qBittorrent WebUI
2. Change default password
3. Configure download paths:
   - Default: `/downloads`
   - Completed: `/media/Movies` or `/media/TV Shows`
4. Set up categories for Sonarr/Radarr integration

## Integration with Sonarr/Radarr

In Sonarr/Radarr settings:
1. Go to Settings → Download Clients
2. Add qBittorrent
3. Host: `qbittorrent` (service name)
4. Port: `8080`
5. Category: `tv` (Sonarr) or `movies` (Radarr)
6. Remote Path Mappings: `/downloads` → `/downloads`

## Troubleshooting

### Check VPN Connection
```bash
# Get pod name
kubectl get pods -n media -l app.kubernetes.io/name=qbittorrent

# Check Gluetun logs
kubectl logs -n media <pod-name> -c gluetun

# Check public IP (should be PIA IP, not your home IP)
kubectl exec -n media <pod-name> -c gluetun -- wget -qO- ifconfig.me
```

### Check qBittorrent Logs
```bash
kubectl logs -n media <pod-name> -c qbittorrent
```

## Security Notes

- qBittorrent traffic is forced through VPN (kill switch enabled)
- Firewall configured to only allow k8s cluster communication + VPN
- Credentials should be stored in Kubernetes secrets, not plain text
- Consider using Sealed Secrets or External Secrets Operator for GitOps
