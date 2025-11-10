# Flux GitOps

This directory contains Flux GitOps configuration for the homelab Kubernetes cluster.

## Overview

Flux continuously monitors this Git repository and automatically applies any changes to the cluster. This enables GitOps - your Git repository becomes the single source of truth for your cluster state.

## Directory Structure

```
flux/
├── bootstrap.sh           # Script to bootstrap Flux to the cluster
├── apps/                  # Application deployments (media services, etc.)
└── infrastructure/        # Infrastructure components managed by Flux
```

## Prerequisites

### 1. Install Flux CLI

**macOS:**
```bash
brew install fluxcd/tap/flux
```

**Linux:**
```bash
curl -s https://fluxcd.io/install.sh | sudo bash
```

**Verify installation:**
```bash
flux --version
```

### 2. GitHub Personal Access Token

Create a GitHub Personal Access Token (classic) with `repo` scope:

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scope: **repo** (all sub-scopes)
4. Generate and copy the token

## Bootstrap Flux

### First Time Setup

```bash
cd src/kubernetes/flux
./bootstrap.sh
```

The bootstrap script will:
1. Check prerequisites (kubectl context, Flux CLI)
2. Prompt for GitHub username and token
3. Install Flux components to the cluster
4. Configure Flux to watch this repository
5. Create the flux-system namespace and controllers

### What Gets Created

Flux bootstrap creates these components in your cluster:

- **flux-system namespace**: Contains all Flux controllers
- **source-controller**: Monitors Git repositories for changes
- **kustomize-controller**: Applies Kustomize configurations
- **helm-controller**: Manages Helm releases
- **notification-controller**: Sends notifications (optional)
- **image-reflector-controller**: Scans container registries (optional)
- **image-automation-controller**: Updates images automatically (optional)

## Verification

### Check Flux Installation

```bash
# Verify all Flux components are healthy
flux check

# View Flux pods
kubectl get pods -n flux-system

# Check Flux version
flux version
```

### View Flux Resources

```bash
# Git sources being monitored
flux get sources git

# Kustomizations being applied
flux get kustomizations

# Helm releases (if any)
flux get helmreleases
```

## How to Use Flux

### 1. Add a New Application

Create a directory in `flux/apps/` for your application:

```bash
mkdir -p flux/apps/sonarr
```

Create Kubernetes manifests or Helm releases:

**Example: Kubernetes Deployment**
```yaml
# flux/apps/sonarr/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarr
  namespace: media
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sonarr
  template:
    metadata:
      labels:
        app: sonarr
    spec:
      containers:
      - name: sonarr
        image: linuxserver/sonarr:latest
        ports:
        - containerPort: 8989
```

**Example: Helm Release**
```yaml
# flux/apps/sonarr/helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: sonarr
  namespace: media
spec:
  interval: 30m
  chart:
    spec:
      chart: sonarr
      version: '16.x'
      sourceRef:
        kind: HelmRepository
        name: k8s-at-home
        namespace: flux-system
      interval: 12h
  values:
    image:
      repository: linuxserver/sonarr
      tag: latest
```

### 2. Create a Kustomization

Tell Flux to watch and apply your app:

```yaml
# flux/apps/sonarr/kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: sonarr
  namespace: flux-system
spec:
  interval: 10m
  path: ./src/kubernetes/flux/apps/sonarr
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

### 3. Commit and Push

```bash
git add flux/apps/sonarr/
git commit -m "Add Sonarr application"
git push
```

### 4. Wait for Flux to Sync

Flux will automatically detect the changes and apply them within ~1 minute.

```bash
# Watch Flux reconciliation
flux get kustomizations --watch

# Force immediate reconciliation (optional)
flux reconcile kustomization flux-system --with-source
```

## Common Operations

### Suspend/Resume Reconciliation

```bash
# Suspend (stop syncing)
flux suspend kustomization <name>

# Resume
flux resume kustomization <name>
```

### Force Sync

```bash
# Sync all
flux reconcile kustomization flux-system --with-source

# Sync specific app
flux reconcile kustomization sonarr --with-source
```

### View Logs

```bash
# Source controller (Git sync)
kubectl logs -n flux-system deploy/source-controller -f

# Kustomize controller (apply manifests)
kubectl logs -n flux-system deploy/kustomize-controller -f

# Helm controller (Helm releases)
kubectl logs -n flux-system deploy/helm-controller -f
```

### Export Flux Configuration

```bash
# Export all Flux resources
flux export source git flux-system > flux-system-source.yaml
flux export kustomization flux-system > flux-system-kustomization.yaml
```

## Helm Repositories

To use Helm charts, add a HelmRepository:

```yaml
# flux/infrastructure/helm-repos.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: k8s-at-home
  namespace: flux-system
spec:
  interval: 1h
  url: https://k8s-at-home.com/charts/
```

Then reference it in your HelmRelease.

## Secrets Management

### SOPS (Recommended)

Flux supports encrypted secrets using Mozilla SOPS:

```bash
# Install SOPS
brew install sops

# Encrypt a secret
sops --encrypt --in-place secret.yaml

# Flux will automatically decrypt when applying
```

### Sealed Secrets

Alternative: Use Bitnami Sealed Secrets to encrypt secrets that can only be decrypted by the cluster.

## Troubleshooting

### Flux Not Syncing

```bash
# Check Flux system status
flux check

# View reconciliation status
flux get all

# Check for errors
kubectl describe kustomization <name> -n flux-system
```

### Application Not Deploying

```bash
# Check kustomization events
kubectl describe kustomization <name> -n flux-system

# View controller logs
kubectl logs -n flux-system deploy/kustomize-controller --tail=100
```

### Git Authentication Issues

```bash
# Check Git repository status
flux get sources git

# Recreate the Git secret if needed
flux create source git flux-system \
  --url=ssh://git@github.com/ZinkNotTheMetal/ansible-homelab \
  --branch=main \
  --interval=1m
```

## Uninstall Flux

⚠️ **Warning**: This will remove Flux but not the applications it deployed.

```bash
flux uninstall --namespace=flux-system
```

## Next Steps

1. **Bootstrap Flux**: Run `./bootstrap.sh`
2. **Add Helm repositories**: Create `infrastructure/helm-repos.yaml`
3. **Migrate media applications**: Move Sonarr, Radarr, etc. to `apps/`
4. **Set up secrets**: Use SOPS or Sealed Secrets for sensitive data
5. **Add monitoring**: Deploy monitoring stack via Flux

## Resources

- [Flux Documentation](https://fluxcd.io/docs/)
- [Flux GitHub](https://github.com/fluxcd/flux2)
- [Flux Best Practices](https://fluxcd.io/docs/guides/)
- [Awesome Flux](https://github.com/fluxcd/awesome-flux)
