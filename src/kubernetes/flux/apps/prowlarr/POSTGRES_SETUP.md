# Prowlarr PostgreSQL Setup

## ✅ Current Status

Prowlarr is successfully configured to use PostgreSQL via **environment variables**.

## Configuration Method

Prowlarr uses environment variables for PostgreSQL configuration instead of config.xml. This approach:
- Avoids permission issues with the LinuxServer container
- Keeps secrets out of ConfigMaps  
- Works reliably with the loeken-at-home Helm chart

## Environment Variables

The following environment variables are configured in `helmrelease.yaml`:

```yaml
env:
  PROWLARR__POSTGRES__HOST: "cnpg-cluster-release-rw.pg-database.svc.cluster.local"
  PROWLARR__POSTGRES__PORT: "5432"
  PROWLARR__POSTGRES__USER: "postgres"
  PROWLARR__POSTGRES__PASSWORD: "<password>"
  PROWLARR__POSTGRES__MAINDB: "prowlarr-main"
  PROWLARR__POSTGRES__LOGDB: "prowlarr-log"
```

## PostgreSQL Databases

Two databases are used:
- `prowlarr-main` - Main application database
- `prowlarr-log` - Log database

## Verification

Check that Prowlarr is connected to PostgreSQL:

```bash
# Check pod status
kubectl get pods -n media -l app.kubernetes.io/name=prowlarr

# Check logs for PostgreSQL connection
kubectl logs -n media -l app.kubernetes.io/name=prowlarr | grep -i postgres

# Verify database tables exist
kubectl exec -n pg-database cnpg-cluster-release-3 -- \
  psql -U postgres -d prowlarr-main -c "\dt"
```

## Known Issues

### Health Probes

The loeken-at-home Helm chart has a bug where it ignores custom probe configuration and defaults to port 8191 (flaresolverr port). As a workaround, health probes are **disabled** in the helmrelease.yaml. The application runs correctly without them.

## Updating Password

To update the PostgreSQL password:

1. Get the new password:
   ```bash
   kubectl get secret -n pg-database cnpg-cluster-release-superuser \
     -o jsonpath='{.data.password}' | base64 -d
   ```

2. Update `helmrelease.yaml` with the new password

3. Apply the changes:
   ```bash
   kubectl apply -f helmrelease.yaml
   ```

4. Delete the pod to restart with new credentials:
   ```bash
   kubectl delete pod -n media -l app.kubernetes.io/name=prowlarr
   ```

## Rollback to SQLite

If you need to rollback to SQLite:

1. Remove all `PROWLARR__POSTGRES__*` environment variables from helmrelease.yaml
2. Delete the PVC: `kubectl delete pvc -n media prowlarr`
3. Apply the updated helmrelease.yaml
4. Prowlarr will recreate SQLite databases on startup
