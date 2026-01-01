# Flux Applications

This directory contains all applications deployed to the homelab Kubernetes cluster via Flux GitOps.

## Application Overview

| Application | Namespace | Type | URL | Description |
|-------------|-----------|------|-----|-------------|
| [Authentik](#authentik) | `auth` | HelmRelease | https://authentik.zinkzone.tech | Identity provider and SSO |
| [FlareSolverr](#flaresolverr) | `media` | Deployment | https://flaresolverr.zinkzone.tech | Cloudflare bypass proxy |
| [Karakeep](#karakeep) | `karakeep` | Deployment | https://hoarder.zinkzone.tech | Bookmark manager (formerly Hoarder) |
| [Overseerr](#overseerr) | `media` | HelmRelease | https://overseerr.zinkzone.tech | Media request management |
| [pgAdmin](#pgadmin) | `pg-database` | HelmRelease | https://pgadmin.zinkzone.tech | PostgreSQL administration |
| [PostgreSQL (CNPG)](#postgresql-cnpg) | `pg-database` | HelmRelease | N/A (internal) | Cloud Native PostgreSQL operator |
| [Prowlarr](#prowlarr) | `media` | HelmRelease | https://prowlarr.zinkzone.tech | Indexer manager |
| [qBittorrent](#qbittorrent) | `media` | Deployment | https://qbittorrent.zinkzone.tech | Torrent client with VPN |
| [Radarr](#radarr) | `media` | HelmRelease | https://radarr.zinkzone.tech | Movie management |
| [Sonarr](#sonarr) | `media` | HelmRelease | https://sonarr.zinkzone.tech | TV show management |
| [Stirling PDF](#stirling-pdf) | `stirling-pdf` | HelmRelease | https://pdf.zinkzone.tech | PDF manipulation tools |

## Resource Summary

| Application | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage |
|-------------|-------------|-----------|----------------|--------------|---------|
| Authentik Server | 250m | 1500m | 512Mi | 3Gi | - |
| Authentik Worker | 250m | 1000m | 512Mi | 3Gi | - |
| FlareSolverr | 100m | 1000m | 256Mi | 1Gi | - |
| Karakeep | 100m | 1000m | 256Mi | 1Gi | 10Gi |
| Karakeep Meilisearch | 50m | 1000m | 256Mi | 1Gi | 5Gi |
| Karakeep Chrome | 100m | 1000m | 256Mi | 1Gi | - |
| Overseerr | 100m | 500m | 128Mi | 512Mi | 512Mi |
| pgAdmin | 100m | 1000m | 256Mi | 1Gi | 2Gi |
| Prowlarr | 100m | 500m | 256Mi | 512Mi | 1Gi |
| qBittorrent | 100m | 2000m | 256Mi | 2Gi | 1Gi + NFS |
| Radarr | 100m | 1000m | 256Mi | 1Gi | 2Gi + NFS |
| Sonarr | 100m | 1000m | 256Mi | 1Gi | 3Gi + NFS |
| Stirling PDF | 100m | 2000m | 256Mi | 2Gi | 5Gi |

---

## Application Details

### Authentik

**Identity Provider and Single Sign-On (SSO)**

- **Namespace**: `auth`
- **Type**: HelmRelease (goauthentik.io chart)
- **URL**: https://authentik.zinkzone.tech
- **Dependencies**: PostgreSQL (CNPG), Redis

Authentik provides centralized authentication and authorization for all homelab services.

**Components:**
- Server - Main authentication service
- Worker - Background task processing
- Redis - Session and cache storage (separate deployment)

**Files:**
- `authentik-release.yaml` - Main Helm release
- `redis-deployment.yaml` - Redis for session storage
- `authentik-secret.sample.yaml` - Secret template
- `ingressroute.yaml` - Traefik routing

---

### FlareSolverr

**Cloudflare Bypass Proxy**

- **Namespace**: `media`
- **Type**: Plain Deployment
- **URL**: https://flaresolverr.zinkzone.tech
- **Image**: `ghcr.io/flaresolverr/flaresolverr:latest`

Proxy server to bypass Cloudflare and DDoS-GUARD protection for Prowlarr indexers.

**Files:**
- `deployment.yaml` - FlareSolverr deployment
- `service.yaml` - ClusterIP service
- `ingressroute.yaml` - Traefik routing

See [FlareSolverr README](./flaresolverr/README.md) for detailed setup.

---

### Karakeep

**Bookmark Manager (formerly Hoarder)**

- **Namespace**: `karakeep`
- **Type**: Plain Deployment
- **URL**: https://hoarder.zinkzone.tech
- **Image**: `ghcr.io/karakeep-app/karakeep:release`

Self-hosted bookmark manager with AI-powered features, full-text search, and browser extension support.

**Components:**
- Karakeep Web - Main Next.js application
- Meilisearch - Full-text search engine
- Chrome - Headless browser for screenshots

**Files:**
- `karakeep-deployment.yaml` - Main application
- `meilisearch-deployment.yaml` - Search engine
- `chrome-deployment.yaml` - Headless browser
- `secret.sample.yaml` - Secret template
- `ingressroute.yaml` - Traefik routing

See [Karakeep README](./karakeep/README.md) for detailed setup.

---

### Overseerr

**Media Request Management**

- **Namespace**: `media`
- **Type**: HelmRelease (TrueCharts)
- **URL**: https://overseerr.zinkzone.tech
- **Image**: `linuxserver/overseerr:1.34.0`

Request management and media discovery tool for Plex. Integrates with Sonarr and Radarr.

**Files:**
- `helmrelease.yaml` - Helm release configuration
- `ingressroute.yaml` - Traefik routing

---

### pgAdmin

**PostgreSQL Administration**

- **Namespace**: `pg-database`
- **Type**: HelmRelease (runix chart)
- **URL**: https://pgadmin.zinkzone.tech

Web-based PostgreSQL administration tool for managing the CNPG cluster.

**Files:**
- `pgadmin-release.yaml` - Helm release configuration
- `pgadmin-secret.sample.yaml` - Secret template
- `ingressroute.yaml` - Traefik routing

---

### PostgreSQL (CNPG)

**Cloud Native PostgreSQL Operator**

- **Namespace**: `pg-database`
- **Type**: HelmRelease (CNPG operator)
- **Access**: Internal only (`cnpg-cluster-release-rw.pg-database.svc.cluster.local:5432`)

Manages PostgreSQL clusters for Sonarr, Radarr, Prowlarr, and Authentik.

**Files:**
- `operator-release.yaml` - CNPG operator
- `cluster-release.yaml` - PostgreSQL cluster definition

---

### Prowlarr

**Indexer Manager**

- **Namespace**: `media`
- **Type**: HelmRelease (loeken-at-home)
- **URL**: https://prowlarr.zinkzone.tech
- **Image**: `lscr.io/linuxserver/prowlarr:latest`

Indexer manager/proxy for Sonarr, Radarr, and other *arr applications.

**Files:**
- `helmrelease.yaml` - Helm release configuration
- `ingressroute.yaml` - Traefik routing
- `postgres-secret.sample.yaml` - PostgreSQL credentials template

See [Prowlarr README](./prowlarr/README.md) for detailed setup.

---

### qBittorrent

**Torrent Client with VPN**

- **Namespace**: `media`
- **Type**: Deployment with Gluetun sidecar
- **URL**: https://qbittorrent.zinkzone.tech
- **Image**: `linuxserver/qbittorrent` + `qmcgaw/gluetun`

Torrent client with all traffic routed through Private Internet Access VPN.

**Features:**
- VPN kill switch (no leaks if VPN drops)
- Automatic port forwarding
- NFS storage for downloads

**Files:**
- `deployment.yaml` - qBittorrent + Gluetun deployment
- `secret.sample.yaml` - VPN credentials template
- `ingressroute.yaml` - Traefik routing

See [qBittorrent README](./qbittorrent/README.md) for detailed setup.

---

### Radarr

**Movie Management**

- **Namespace**: `media`
- **Type**: HelmRelease (loeken-at-home)
- **URL**: https://radarr.zinkzone.tech
- **Image**: `linuxserver/radarr:5.28.0`

Movie collection manager that integrates with Prowlarr and qBittorrent.

**Features:**
- PostgreSQL backend for improved performance
- NFS mounts for downloads and media
- Integration with Prowlarr for indexers

**Files:**
- `helmrelease.yaml` - Helm release configuration
- `ingressroute.yaml` - Traefik routing

---

### Sonarr

**TV Show Management**

- **Namespace**: `media`
- **Type**: HelmRelease (loeken-at-home)
- **URL**: https://sonarr.zinkzone.tech
- **Image**: `linuxserver/sonarr:4.0.16`

TV show collection manager that integrates with Prowlarr and qBittorrent.

**Features:**
- PostgreSQL backend for improved performance
- NFS mounts for downloads and media
- Integration with Prowlarr for indexers

**Files:**
- `helmrelease.yaml` - Helm release configuration
- `ingressroute.yaml` - Traefik routing

---

### Stirling PDF

**PDF Manipulation Tools**

- **Namespace**: `stirling-pdf`
- **Type**: HelmRelease (stirling-tools chart)
- **URL**: https://pdf.zinkzone.tech
- **Image**: `stirlingtools/stirling-pdf`

Locally hosted one-stop-shop for all PDF needs including merge, split, convert, and more.

**Files:**
- `helmrelease.yaml` - Helm release configuration
- `namespace.yaml` - Dedicated namespace
- `ingressroute.yaml` - Traefik routing

---

## Deployment

All applications are deployed automatically by Flux when changes are pushed to the repository.

### Force Reconciliation

```bash
# Reconcile all applications
flux reconcile kustomization flux-system --with-source

# Check application status
flux get helmreleases -A
flux get kustomizations -A
```

### View Logs

```bash
# Flux source controller
kubectl logs -n flux-system deploy/source-controller -f

# Flux kustomize controller
kubectl logs -n flux-system deploy/kustomize-controller -f

# Flux helm controller
kubectl logs -n flux-system deploy/helm-controller -f
```

## Adding New Applications

1. Create a new directory under `apps/`
2. Add required manifests (deployment, service, ingress, etc.)
3. Create a `kustomization.yaml` listing all resources
4. Commit and push - Flux will auto-deploy

See the [Flux README](../README.md) for detailed instructions.
