# CPU Resource Management

This document outlines the CPU resource limits and requests configured for applications in this Kubernetes cluster.

## Cluster Configuration

- **Total Nodes**: 3 (1 control plane, 2 workers)
- **Worker CPU Capacity**: 8 cores (2 nodes × 4 cores)
- **Total CPU Limits**: 7500m (7.5 cores)
- **Utilization**: 93.75% of capacity
- **Headroom**: 500m (0.5 cores) for system overhead

## Resource Allocation Strategy

### Database Applications
- **PostgreSQL Cluster**: 3 instances × 500m = 1500m (1.5 cores total)
  - Optimized for homelab usage with light database load
  - Suitable for multiple applications with light query patterns
  - Requests: 100m per instance (300m total)
  
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

- **FlareSolverr**: 1000m CPU limit (1.0 core)
  - Browser automation for CAPTCHA solving
  - Chromium-based, CPU intensive during active solving
  - Requests: 100m

### Standard Applications
- **Overseerr**: 500m CPU limit
  - Media request management
  - Web-based interface with light processing
  - Requests: 100m

- **Prowlarr**: 500m CPU limit
  - Indexer manager for media automation
  - Light to moderate CPU usage
  - Requests: 100m

- **Traefik**: 500m CPU limit
  - Ingress controller and reverse proxy
  - Handles SSL termination and routing
  - Requests: 100m

## Resource Management Guidelines

1. **Requests vs Limits**: All applications have both CPU requests and limits defined
   - Total Requests: 1350m (1.35 cores) - guaranteed minimum
   - Total Limits: 7500m (7.5 cores) - maximum burst capacity
   - Burst Ratio: 5.6x - excellent headroom for simultaneous spikes

2. **Cluster Balance**: Optimized for 8-core worker capacity
   - 93.75% utilization provides balanced resource allocation
   - 500m headroom for Kubernetes system components

3. **Homelab Optimization**: Limits tuned for homelab usage patterns
   - PostgreSQL: Light database load across multiple apps
   - Media apps: Periodic scanning and processing
   - Most apps idle or low CPU usage majority of time

## Monitoring Recommendations

- Monitor CPU throttling metrics: `container_cpu_cfs_throttled_seconds_total`
- Set up alerts for sustained CPU usage > 80% of limits
- Review resource usage monthly and adjust as needed
- Watch for PostgreSQL query performance - increase limits if needed

## Changes Made (feat/managing-cpu-limits)

**Initial Changes:**
- Added CPU limits to PostgreSQL cluster (previously unbounded)
- Added resource limits to pgAdmin (previously undefined)
- Optimized qBittorrent CPU limits from 2500m to 1500m
- Standardized resource documentation across all applications

**Homelab Optimization Pass:**
- Reduced PostgreSQL limits from 3000m to 1500m (3×500m) for light homelab usage
- Reduced FlareSolverr from 2000m to 1000m
- Reduced Radarr from 1500m to 1000m
- Reduced Sonarr from 1500m to 1000m
- Final total: 7500m (fits within 8-core capacity with headroom)