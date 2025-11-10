# MetalLB - LoadBalancer for K3S

MetalLB provides LoadBalancer IPs for services in your K3S cluster.

## Configuration

**IP Pool:** 192.168.11.240 - 192.168.11.250 (11 IPs)

This range is:
- Outside the DHCP range (192.168.10.11 - 192.168.10.239)
- On the same /23 subnet as the cluster nodes
- Reserved in UniFi for static assignment

## Installation

### 1. Install MetalLB via Manifest

```bash
# Install MetalLB native (recommended)
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml

# Wait for pods to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

### 2. Apply IP Pool Configuration

```bash
# Apply namespace (if not already exists)
kubectl apply -f namespace.yaml

# Apply IP pool and L2 advertisement
kubectl apply -f ipaddresspool.yaml
```

### 3. Verify Installation

```bash
# Check MetalLB pods
kubectl get pods -n metallb-system

# Check IP pool configuration
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system

# Should see:
# NAME            AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
# homelab-pool    true          false             ["192.168.11.240-192.168.11.250"]
```

## Testing

Create a test LoadBalancer service:

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=LoadBalancer --port=80

# Check the external IP (should be from the pool)
kubectl get svc nginx

# Should show:
# NAME    TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE
# nginx   LoadBalancer   10.43.xxx.xxx   192.168.11.240    80:xxxxx/TCP   10s

# Test from your network
curl http://192.168.11.240

# Cleanup
kubectl delete svc nginx
kubectl delete deployment nginx
```

## IP Allocation

MetalLB will assign IPs in order:
- **192.168.11.240** - First service (likely Traefik)
- **192.168.11.241** - Second service
- **192.168.11.242-250** - Future services

## Troubleshooting

### No IP Assigned (Stuck on Pending)

```bash
# Check speaker logs
kubectl logs -n metallb-system -l component=speaker

# Check controller logs
kubectl logs -n metallb-system -l component=controller
```

### ARP Issues

```bash
# Verify L2 advertisement
kubectl describe l2advertisement -n metallb-system homelab-l2

# Check if nodes can reach the gateway
kubectl exec -it <pod> -- ping 192.168.10.1
```

### IP Already in Use

If you see "IP already in use" errors:
1. Check UniFi DHCP range doesn't overlap
2. Verify no static IPs are using 192.168.11.240-250
3. Check for duplicate MetalLB installations

## Uninstall

```bash
# Remove IP pool configuration
kubectl delete -f ipaddresspool.yaml

# Uninstall MetalLB
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
```

## References

- [MetalLB Documentation](https://metallb.universe.tf/)
- [MetalLB Configuration](https://metallb.universe.tf/configuration/)
- [L2 Mode](https://metallb.universe.tf/concepts/layer2/)
