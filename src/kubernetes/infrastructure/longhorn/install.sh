#!/bin/bash
set -e

echo "=========================================="
echo "Installing Longhorn Storage System"
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
echo "1. Creating longhorn-system namespace..."
kubectl apply -f "$(dirname "$0")/namespace.yaml"

echo ""
echo "2. Adding Longhorn Helm repository..."
helm repo add longhorn https://charts.longhorn.io
helm repo update

echo ""
echo "3. Installing Longhorn via Helm..."
helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --wait \
  --timeout 10m

echo ""
echo "4. Waiting for Longhorn to be ready..."
sleep 10
kubectl get pods -n longhorn-system

echo ""
echo "5. Setting Longhorn as default storage class..."
# Remove default from local-path
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# Set Longhorn as default
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo ""
echo "6. Creating IngressRoute for Longhorn UI (longhorn.zinkzone.tech)..."
kubectl apply -f "$(dirname "$0")/longhorn-ingressroute.yaml"

echo ""
echo "7. Creating External-DNS service for longhorn.zinkzone.tech DNS record..."
kubectl apply -f "$(dirname "$0")/longhorn-external-dns.yaml"

echo ""
echo "8. Verifying installation..."
kubectl get storageclass

echo ""
echo "=========================================="
echo "✓ Longhorn Installation Complete!"
echo "=========================================="
echo ""
echo "Longhorn provides ReadWriteMany (RWX) storage for your cluster."
echo ""
echo "Storage classes:"
kubectl get storageclass
echo ""
echo "Longhorn UI accessible at: https://longhorn.zinkzone.tech"
echo ""
echo "Next steps:"
echo "  1. Wait for all Longhorn pods to be Running"
echo "  2. Install/Upgrade Traefik with Longhorn storage for ACME certificates"
echo ""
