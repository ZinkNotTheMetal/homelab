# Sonarr PostgreSQL Migration Setup

## Prerequisites

1. PostgreSQL databases created:
   - `sonarr-main` - Main application database
   - `sonarr-log` - Log database

2. Get PostgreSQL credentials:
   ```bash
   kubectl get secret -n pg-database cnpg-cluster-release-superuser -o jsonpath='{.data.password}' | base64 -d
   ```

## Setup Steps

### 1. Create the Secret

Get the PostgreSQL password and create the secret directly with kubectl:

```bash
# Get the password
PGPASSWORD=$(kubectl get secret -n pg-database cnpg-cluster-release-superuser -o jsonpath='{.data.password}' | base64 -d)

# Create the secret
kubectl create secret generic sonarr-postgres-credentials -n media \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD="$PGPASSWORD" \
  --from-literal=POSTGRES_HOST=cnpg-cluster-release-rw.pg-database.svc.cluster.local \
  --from-literal=POSTGRES_PORT=5432 \
  --from-literal=POSTGRES_MAIN_DB=sonarr-main \
  --from-literal=POSTGRES_LOG_DB=sonarr-log
```

### 2. Create the ConfigMap

```bash
# Get the password
PGPASSWORD=$(kubectl get secret -n pg-database cnpg-cluster-release-superuser -o jsonpath='{.data.password}' | base64 -d)

# Create config.xml file
cat > /tmp/sonarr-config.xml <<EOF
<Config>
  <LogLevel>info</LogLevel>
  <UrlBase></UrlBase>
  <BindAddress>*</BindAddress>
  <Port>8989</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey></ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Branch>main</Branch>
  <SslCertPath></SslCertPath>
  <SslCertPassword></SslCertPassword>
  <UpdateMechanism>Docker</UpdateMechanism>
  <InstanceName>Sonarr</InstanceName>
  <PostgresUser>postgres</PostgresUser>
  <PostgresPassword>$PGPASSWORD</PostgresPassword>
  <PostgresPort>5432</PostgresPort>
  <PostgresHost>cnpg-cluster-release-rw.pg-database.svc.cluster.local</PostgresHost>
  <PostgresMainDb>sonarr-main</PostgresMainDb>
  <PostgresLogDb>sonarr-log</PostgresLogDb>
</Config>
EOF

# Create the ConfigMap
kubectl create configmap sonarr-postgres-config -n media --from-file=config.xml=/tmp/sonarr-config.xml

# Clean up
rm /tmp/sonarr-config.xml
```

### 3. Delete Old PVC (IMPORTANT: This will delete all existing Sonarr data)

```bash
# Delete the deployment first
kubectl delete deployment -n media sonarr

# Delete the PVC
kubectl delete pvc -n media sonarr
```

### 4. Apply HelmRelease

The HelmRelease will be applied by Flux automatically once merged to main, or you can apply it manually:

```bash
kubectl apply -f helmrelease.yaml
```

### 5. Verify PostgreSQL Connection

```bash
# Check pod logs
kubectl logs -n media -l app.kubernetes.io/name=sonarr --tail=50

# Verify databases have tables
kubectl exec -n pg-database cnpg-cluster-release-3 -- psql -U postgres -d sonarr-main -c "\dt"
```

## Rollback

If you need to rollback to SQLite:

1. Delete the postgres-config mount from helmrelease.yaml
2. Delete the configmap: `kubectl delete configmap -n media sonarr-postgres-config`
3. Restart Sonarr - it will recreate SQLite database
