#!/bin/bash
set -e

echo "=========================================="
echo "Installing MetalLB LoadBalancer"
echo "=========================================="
echo ""

# Check if kubectl is configured for homelab-prod
CURRENT_CONTEXT=$(kubectl config current-context)
echo "Current context: $CURRENT_CONTEXT"

if [[ "$CURRENT_CONTEXT" != "homelab-production-cluster" ]]; then
  echo ""
  echo "⚠️  WARNING: You're not on the homelab-prod context!"
  echo "Current context: $CURRENT_CONTEXT"
  echo ""
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

echo ""
echo "1. Installing MetalLB (v0.14.8)..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml

echo ""
echo "2. Waiting for MetalLB pods to be ready (this may take 60-90 seconds)..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=120s

echo ""
echo "3. Applying IP Address Pool (192.168.11.240-250)..."
kubectl apply -f "$(dirname "$0")/namespace.yaml"
kubectl apply -f "$(dirname "$0")/ipaddresspool.yaml"

echo ""
echo "4. Verifying configuration..."
sleep 3
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system

echo ""
echo "=========================================="
echo "✓ MetalLB Installation Complete!"
echo "=========================================="
echo ""
echo "IP Pool: 192.168.11.240 - 192.168.11.250"
echo ""
echo "Next steps:"
echo "  1. Deploy Traefik (will get 192.168.11.240)"
echo "  2. Configure DNS to point *.zinkzone.tech → 192.168.11.240"
echo ""
echo "To test MetalLB:"
echo "  kubectl create deployment nginx --image=nginx"
echo "  kubectl expose deployment nginx --type=LoadBalancer --port=80"
echo "  kubectl get svc nginx  # Should show EXTERNAL-IP from the pool"
echo ""
