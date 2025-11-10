#!/bin/bash
set -e

echo "=========================================="
echo "Installing Traefik Ingress Controller"
echo "=========================================="
echo ""

# Check if kubectl is configured
CURRENT_CONTEXT=$(kubectl config current-context)
echo "Current context: $CURRENT_CONTEXT"

if [[ "$CURRENT_CONTEXT" != "homelab-production-cluster" ]]; then
  echo ""
  echo "⚠️  WARNING: You're not on the homelab-production-cluster context!"
  echo ""
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

echo ""
echo "1. Creating traefik namespace..."
kubectl apply -f "$(dirname "$0")/namespace.yaml"

echo ""
echo "2. Creating Cloudflare API secret..."
kubectl apply -f "$(dirname "$0")/cloudflare-secret.secret.yaml"

echo ""
echo "3. Adding Traefik Helm repository..."
helm repo add traefik https://traefik.github.io/charts
helm repo update

echo ""
echo "4. Installing Traefik via Helm..."
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --values "$(dirname "$0")/values.yaml" \
  --wait \
  --timeout 5m

echo ""
echo "5. Waiting for Traefik to get LoadBalancer IP..."
sleep 10
kubectl get svc -n traefik traefik

echo ""
echo "6. Applying middleware (HTTPS redirect, security headers)..."
kubectl apply -f "$(dirname "$0")/middleware.yaml"

echo ""
echo "7. Creating Traefik dashboard IngressRoute..."
kubectl apply -f "$(dirname "$0")/dashboard-ingressroute.yaml"

echo ""
echo "8. Scaling Traefik to 2 replicas (now that ACME validation is bypassed)..."
kubectl scale deployment -n traefik traefik --replicas=2

echo ""
echo "9. Waiting for second replica to be ready..."
sleep 5
kubectl wait --namespace traefik \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=traefik \
  --timeout=120s

echo ""
echo "10. Verifying installation..."
kubectl get pods -n traefik

echo ""
echo "=========================================="
echo "✓ Traefik Installation Complete!"
echo "=========================================="
echo ""

# Get the LoadBalancer IP
TRAEFIK_IP=$(kubectl get svc -n traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Traefik LoadBalancer IP: $TRAEFIK_IP"
echo ""
echo ""
echo "Next steps:"
echo "  1. Wait 5-10 minutes for DNS to propagate"
echo "  2. Test dashboard: https://traefik.zinkzone.tech/dashboard/"
echo "  3. Run external-services as needed for all *.zinkzone.tech routing."
echo ""
echo "Note: SSL certificates will be auto-generated on first request"
echo "      (may take 30-60 seconds for first access)"
echo ""
