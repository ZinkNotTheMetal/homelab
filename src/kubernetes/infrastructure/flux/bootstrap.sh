#!/bin/bash
set -e

echo "=========================================="
echo "Bootstrapping Flux GitOps"
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
echo "This will bootstrap Flux to manage your cluster via GitOps."
echo ""
echo "Repository: git@github.com:ZinkNotTheMetal/ansible-homelab.git"
echo "Path: src/kubernetes/flux"
echo "Branch: main"
echo "Authentication: SSH"
echo ""

# Check if Flux CLI is installed
if ! command -v flux &> /dev/null; then
  echo "❌ ERROR: Flux CLI not found!"
  echo ""
  echo "Install Flux CLI:"
  echo "  macOS: brew install fluxcd/tap/flux"
  echo "  Linux: curl -s https://fluxcd.io/install.sh | sudo bash"
  echo ""
  exit 1
fi

echo "✓ Flux CLI version:"
flux --version

echo ""
echo "Checking prerequisites..."
flux check --pre

echo ""
echo "Checking SSH key..."
if [ -f ~/.ssh/id_ed25519 ]; then
  SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
  echo "✓ Found SSH key: $SSH_KEY_PATH"
elif [ -f ~/.ssh/id_rsa ]; then
  SSH_KEY_PATH="$HOME/.ssh/id_rsa"
  echo "✓ Found SSH key: $SSH_KEY_PATH"
else
  echo "❌ No default SSH key found."
  echo ""
  echo "Please specify the path to your SSH private key:"
  read -r SSH_KEY_PATH
  if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ ERROR: Key not found at $SSH_KEY_PATH"
    exit 1
  fi
fi

echo ""
echo "Verifying SSH key can access GitHub..."
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" && echo "✓ SSH authentication to GitHub works!" || echo "⚠️  Warning: Could not verify SSH access to GitHub"

echo ""
echo "⚠️  IMPORTANT: This will create a deploy key in your GitHub repository"
echo "The deploy key will have write access to the repository for Flux to commit."
echo ""
echo "After bootstrapping, you can view the deploy key at:"
echo "https://github.com/ZinkNotTheMetal/homelab/settings/keys"
echo ""
read -p "Continue with SSH bootstrap? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "Bootstrapping Flux with SSH..."
echo ""

flux bootstrap git \
  --url=ssh://git@github.com/ZinkNotTheMetal/homelab \
  --branch=main \
  --path=src/kubernetes/flux \
  --private-key-file="$SSH_KEY_PATH"

echo ""
echo "=========================================="
echo "✓ Flux Bootstrap Complete!"
echo "=========================================="
echo ""

echo "Flux has been installed and is now monitoring:"
echo "  Repository: git@github.com:ZinkNotTheMetal/homelab.git"
echo "  Path: src/kubernetes/flux"
echo "  Branch: main"
echo "  Authentication: SSH (deploy key)"
echo ""

echo "Verify Flux installation:"
echo "  flux check"
echo "  kubectl get pods -n flux-system"
echo ""

echo "View Flux status:"
echo "  flux get sources git"
echo "  flux get kustomizations"
echo ""

echo "Deploy key created in GitHub:"
echo "  https://github.com/ZinkNotTheMetal/ansible-homelab/settings/keys"
echo ""

echo "Next steps:"
echo "  1. Create application manifests in src/kubernetes/flux/apps/"
echo "  2. Commit and push to GitHub"
echo "  3. Flux will automatically sync and deploy"
echo ""
