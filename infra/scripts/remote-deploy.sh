#!/usr/bin/env bash
set -euo pipefail

# Arguments passed from GitHub Actions
ACTION="$1"
SA_PASSWORD="$2"
CI_PASSWORD="$3"
CONTAINER_NAME="$4"
SQL_VERSION="$5"

if [ "$ACTION" = "stop" ]; then
  echo "Stopping SQL Server container..."
  sudo docker stop "$CONTAINER_NAME" || true
  exit 0
fi

if [ "$ACTION" = "restart" ]; then
  echo "Restarting SQL Server container..."
  sudo docker restart "$CONTAINER_NAME"
  exit 0
fi

# Deploy action
echo "=== Deploying SQL Server $SQL_VERSION ==="

# Pull latest image
echo "Pulling SQL Server image..."
sudo docker pull mcr.microsoft.com/mssql/server:"$SQL_VERSION"

# Ensure correct permissions on persistent volume (idempotent)
echo "Setting correct permissions on /mnt/sqldata..."
sudo chown -R 10001:0 /mnt/sqldata || true
sudo chmod -R 770 /mnt/sqldata || true

# Stop and remove existing container if present
echo "Removing existing container if present..."
sudo docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Deploy SQL Server container with persistent storage
echo "Starting new SQL Server container..."
sudo docker run -d \
  --name "$CONTAINER_NAME" \
  --hostname sqlserver \
  --restart unless-stopped \
  -e ACCEPT_EULA=Y \
  -e MSSQL_PID=Developer \
  -e "MSSQL_SA_PASSWORD=$SA_PASSWORD" \
  -p 1433:1433 \
  -v /mnt/sqldata:/var/opt/mssql \
  mcr.microsoft.com/mssql/server:"$SQL_VERSION"

# Wait for SQL Server to be ready (up to 5 minutes)
echo "Waiting for SQL Server to become healthy (max 5 minutes)..."
for i in $(seq 1 60); do
  # Check container health status first (if image defines HEALTHCHECK)
  STATUS=$(sudo docker inspect -f '{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo 'unknown')
  
  if [ "$STATUS" = "healthy" ]; then
    echo "[OK] SQL Server is healthy!"
    break
  fi
  
  # Fallback: try simple query
  if sudo docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -C -Q 'SELECT 1' >/dev/null 2>&1; then
    echo "[OK] SQL Server is responding!"
    break
  fi
  
  if [ "$i" -eq 60 ]; then
    echo "[ERROR] SQL Server not healthy after 5 minutes. Last logs:"
    sudo docker logs --tail=200 "$CONTAINER_NAME" || true
    exit 1
  fi
  
  echo "Waiting... ($i/60)"
  sleep 5
done

# Copy initialization SQL into container (if init script exists on VM)
if [ -f /tmp/init-database.sql ]; then
  echo "=== Copying script into container ==="
  sudo docker cp /tmp/init-database.sql "$CONTAINER_NAME":/tmp/init-database.sql
  sudo docker exec "$CONTAINER_NAME" chown 10001:0 /tmp/init-database.sql || true
  sudo docker exec "$CONTAINER_NAME" chmod 640 /tmp/init-database.sql || true
  
  echo "=== Running database initialization (idempotent) ==="
  sudo docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "$SA_PASSWORD" -C -b \
    -v CI_PASSWORD="$CI_PASSWORD" \
    -v VERSION="$(date +%Y%m%d-%H%M%S)" \
    -i /tmp/init-database.sql
  
  echo "=== Verifying deployment ==="
  sudo docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "$SA_PASSWORD" -C \
    -Q "SELECT name, database_id, create_date FROM sys.databases WHERE name = N'DemoDB'; SELECT name, type_desc FROM sys.database_principals WHERE name = N'ci_user';"
else
  echo "No /tmp/init-database.sql found on VM; skipping DB init."
fi

echo "=== [OK] Deployment complete on VM ==="
