# Longhorn - Distributed Block Storage

Longhorn provides cloud-native distributed block storage for Kubernetes with support for ReadWriteMany (RWX) volumes.

## Features

- **Distributed Storage**: Replicates data across multiple nodes for high availability
- **ReadWriteMany (RWX)**: Shared volumes that can be mounted by multiple pods simultaneously
- **Snapshots & Backups**: Built-in backup capabilities
- **Volume Management**: Easy volume creation, deletion, and management via UI or kubectl

## Prerequisites

Longhorn requires `open-iscsi` to be installed on all K3S nodes. This is automatically installed if you used the K3S Ansible role in this repository.

If you need to install it manually:
```bash
sudo apt-get install -y open-iscsi
sudo systemctl enable iscsid
sudo systemctl start iscsid
```

## Installation

### Automated Installation

```bash
cd src/kubernetes/infrastructure/longhorn
./install.sh
```

### Manual Installation

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Add Longhorn Helm repository
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Install Longhorn
helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --wait \
  --timeout 10m
```

## Verification

### Check Installation

```bash
# Check all Longhorn pods are running
kubectl get pods -n longhorn-system

# Verify storage class
kubectl get storageclass
# Should show 'longhorn' storage class

# Check Longhorn system status
kubectl get daemonset -n longhorn-system
```

### Access Longhorn UI

```bash
# Port forward to Longhorn UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80

# Open in browser: http://localhost:8080
```

## Usage

### Creating RWX Volumes

Longhorn supports ReadWriteMany (RWX) volumes which can be shared across multiple pods:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
```

### Example: Traefik with RWX Storage

Traefik uses Longhorn RWX storage for ACME certificates, allowing multiple replicas to share the same certificate file:

```yaml
persistence:
  enabled: true
  accessMode: ReadWriteMany
  storageClass: "longhorn"
  size: 128Mi
```

## Storage Classes

Longhorn creates the following storage class:

- **longhorn**: Default Longhorn storage class
  - Supports: ReadWriteOnce (RWO) and ReadWriteMany (RWX)
  - Replication: 3 replicas (configurable)
  - Reclaim Policy: Delete

## Troubleshooting

### Pods Not Starting

```bash
# Check Longhorn manager logs
kubectl logs -n longhorn-system -l app=longhorn-manager

# Check instance manager logs
kubectl logs -n longhorn-system -l app=longhorn-instance-manager
```

### Storage Not Available

```bash
# Check node status in Longhorn
kubectl get nodes.longhorn.io -n longhorn-system

# Verify disks are attached
kubectl describe nodes.longhorn.io -n longhorn-system
```

### Volume Mount Issues

```bash
# Check PVC status
kubectl get pvc

# Describe PVC for events
kubectl describe pvc <pvc-name>

# Check volume status in Longhorn
kubectl get volumes.longhorn.io -n longhorn-system
```

## Configuration

### Node Storage

By default, Longhorn uses `/var/lib/longhorn` on each node for storage.

### Replica Settings

Default: 3 replicas per volume (configured in Longhorn settings)

To change replica count for a specific volume:
```bash
kubectl edit volume.longhorn.io/<volume-name> -n longhorn-system
```

## Uninstall

```bash
# Uninstall Longhorn via Helm
helm uninstall longhorn -n longhorn-system

# Clean up CRDs (optional, will delete all Longhorn data)
kubectl delete crd $(kubectl get crd | grep longhorn.io | awk '{print $1}')

# Remove namespace
kubectl delete namespace longhorn-system
```

⚠️ **Warning**: Uninstalling Longhorn will delete all volumes and data!

## References

- [Longhorn Documentation](https://longhorn.io/docs/)
- [Longhorn GitHub](https://github.com/longhorn/longhorn)
- [ReadWriteMany Volumes](https://longhorn.io/docs/latest/advanced-resources/rwx-workloads/)
