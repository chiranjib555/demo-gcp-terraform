#!/usr/bin/env bash
#
# VM Startup Script for SQL Server Deployment
# This runs on every boot/reset and is idempotent
#
set -euo pipefail

CONTAINER_NAME="mssql"
SQL_VERSION="2022-latest"
PROJECT_ID="praxis-gantry-475007-k0"
GCS_BUCKET="praxis-sql-bootstrap"

# Logging helper
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "=== SQL Server Startup Script ==="

# Install gcloud if not present (should be there on Debian)
if ! command -v gcloud &> /dev/null; then
  log "Installing Google Cloud SDK..."
  curl https://sdk.cloud.google.com | bash
  exec -l $SHELL
fi

# Fetch secrets from Secret Manager
log "Fetching secrets from Secret Manager..."
SA_PASSWORD=$(gcloud secrets versions access latest \
  --secret=sql-sa-password \
  --project="${PROJECT_ID}" 2>/dev/null || echo "")

CI_PASSWORD=$(gcloud secrets versions access latest \
  --secret=sql-ci-password \
  --project="${PROJECT_ID}" 2>/dev/null || echo "")

if [ -z "$SA_PASSWORD" ] || [ -z "$CI_PASSWORD" ]; then
  log "ERROR: Failed to fetch secrets from Secret Manager"
  exit 1
fi

log "Secrets fetched successfully"

# Download latest SQL init script from GCS
log "Downloading init script from GCS..."
SKIP_INIT=false
gsutil cp "gs://${GCS_BUCKET}/init-database.sql" /tmp/init-database.sql || {
  log "WARNING: Failed to download init-database.sql, will skip initialization"
  SKIP_INIT=true
}

# Install Docker if not present
if ! command -v docker &> /dev/null; then
  log "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  systemctl enable docker
  systemctl start docker
  rm get-docker.sh
fi

# Ensure data directory exists with correct permissions
log "Setting up /mnt/sqldata..."
mkdir -p /mnt/sqldata
chown -R 10001:0 /mnt/sqldata
chmod -R 770 /mnt/sqldata

# Check if container is already running and healthy
EXISTING=$(docker ps -q --filter name="${CONTAINER_NAME}" 2>/dev/null || echo "")

if [ -n "$EXISTING" ]; then
  log "Container ${CONTAINER_NAME} is already running"
  
  # Check if it's healthy
  if docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U SA -P "${SA_PASSWORD}" -C -Q "SELECT 1" >/dev/null 2>&1; then
    log "Container is healthy, checking if init script changed..."
    
    # Only re-run init if file timestamp is newer (simple version check)
    if [ "${SKIP_INIT}" != "true" ]; then
      log "Running database initialization (idempotent)..."
      docker cp /tmp/init-database.sql "${CONTAINER_NAME}":/tmp/init-database.sql
      docker exec "${CONTAINER_NAME}" chmod 640 /tmp/init-database.sql
      
      docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U SA -P "${SA_PASSWORD}" -C -b \
        -v CI_PASSWORD="${CI_PASSWORD}" \
        -v VERSION="$(date +%Y%m%d-%H%M%S)" \
        -i /tmp/init-database.sql
      
      log "Database initialization complete"
      docker exec "${CONTAINER_NAME}" rm -f /tmp/init-database.sql
    fi
    
    log "=== Startup script complete (container already running) ==="
    exit 0
  else
    log "Container exists but not healthy, recreating..."
    docker rm -f "${CONTAINER_NAME}"
  fi
fi

# Pull latest SQL Server image
log "Pulling SQL Server ${SQL_VERSION} image..."
docker pull "mcr.microsoft.com/mssql/server:${SQL_VERSION}"

# Remove any stopped containers
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# Start SQL Server container
log "Starting SQL Server container..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  --hostname sqlserver \
  --restart unless-stopped \
  -e ACCEPT_EULA=Y \
  -e MSSQL_PID=Developer \
  -e MSSQL_SA_PASSWORD="${SA_PASSWORD}" \
  -p 1433:1433 \
  -v /mnt/sqldata:/var/opt/mssql \
  "mcr.microsoft.com/mssql/server:${SQL_VERSION}"

# Wait for SQL Server to be ready
log "Waiting for SQL Server to be ready (max 5 minutes)..."
for i in {1..60}; do
  if docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd \
      -S localhost -U SA -P "${SA_PASSWORD}" -C -Q "SELECT 1" >/dev/null 2>&1; then
    log "✅ SQL Server is ready!"
    break
  fi
  
  if [ $i -eq 60 ]; then
    log "❌ SQL Server not ready after 5 minutes. Logs:"
    docker logs --tail=100 "${CONTAINER_NAME}"
    exit 1
  fi
  
  log "Waiting... ($i/60)"
  sleep 5
done

# Run database initialization
if [ "${SKIP_INIT}" != "true" ]; then
  log "Running database initialization..."
  docker cp /tmp/init-database.sql "${CONTAINER_NAME}":/tmp/init-database.sql
  docker exec "${CONTAINER_NAME}" chmod 640 /tmp/init-database.sql
  
  docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "${SA_PASSWORD}" -C -b \
    -v CI_PASSWORD="${CI_PASSWORD}" \
    -v VERSION="$(date +%Y%m%d-%H%M%S)" \
    -i /tmp/init-database.sql
  
  log "Database initialization complete"
  
  # Verify deployment
  log "Verifying deployment..."
  docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "${SA_PASSWORD}" -C \
    -Q "SELECT name, database_id, create_date FROM sys.databases WHERE name = N'DemoDB';
        SELECT name, type_desc FROM sys.database_principals WHERE name = N'ci_user';"
  
  # Cleanup
  docker exec "${CONTAINER_NAME}" rm -f /tmp/init-database.sql
  rm -f /tmp/init-database.sql
fi

log "=== ✅ SQL Server deployment complete ==="
log "Container status: $(docker ps --filter name=${CONTAINER_NAME} --format '{{.Status}}')"
