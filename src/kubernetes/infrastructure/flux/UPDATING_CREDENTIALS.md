# Updating Flux Credentials

This document explains how to update Flux's Git authentication credentials when your SSH key changes, expires, or needs to be revoked.

## When You Need This

- Your SSH key has been compromised and needs to be rotated
- You want to use a different SSH key for Flux
- The GitHub deploy key needs to be regenerated
- You're migrating to a different authentication method

## Understanding Flux Authentication

Flux uses SSH key authentication to access your Git repository. When you bootstrap Flux, it creates:

1. **A Kubernetes Secret** (`flux-system` in `flux-system` namespace) containing the SSH private key
2. **A GitHub Deploy Key** (visible at https://github.com/ZinkNotTheMetal/ansible-homelab/settings/keys)

## Method 1: Update the SSH Key (Recommended)

### Step 1: Generate a New SSH Key (Optional)

If you need a new key pair:

```bash
# Generate a new SSH key
ssh-keygen -t ed25519 -C "flux-homelab" -f ~/.ssh/flux-homelab

# This creates:
# ~/.ssh/flux-homelab (private key)
# ~/.ssh/flux-homelab.pub (public key)
```

Or use your existing SSH key.

### Step 2: Delete the Old Flux Secret

```bash
# Delete the existing Flux Git authentication secret
kubectl delete secret flux-system -n flux-system
```

### Step 3: Create a New Secret with Your SSH Key

```bash
# Create a new secret with your SSH private key
flux create secret git flux-system \
  --url=ssh://git@github.com/ZinkNotTheMetal/homelab \
  --namespace=flux-system \
  --private-key-file=~/.ssh/id_ed25519
```

Or if using a specific key:

```bash
flux create secret git flux-system \
  --url=ssh://git@github.com/ZinkNotTheMetal/homelab \
  --namespace=flux-system \
  --private-key-file=~/.ssh/flux-homelab
```

### Step 4: Update the GitHub Deploy Key

1. Go to your repository's deploy keys:
   - https://github.com/ZinkNotTheMetal/homelab/settings/keys

2. Delete the old deploy key (usually named `flux-system-main-flux-system`)

3. Add the new public key:
   - Click "Add deploy key"
   - Title: `flux-system` (or descriptive name)
   - Key: Paste the contents of your public key
     ```bash
     cat ~/.ssh/id_ed25519.pub
     # or
     cat ~/.ssh/flux-homelab.pub
     ```
   - ✅ Allow write access (required for Flux to commit)
   - Click "Add key"

### Step 5: Reconcile Flux

Force Flux to reconnect with the new credentials:

```bash
# Reconcile the Git source
flux reconcile source git flux-system

# If successful, you should see:
# ► annotating GitRepository flux-system in flux-system namespace
# ✔ GitRepository annotated
# ◎ waiting for GitRepository reconciliation
# ✔ GitRepository reconciliation completed
# ✔ fetched revision main@sha1:xxxxx
```

### Step 6: Verify

```bash
# Check the Git source status
flux get sources git

# Should show READY as True:
# NAME         REVISION        SUSPENDED  READY  MESSAGE
# flux-system  main@sha1:xxxxx False      True   stored artifact for revision 'main@sha1:xxxxx'

# Check for any errors
kubectl describe gitrepository flux-system -n flux-system
```

## Method 2: Re-Bootstrap (Nuclear Option)

If updating the secret doesn't work, you can re-bootstrap Flux. This will recreate everything.

### Step 1: Uninstall Flux

```bash
flux uninstall --namespace=flux-system --silent
```

**⚠️ Important:** This will NOT delete your applications, only the Flux controllers.

### Step 2: Delete the Old Deploy Key from GitHub

Go to https://github.com/ZinkNotTheMetal/ansible-homelab/settings/keys and delete any old Flux deploy keys.

### Step 3: Re-Bootstrap

```bash
cd src/kubernetes/flux
./bootstrap.sh
```

This will:
- Reinstall Flux controllers
- Create a new SSH secret
- Create a new GitHub deploy key
- Reconnect to your repository

### Step 4: Verify

```bash
flux check
flux get sources git
kubectl get pods -n flux-system
```

## Troubleshooting

### "couldn't find remote ref" Error

This usually means Flux can't authenticate to GitHub.

```bash
# Check the secret exists
kubectl get secret flux-system -n flux-system

# View the Git repository error
kubectl describe gitrepository flux-system -n flux-system

# Look for authentication errors in source-controller logs
kubectl logs -n flux-system deploy/source-controller --tail=50
```

**Solution:** Verify the deploy key is added to GitHub with write access.

### "Host key verification failed" Error

The GitHub host key isn't in the known_hosts.

```bash
# Update the Flux secret to include GitHub's host key
flux create secret git flux-system \
  --url=ssh://git@github.com/ZinkNotTheMetal/homelab \
  --namespace=flux-system \
  --private-key-file=~/.ssh/id_ed25519 \
  --ssh-key-algorithm=ecdsa \
  --ssh-ecdsa-curve=p256
```

### "Permission denied (publickey)" Error

The public key isn't added to GitHub or doesn't match the private key.

```bash
# Verify you're using the correct key pair
ssh-keygen -y -f ~/.ssh/id_ed25519 > /tmp/public.pub
cat /tmp/public.pub

# Compare with what's in GitHub deploy keys
# They should match!
```

### Flux Still Can't Connect

```bash
# Get detailed logs
kubectl logs -n flux-system deploy/source-controller -f

# Test SSH from inside the cluster
kubectl run -it --rm test-ssh \
  --image=alpine/git \
  --restart=Never \
  --namespace=flux-system -- sh

# Inside the pod:
apk add openssh-client
ssh -T git@github.com
# Should show: "Hi ZinkNotTheMetal! You've successfully authenticated"
```

## Rotating Keys Regularly (Best Practice)

For security, consider rotating your Flux SSH keys periodically:

1. **Set a reminder** to rotate keys every 6-12 months
2. **Use dedicated keys** for Flux (not your personal SSH key)
3. **Store backup keys** securely (password manager, encrypted)
4. **Monitor deploy key usage** in GitHub settings

## Alternative: GitHub Personal Access Token (Not Recommended)

If you prefer using a Personal Access Token instead of SSH:

```bash
# Create a secret with PAT
flux create secret git flux-system \
  --url=https://github.com/ZinkNotTheMetal/homelab \
  --username=git \
  --password=<your-github-token> \
  --namespace=flux-system

# Update GitRepository to use HTTPS
kubectl edit gitrepository flux-system -n flux-system
# Change spec.url to: https://github.com/ZinkNotTheMetal/homelab
```

**Why SSH is better:**
- ✅ Deploy keys are repository-specific (more secure)
- ✅ Deploy keys don't expire
- ✅ Personal Access Tokens can expire and need rotation
- ✅ Deploy keys have limited scope (single repo)

## Quick Reference Commands

```bash
# View current Git source
flux get sources git

# View secret (base64 encoded)
kubectl get secret flux-system -n flux-system -o yaml

# Recreate secret with new key
kubectl delete secret flux-system -n flux-system
flux create secret git flux-system \
  --url=ssh://git@github.com/ZinkNotTheMetal/homelab \
  --namespace=flux-system \
  --private-key-file=~/.ssh/id_ed25519

# Force reconciliation
flux reconcile source git flux-system

# Check logs
kubectl logs -n flux-system deploy/source-controller --tail=100
```

## Resources

- [Flux Bootstrap Documentation](https://fluxcd.io/flux/installation/)
- [Flux Git Authentication](https://fluxcd.io/flux/components/source/gitrepositories/#authentication)
- [GitHub Deploy Keys Documentation](https://docs.github.com/en/developers/overview/managing-deploy-keys)
