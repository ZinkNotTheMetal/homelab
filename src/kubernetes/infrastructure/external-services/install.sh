#!/bin/bash
set -e

echo "=========================================="
echo "Installing External Service Routes"
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
echo "This will configure routes for external services:"
echo "  - nas.zinkzone.tech → 192.168.1.197:5000 (Synology NAS)"
echo "  - home.zinkzone.tech → 192.168.101.2:8123 (Home Assistant)"
echo ""

echo ""
echo "1. Verifying Traefik is installed..."
if ! kubectl get namespace traefik &> /dev/null; then
  echo "❌ ERROR: Traefik namespace not found!"
  echo "Please install Traefik first: cd ../traefik && ./install.sh"
  exit 1
fi
echo "✓ Traefik namespace found"

echo ""
echo "2. Creating External-DNS services for DNS records..."
kubectl apply -f "$(dirname "$0")/nas-external-dns.yaml"
kubectl apply -f "$(dirname "$0")/home-external-dns.yaml"

echo ""
echo "3. Creating IngressRoutes for external services..."
kubectl apply -f "$(dirname "$0")/nas-ingressroute.yaml"
kubectl apply -f "$(dirname "$0")/home-ingressroute.yaml"

echo ""
echo "4. Verifying IngressRoutes..."
kubectl get ingressroute -n traefik

echo ""
echo "5. Checking External-DNS services..."
kubectl get svc -n traefik | grep external-dns

echo ""
echo "=========================================="
echo "✓ External Services Configuration Complete!"
echo "=========================================="
echo ""

echo "DNS Records (will be created by External-DNS within 1-2 minutes):"
echo "  - nas.zinkzone.tech → CNAME → traefik.zinkzone.tech"
echo "  - home.zinkzone.tech → CNAME → traefik.zinkzone.tech"
echo ""

echo "Available Routes:"
echo "  - Synology NAS: https://nas.zinkzone.tech"
echo "  - Home Assistant: https://home.zinkzone.tech"
echo ""

echo "Verify DNS propagation:"
echo "  dig nas.zinkzone.tech"
echo "  dig home.zinkzone.tech"
echo ""

echo "Check External-DNS logs to confirm record creation:"
echo "  kubectl logs -n external-dns -l app=external-dns --tail=20"
echo ""
