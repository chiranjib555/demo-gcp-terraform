# Alternative: Simple Mode Deployment (Public SSH)

If you prefer simpler setup without IAP tunnel, use this workflow instead.

## Setup

### 1. Remove IAP Requirement

The VM already has public SSH enabled via firewall rule `allow-ssh-admin` (restricted to your IP).

### 2. Update Workflow to Use Direct SSH

Create `.github/workflows/deploy-sql-simple.yml`:

```yaml
name: Deploy SQL Server (Simple Mode - Direct SSH)

on:
  workflow_dispatch:
    inputs:
      action:
        description: 'Action to perform'
        required: true
        type: choice
        options:
          - deploy
          - restart
          - stop

env:
  VM_EXTERNAL_IP: ${{ secrets.VM_EXTERNAL_IP }}
  VM_USER: debian
  CONTAINER_NAME: mssql
  SQL_VERSION: "2022-latest"

jobs:
  deploy-sql-server:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup SSH key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H $VM_EXTERNAL_IP >> ~/.ssh/known_hosts

      - name: Deploy SQL Server Container
        env:
          SA_PASSWORD: ${{ secrets.SQL_SA_PASSWORD }}
          CI_PASSWORD: ${{ secrets.SQL_CI_PASSWORD }}
          ACTION: ${{ github.event.inputs.action }}
        run: |
          SSH="ssh -o StrictHostKeyChecking=no $VM_USER@$VM_EXTERNAL_IP"
          
          if [ "$ACTION" = "stop" ]; then
            $SSH "sudo docker stop $CONTAINER_NAME || true"
            exit 0
          fi
          
          if [ "$ACTION" = "restart" ]; then
            $SSH "sudo docker restart $CONTAINER_NAME"
            exit 0
          fi
          
          # Deploy
          CONTAINER_EXISTS=$($SSH "sudo docker ps -a -q -f name=$CONTAINER_NAME" || echo "")
          
          if [ -n "$CONTAINER_EXISTS" ]; then
            $SSH "sudo docker stop $CONTAINER_NAME || true"
            $SSH "sudo docker rm $CONTAINER_NAME || true"
          fi
          
          $SSH "sudo docker run -d \
            --name $CONTAINER_NAME \
            --hostname sqlserver \
            -e ACCEPT_EULA=Y \
            -e MSSQL_SA_PASSWORD='$SA_PASSWORD' \
            -e MSSQL_PID=Developer \
            -p 1433:1433 \
            -v /mnt/sqldata/data:/var/opt/mssql/data \
            -v /mnt/sqldata/log:/var/opt/mssql/log \
            -v /mnt/sqldata/secrets:/var/opt/mssql/secrets \
            --restart unless-stopped \
            mcr.microsoft.com/mssql/server:$SQL_VERSION"
          
          # Wait for SQL Server
          for i in {1..12}; do
            if $SSH "sudo docker exec $CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P '$SA_PASSWORD' -C -Q 'SELECT 1' &>/dev/null"; then
              echo "SQL Server ready!"
              break
            fi
            sleep 5
          done
          
          # Run init script
          scp -o StrictHostKeyChecking=no infra/scripts/init-database.sql $VM_USER@$VM_EXTERNAL_IP:/tmp/
          
          $SSH "cat /tmp/init-database.sql | sudo docker exec -i $CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U SA -P '$SA_PASSWORD' -C \
            -v CI_PASSWORD='$CI_PASSWORD' \
            -v VERSION='$(date +%Y%m%d-%H%M%S)'"
          
          echo "Deployment complete!"
```

### 3. Generate SSH Key Pair

**On your local machine:**
```bash
# Generate new SSH key (no passphrase)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/gcp-github-actions -N ""

# View public key (add to VM metadata)
cat ~/.ssh/gcp-github-actions.pub
```

### 4. Add SSH Public Key to VM

**Option A: Via Terraform**

Add to `infra/compute.sql-linux.tf`:
```hcl
metadata = {
  startup-script = templatefile(...)
  enable-oslogin = "FALSE"  # Use metadata SSH keys instead
  ssh-keys       = "debian:ssh-rsa AAAAB3... your-public-key"
}
```

**Option B: Via Console**

1. Go to Compute Engine → VM instances → sql-linux-vm
2. Click **Edit**
3. Scroll to **SSH Keys**
4. Click **Add item**
5. Paste your public key
6. Save

### 5. Add GitHub Secrets

Add these additional secrets:

| Name | Value |
|------|-------|
| `VM_EXTERNAL_IP` | Your VM's static IP (from terraform output) |
| `SSH_PRIVATE_KEY` | Contents of `~/.ssh/gcp-github-actions` (private key) |

### 6. Run Simple Mode Workflow

Go to Actions → Deploy SQL Server (Simple Mode) → Run workflow

---

## Comparison: IAP vs Simple Mode

| Feature | IAP Mode | Simple Mode |
|---------|----------|-------------|
| **Setup Complexity** | Medium (service account + IAP) | Simple (just SSH keys) |
| **Security** | ✅ Better (no public SSH exposure) | ⚠️ SSH port exposed (limited to firewall) |
| **GitHub Secrets** | 4 secrets | 6 secrets |
| **Maintenance** | Service account key rotation | SSH key rotation |
| **Debugging** | Harder (IAP logs) | Easier (direct connection) |
| **Cost** | Free | Free |
| **Best For** | Production, compliance | Development, quick setup |

---

## Security Notes

**Simple Mode Security:**
- SSH port 22 exposed to internet (but restricted by firewall to your IP)
- Private SSH key stored in GitHub Secrets (encrypted at rest)
- If your IP changes, update `admin_ip_cidr` in terraform.tfvars

**To improve security:**
1. Use a bastion host instead of direct SSH
2. Rotate SSH keys quarterly
3. Enable Cloud Audit Logs
4. Use Cloud Armor for DDoS protection on the IP

---

**Recommendation:** Use IAP mode for production, Simple mode for quick dev/test environments.
