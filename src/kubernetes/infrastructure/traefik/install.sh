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
echo "7. Verifying installation..."
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
echo "Next steps:"
echo "  1. Update DNS: Point *.zinkzone.tech → $TRAEFIK_IP"
echo "  2. Wait 5-10 minutes for DNS to propagate"
echo "  3. Test SSL: curl https://traefik.zinkzone.tech/dashboard/"
echo "  4. Once SSL works, configure home.zinkzone.tech routing"
echo ""
echo "Note: SSL certificates will be auto-generated on first request"
echo "      (may take 30-60 seconds for first access)"
echo ""
echo "Home IngressRoute setup skipped - apply manually when ready:"
echo "  kubectl apply -f $(dirname "$0")/home-ingressroute.yaml"
echo ""
