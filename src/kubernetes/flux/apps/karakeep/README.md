# Karakeep

Karakeep (formerly known as Hoarder) is a self-hosted bookmark manager and read-it-later application with AI-powered features.

## Components

This deployment includes three components:

1. **Karakeep Web** - The main application (Next.js)
2. **Meilisearch** - Full-text search engine for fast bookmark searching
3. **Chrome** - Headless browser for capturing web page screenshots and content

## Prerequisites

### 1. Create the Secret

Copy the sample secret and fill in your values:

```bash
cp secret.sample.yaml secret.secret.yaml
```

Edit `secret.secret.yaml` and set:

- `NEXTAUTH_SECRET`: Generate with `openssl rand -base64 36`
- `MEILI_MASTER_KEY`: Generate with `openssl rand -base64 36`
- `OPENAI_API_KEY`: (Optional) For AI-powered features like automatic tagging

### 2. Apply the Secret

The secret will be applied automatically when Flux reconciles. Ensure the `secret.secret.yaml` file exists before deploying.

## Deployment

Flux will automatically deploy this application when changes are pushed to the repository.

To force reconciliation:

```bash
flux reconcile kustomization flux-system --with-source
```

## Accessing the Application

Once deployed, access Karakeep at:

- **URL**: https://hoarder.zinkzone.tech

## Storage

This deployment uses Longhorn for persistent storage:

- **Karakeep Data**: 10Gi - Stores bookmarks, assets, and application data
- **Meilisearch Data**: 5Gi - Stores search indexes

## Resource Requirements

| Component   | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-------------|-------------|-----------|----------------|--------------|
| Karakeep    | 100m        | 1000m     | 256Mi          | 1Gi          |
| Meilisearch | 50m         | 1000m     | 256Mi          | 1Gi          |
| Chrome      | 100m        | 1000m     | 256Mi          | 1Gi          |

## Features

- Bookmark management with tags and lists
- Full-text search powered by Meilisearch
- Browser extension support
- Mobile-friendly interface
- RSS feed generation
- AI-powered automatic tagging (requires OpenAI API key)
- Web page screenshot capture
- Archive/offline mode for saved pages

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n karakeep
```

### View Logs

```bash
# Karakeep application logs
kubectl logs -n karakeep -l app=karakeep -f

# Meilisearch logs
kubectl logs -n karakeep -l app=meilisearch -f

# Chrome logs
kubectl logs -n karakeep -l app=chrome -f
```

### Restart Deployments

```bash
kubectl rollout restart deployment -n karakeep karakeep
kubectl rollout restart deployment -n karakeep meilisearch
kubectl rollout restart deployment -n karakeep chrome
```

## References

- [Karakeep Documentation](https://docs.karakeep.app/)
- [Karakeep GitHub](https://github.com/karakeep-app/karakeep)
- [Meilisearch Documentation](https://docs.meilisearch.com/)
