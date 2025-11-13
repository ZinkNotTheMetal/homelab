# CPU Resource Management

This document outlines the CPU resource limits and requests configured for applications in this Kubernetes cluster.

## Cluster Configuration

- **Total Nodes**: 3 (1 control plane, 2 workers)
- **Control Plane CPU**: 2 cores (reduced from 3, usage ~0.58 cores)
- **Worker CPU Capacity**: 8 cores (2 nodes × 4 cores)
- **Total CPU Limits**: 7500m (7.5 cores)
- **Utilization**: 93.75% of capacity
- **Headroom**: 500m (0.5 cores) for system overhead

## Resource Allocation Strategy

### Database Applications
- **PostgreSQL**: 1 instance × 500m = 500m (0.5 cores)
  - Single instance for homelab simplicity
  - No HA needed for homelab use case
  - Adequate for light database load across multiple apps
  - Requests: 100m
  
- **pgAdmin**: 500m CPU limit
  - Database management interface
  - Light usage for administrative tasks
  - Requests: 100m

### Media Management Applications
- **qBittorrent**: 1500m CPU limit (1.5 cores)
  - Torrent processing and VPN overhead
  - Includes Gluetun VPN sidecar (500m)
  - Requests: 250m (qBittorrent) + 100m (VPN)

- **Radarr/Sonarr**: 1000m CPU limit each (1.0 core each)
  - Media library management and processing
  - Handles library scanning and metadata updates
  - Startup spikes accommodated within limits
  - Requests: 100m each

- **FlareSolverr**: 2000m CPU limit (2.0 cores)
  - Browser automation for CAPTCHA solving
  - Chromium-based, heavily utilized during indexer operations
  - Increased from 1000m to address slowdown issues
  - Critical for Prowlarr indexer functionality
  - Requests: 100m

### Standard Applications
- **Overseerr**: 500m CPU limit
  - Media request management
  - Web-based interface with light processing
  - Requests: 100m

- **Prowlarr**: 500m CPU limit
  - Indexer manager for media automation
  - Relies on FlareSolverr for CAPTCHA solving
  - Requests: 100m

- **Traefik**: 500m CPU limit
  - Ingress controller and reverse proxy
  - Handles SSL termination and routing
  - Requests: 100m

## Resource Management Guidelines

1. **Requests vs Limits**: All applications have both CPU requests and limits defined
   - Total Requests: 1150m (1.15 cores) - guaranteed minimum
   - Total Limits: 7500m (7.5 cores) - maximum burst capacity
   - Burst Ratio: 6.5x - excellent headroom for simultaneous spikes

2. **Cluster Balance**: Optimized for 8-core worker capacity
   - 93.75% utilization provides balanced resource allocation
   - 500m headroom for Kubernetes system components (Flux, Longhorn, MetalLB, CoreDNS)

3. **Control Plane**: Reduced from 3 to 2 cores
   - Actual usage: ~0.58 cores (29% of 2-core capacity)
   - Still comfortable headroom for control plane operations
   - Eliminates over-allocation warnings

4. **Homelab Optimization**: Limits tuned for homelab usage patterns
   - PostgreSQL: Single instance, light database load
   - FlareSolverr: Heavy usage, critical for media automation
   - Media apps: Periodic scanning and processing
   - Most apps idle or low CPU usage majority of time

## Monitoring Recommendations

- Monitor CPU throttling metrics: `container_cpu_cfs_throttled_seconds_total`
- Set up alerts for sustained CPU usage > 80% of limits
- Review resource usage monthly and adjust as needed
- Watch FlareSolverr performance after increase to 2000m
- Monitor PostgreSQL with single instance for any performance issues
- Verify control plane stability at 2 cores

## Changes Made (feat/optimize-cluster-resources)

**Infrastructure Changes:**
- Reduced control plane from 3 to 2 CPU cores
  - Addresses over-allocation on control plane node
  - Actual usage ~0.58 cores leaves comfortable headroom
  - Requires VM recreation (downtime expected)

**Application Changes:**
- Reduced PostgreSQL from 3 instances to 1 instance
  - Simplifies operations for homelab use case
  - Saves 1000m CPU (1500m → 500m)
  - No HA needed for homelab

- Increased FlareSolverr from 1000m to 2000m
  - Addresses slowdown issues during heavy CAPTCHA solving
  - Critical for Prowlarr indexer functionality
  - Doubles CPU capacity for browser automation

**Net Result:**
- Application CPU limits remain at 7500m (PostgreSQL -1000m, FlareSolverr +1000m)
- Control plane freed from over-allocation
- Improved performance for critical FlareSolverr component