#!/usr/bin/env bash
set -euo pipefail

# -------- Inputs via env --------
DATA_DIR="${DATA_DIR:-/mnt/sqldata}"
SA_PWD="${SA_PWD:?missing SA_PWD}"
DB_NAME="${DB_NAME:-DemoDB}"
CI_LOGIN="${CI_LOGIN:-ci_user}"
CI_PASSWORD="${CI_PASSWORD:?missing CI_PASSWORD}"
IMAGE="mcr.microsoft.com/mssql/server:2022-latest"
# --------------------------------

echo "[provision] Data dir: $DATA_DIR"
sudo mkdir -p "$DATA_DIR"
sudo chown -R 10001:0 "$DATA_DIR"
sudo chmod -R 770 "$DATA_DIR"

echo "[provision] Pulling image..."
sudo docker pull "$IMAGE"

if sudo docker ps -a --format '{{.Names}}' | grep -q '^mssql$'; then
  echo "[provision] Removing old container 'mssql'..."
  sudo docker rm -f mssql || true
fi

echo "[provision] Starting container..."
sudo docker run -d --name mssql \
  --restart unless-stopped \
  -e ACCEPT_EULA=Y \
  -e MSSQL_PID=Developer \
  -e MSSQL_SA_PASSWORD="$SA_PWD" \
  -p 1433:1433 \
  -v "$DATA_DIR:/var/opt/mssql" \
  "$IMAGE"

echo "[provision] Waiting up to 5 minutes for SQL to be ready..."
for i in $(seq 1 60); do
  if sudo docker inspect -f '{{.State.Health.Status}}' mssql 2>/dev/null | grep -q healthy; then
    echo "[provision] Health: healthy"
    break
  fi

  if sudo docker exec mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$SA_PWD" -Q "SELECT 1" >/dev/null 2>&1; then
    echo "[provision] SQL responds to queries."
    break
  fi

  sleep 5
  if [ "$i" -eq 60 ]; then
    echo "[provision] SQL not healthy in time. Last logs:"
    sudo docker logs --tail=200 mssql || true
    exit 1
  fi
done

echo "[provision] Ensuring DB '$DB_NAME' and login '$CI_LOGIN'..."
sudo docker exec mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$SA_PWD" -b \
  -Q "IF DB_ID(N'$DB_NAME') IS NULL CREATE DATABASE [$DB_NAME];"

sudo docker exec mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$SA_PWD" -b \
  -Q "IF NOT EXISTS (SELECT name FROM sys.sql_logins WHERE name = N'$CI_LOGIN') BEGIN CREATE LOGIN [$CI_LOGIN] WITH PASSWORD=N'$CI_PASSWORD', CHECK_POLICY=OFF; END;"

sudo docker exec mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$SA_PWD" -b \
  -Q "USE [$DB_NAME]; IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'$CI_LOGIN') BEGIN CREATE USER [$CI_LOGIN] FOR LOGIN [$CI_LOGIN]; EXEC sp_addrolemember N'db_owner', N'$CI_LOGIN'; END;"

echo "[provision] Done."
