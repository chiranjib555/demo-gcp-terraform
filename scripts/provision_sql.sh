#!/usr/bin/env bash
# Purpose: start MSSQL container, ensure data dir permissions, wait for readiness, and init DB/login.
set -euo pipefail

# --- Inputs (passed via env) ---
DATA_DIR="${DATA_DIR:-/mnt/sqldata}"          # persistent mount point
SA_PWD="${SA_PWD:?missing SA_PWD}"            # strong SA password
DB_NAME="${DB_NAME:-DemoDB}"
CI_LOGIN="${CI_LOGIN:-ci_user}"
CI_PASSWORD="${CI_PASSWORD:?missing CI_PASSWORD}"
IMAGE="${IMAGE:-mcr.microsoft.com/mssql/server:2022-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-mssql}"

echo "[provision] Data dir: ${DATA_DIR}"
sudo mkdir -p "${DATA_DIR}"

# MSSQL container runs as UID 10001 (group 0); it must own DATA_DIR
sudo chown -R 10001:0 "${DATA_DIR}"
sudo chmod -R 770 "${DATA_DIR}"

# Pull image (idempotent)
echo "[provision] Pulling image ${IMAGE}..."
sudo docker pull "${IMAGE}"

# Remove old container if present (idempotent)
if sudo docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
  echo "[provision] Removing existing container '${CONTAINER_NAME}'..."
  sudo docker rm -f "${CONTAINER_NAME}" || true
fi

echo "[provision] Starting new container '${CONTAINER_NAME}'..."
sudo docker run -d --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -e ACCEPT_EULA=Y \
  -e MSSQL_PID=Developer \
  -e MSSQL_SA_PASSWORD="${SA_PWD}" \
  -p 1433:1433 \
  -v "${DATA_DIR}:/var/opt/mssql" \
  "${IMAGE}"

echo "[provision] Waiting for SQL Server to become healthy..."
for i in $(seq 1 60); do
  if sudo docker inspect -f '{{.State.Health.Status}}' "${CONTAINER_NAME}" 2>/dev/null | grep -q healthy; then
    echo "[provision] Healthcheck reports healthy."
    break
  fi

  if sudo docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "${SA_PWD}" -Q "SELECT 1" >/dev/null 2>&1; then
    echo "[provision] SQL responds to queries."
    break
  fi

  sleep 5

  if [ "$i" -eq 60 ]; then
    echo "[provision] SQL did not become healthy in time. Recent logs:"
    sudo docker logs --tail=200 "${CONTAINER_NAME}" || true
    exit 1
  fi
done

echo "[provision] Ensuring database '${DB_NAME}' and login '${CI_LOGIN}'..."
sudo docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "${SA_PWD}" -b \
  -Q "IF DB_ID(N'${DB_NAME}') IS NULL CREATE DATABASE [${DB_NAME}];"

sudo docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "${SA_PWD}" -b \
  -Q "IF NOT EXISTS (SELECT name FROM sys.sql_logins WHERE name = N'${CI_LOGIN}') BEGIN CREATE LOGIN [${CI_LOGIN}] WITH PASSWORD=N'${CI_PASSWORD}', CHECK_POLICY=OFF; END;"

sudo docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "${SA_PWD}" -b \
  -Q "USE [${DB_NAME}]; IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'${CI_LOGIN}') BEGIN CREATE USER [${CI_LOGIN}] FOR LOGIN [${CI_LOGIN}]; EXEC sp_addrolemember N'db_owner', N'${CI_LOGIN}'; END;"

echo "[provision] Done."
