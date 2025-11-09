#!/bin/bash
set -e

echo "=========================================="
echo "Installing External-DNS for Pi-hole"
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

# Check if secret file exists
if [[ ! -f "$(dirname "$0")/pihole-secret.secret.yaml" ]]; then
  echo ""
  echo "❌ ERROR: pihole-secret.secret.yaml not found!"
  echo ""
  echo "Please create it from the sample:"
  echo "  cp pihole-secret.sample.yaml pihole-secret.secret.yaml"
  echo "  # Then edit it and add your Pi-hole password"
  echo ""
  exit 1
fi

echo ""
echo "1. Creating external-dns namespace..."
kubectl apply -f "$(dirname "$0")/namespace.yaml"

echo ""
echo "2. Creating Pi-hole password secret..."
kubectl apply -f "$(dirname "$0")/pihole-secret.secret.yaml"

echo ""
echo "3. Deploying External-DNS..."
kubectl apply -f "$(dirname "$0")/deployment.yaml"

echo ""
echo "4. Waiting for External-DNS pod to start..."
kubectl wait --for=condition=ready pod -l app=external-dns -n external-dns --timeout=60s

echo ""
echo "5. Verifying installation..."
kubectl get pods -n external-dns

echo ""
echo "=========================================="
echo "✓ External-DNS Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Remove wildcard DNS from Pi-hole: address=/*.zinkzone.tech/192.168.86.40"
echo "  2. Restart Pi-hole: docker restart pihole"
echo "  3. Deploy services/ingresses with annotations"
echo ""
echo "Check logs:"
echo "  kubectl logs -n external-dns -l app=external-dns -f"
echo ""
