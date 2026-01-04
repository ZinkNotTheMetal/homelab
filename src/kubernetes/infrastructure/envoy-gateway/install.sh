#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "Installing Envoy Gateway with cert-manager"
echo "=========================================="
echo ""

# Check if kubectl is configured
CURRENT_CONTEXT=$(kubectl config current-context)
echo "Current context: $CURRENT_CONTEXT"

if [[ "$CURRENT_CONTEXT" != "homelab-production-cluster" ]]; then
  echo ""
  echo "WARNING: You're not on the homelab-production-cluster context!"
  echo ""
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Check for required secret file
if [[ ! -f "$SCRIPT_DIR/cloudflare-secret.secret.yaml" ]]; then
  echo ""
  echo "ERROR: cloudflare-secret.secret.yaml not found!"
  echo ""
  echo "Create it from the sample:"
  echo "  cp $SCRIPT_DIR/cloudflare-secret.sample.yaml $SCRIPT_DIR/cloudflare-secret.secret.yaml"
  echo "  # Edit the file with your Cloudflare API token"
  exit 1
fi

echo ""
echo "Step 1/10: Creating namespaces..."
kubectl apply -f "$SCRIPT_DIR/namespace.yaml"

echo ""
echo "Step 2/10: Applying Cloudflare API secret..."
kubectl apply -f "$SCRIPT_DIR/cloudflare-secret.secret.yaml"

echo ""
echo "Step 3/10: Adding Helm repositories..."
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update

echo ""
echo "Step 4/10: Installing cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.17.2 \
  --set crds.enabled=true \
  --set crds.keep=true \
  --set dns01RecursiveNameserversOnly=true \
  --set "dns01RecursiveNameservers=1.1.1.1:53\,8.8.8.8:53" \
  --set config.enableGatewayAPI=true \
  --wait \
  --timeout 5m

echo ""
echo "Step 5/10: Waiting for cert-manager webhook to be ready..."
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=webhook \
  --timeout=120s

echo ""
echo "Step 6/10: Creating ClusterIssuers..."
kubectl apply -f "$SCRIPT_DIR/cluster-issuer.yaml"

echo ""
echo "Step 7/10: Installing Envoy Gateway..."
helm upgrade --install envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
  --namespace envoy-gateway-system \
  --version v1.6.1 \
  --wait \
  --timeout 5m

echo ""
echo "Step 8/10: Waiting for Envoy Gateway to be ready..."
kubectl wait --namespace envoy-gateway-system \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=envoy-gateway \
  --timeout=120s

echo ""
echo "Step 9/10: Creating Gateway and wildcard certificate..."
kubectl apply -f "$SCRIPT_DIR/gateway.yaml"
kubectl apply -f "$SCRIPT_DIR/wildcard-certificate.yaml"

echo ""
echo "Step 10/10: Creating external service routes..."
kubectl apply -f "$SCRIPT_DIR/external-services.yaml"

echo ""
echo "Waiting for certificate to be issued (this may take 1-2 minutes)..."
echo "Checking certificate status..."

# Wait for certificate with timeout
TIMEOUT=180
ELAPSED=0
while [[ $ELAPSED -lt $TIMEOUT ]]; do
  CERT_READY=$(kubectl get certificate wildcard-zinkzone-tech -n envoy-gateway-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
  if [[ "$CERT_READY" == "True" ]]; then
    echo "Certificate is ready!"
    break
  fi
  echo "  Certificate status: $CERT_READY (waiting...)"
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

if [[ "$CERT_READY" != "True" ]]; then
  echo ""
  echo "WARNING: Certificate not ready after ${TIMEOUT}s"
  echo "Check status with: kubectl describe certificate wildcard-zinkzone-tech -n envoy-gateway-system"
  echo ""
fi

echo ""
echo "=========================================="
echo "Envoy Gateway Installation Complete!"
echo "=========================================="
echo ""

# Get the Gateway IP
GATEWAY_IP=$(kubectl get gateway homelab-gateway -n envoy-gateway-system -o jsonpath='{.status.addresses[0].value}' 2>/dev/null || echo "Pending")
echo "Gateway LoadBalancer IP: $GATEWAY_IP"
echo ""

echo "Installed components:"
echo "  - cert-manager (namespace: cert-manager)"
echo "  - Envoy Gateway (namespace: envoy-gateway-system)"
echo "  - ClusterIssuer: letsencrypt-production, letsencrypt-staging"
echo "  - Gateway: homelab-gateway"
echo "  - Wildcard Certificate: *.zinkzone.tech"
echo ""

echo "HTTPRoutes created:"
kubectl get httproute -n envoy-gateway-system --no-headers 2>/dev/null | awk '{print "  - " $1}' || echo "  (none yet)"
echo ""

echo "Next steps:"
echo "  1. Verify certificate: kubectl get certificate -n envoy-gateway-system"
echo "  2. Check Gateway IP is assigned: kubectl get gateway -n envoy-gateway-system"
echo "  3. Update External-DNS: kubectl apply -f ../external-dns/deployment.yaml"
echo "  4. Test access: curl -v https://grafana.zinkzone.tech"
echo ""
echo "App HTTPRoutes are managed by Flux in flux/apps/<app>/httproute.yaml"
echo ""
