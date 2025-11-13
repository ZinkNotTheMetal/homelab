# CPU Resource Management

This document outlines the CPU resource limits and requests configured for applications in this Kubernetes cluster.

## Resource Allocation Strategy

### High-Priority Applications
- **PostgreSQL Cluster**: 3 instances × 1000m CPU limit (3 cores total)
  - Database workloads require consistent CPU performance
  - Memory-intensive operations during queries and indexing
  
- **qBittorrent**: 1500m CPU limit
  - Reduced from 2500m to optimize cluster resources
  - Handles torrent processing and VPN overhead

### Medium-Priority Applications  
- **Radarr/Sonarr**: 1500m CPU limit each
  - Media processing and library scanning can be CPU intensive
  - Startup spikes require additional headroom

- **FlareSolverr**: 2000m CPU limit
  - Browser automation for CAPTCHA solving
  - High CPU usage during active solving operations

### Standard Applications
- **Overseerr/Prowlarr**: 500m CPU limit each
  - Web-based request management and indexers
  - Light to moderate CPU usage

- **pgAdmin**: 500m CPU limit
  - Database management interface
  - Primarily serves web UI and queries

- **Traefik**: 500m CPU limit
  - Ingress controller and reverse proxy
  - Handles SSL termination and routing

## Resource Management Guidelines

1. **Requests vs Limits**: All applications now have both CPU requests and limits defined
2. **Burst Capacity**: Limits provide 2-5x headroom over requests for handling spikes
3. **Cluster Balance**: Total CPU allocation should not exceed cluster capacity by more than 80%

## Monitoring Recommendations

- Monitor CPU throttling metrics: `container_cpu_cfs_throttled_seconds_total`
- Set up alerts for sustained CPU usage > 80% of limits
- Review resource usage monthly and adjust as needed

## Changes Made (feat/managing-cpu-limits)

- Added CPU limits to PostgreSQL cluster (previously unbounded)
- Added resource limits to pgAdmin (previously undefined)
- Optimized qBittorrent CPU limits from 2500m to 1500m
- Standardized resource documentation across all applications