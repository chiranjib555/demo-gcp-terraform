###############################################################################
# SQL Server VM Connection Information Retrieval Script (PowerShell)
# 
# Purpose: Fetch current VM IP address and generate connection strings
# Usage: .\scripts\Get-ConnectionInfo.ps1 [-ProjectId <id>] [-Zone <zone>]
#
# This script is useful for:
#   - Getting current connection details after VM recreate
#   - Updating application configuration files
#   - Generating connection strings for different tools
###############################################################################

param(
    [string]$ProjectId = "praxis-gantry-475007-k0",
    [string]$Zone = "us-central1-a",
    [string]$VMName = "sql-linux-vm",
    [string]$Database = "DemoDB",
    [string]$SqlUser = "ci_user"
)

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         SQL Server VM Connection Information                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Set project
gcloud config set project $ProjectId --quiet | Out-Null

# Check if VM exists
$vmExists = gcloud compute instances describe $VMName --zone $Zone 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ VM does not exist!" -ForegroundColor Red
    Write-Host ""
    Write-Host "The VM has been destroyed. To recreate it:" -ForegroundColor Yellow
    Write-Host "  1. Run GitHub Actions workflow with 'create' action"
    Write-Host "  2. Or use: cd infra; terraform apply"
    exit 1
}

# Get VM status
$vmStatus = gcloud compute instances describe $VMName --zone $Zone --format="value(status)"

Write-Host "📊 VM Status:" -ForegroundColor Cyan
Write-Host "   Name: $VMName"
Write-Host "   Zone: $Zone"
Write-Host "   Status: $vmStatus" -ForegroundColor Green
Write-Host ""

# Get IP addresses
$externalIp = gcloud compute instances describe $VMName --zone $Zone --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
$internalIp = gcloud compute instances describe $VMName --zone $Zone --format="get(networkInterfaces[0].networkIP)"

Write-Host "🌐 Network Information:" -ForegroundColor Cyan
Write-Host "   External IP: $externalIp"
Write-Host "   Internal IP: $internalIp"
Write-Host "   SQL Port: 1433"
Write-Host ""

# Check if VM is running
if ($vmStatus -ne "RUNNING") {
    Write-Host "⚠️ VM is not running. Start it first to connect." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To start the VM:"
    Write-Host "  gcloud compute instances start $VMName --zone $Zone"
    exit 0
}

# Generate connection strings
Write-Host "🔌 Connection Strings:" -ForegroundColor Cyan
Write-Host ""

Write-Host "ADO.NET / C# / .NET:" -ForegroundColor Yellow
Write-Host "Server=$externalIp,1433;Database=$Database;User Id=$SqlUser;Password=<YOUR_PASSWORD>;TrustServerCertificate=True;Encrypt=True;"
Write-Host ""

Write-Host "JDBC / Java:" -ForegroundColor Yellow
Write-Host "jdbc:sqlserver://${externalIp}:1433;databaseName=$Database;user=$SqlUser;password=<YOUR_PASSWORD>;encrypt=true;trustServerCertificate=true;"
Write-Host ""

Write-Host "ODBC:" -ForegroundColor Yellow
Write-Host "Driver={ODBC Driver 18 for SQL Server};Server=$externalIp,1433;Database=$Database;Uid=$SqlUser;Pwd=<YOUR_PASSWORD>;Encrypt=yes;TrustServerCertificate=yes;"
Write-Host ""

Write-Host "SQLAlchemy / Python:" -ForegroundColor Yellow
Write-Host "mssql+pyodbc://${SqlUser}:<YOUR_PASSWORD>@${externalIp}:1433/$Database?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
Write-Host ""

Write-Host "Azure Data Studio / SSMS:" -ForegroundColor Yellow
Write-Host "Server: $externalIp,1433"
Write-Host "Database: $Database"
Write-Host "Authentication: SQL Server Authentication"
Write-Host "Username: $SqlUser"
Write-Host "Password: <YOUR_PASSWORD>"
Write-Host "Encryption: Mandatory"
Write-Host "Trust server certificate: Yes"
Write-Host ""

# Test connection (requires sqlcmd to be installed locally)
Write-Host "🧪 Testing Connection:" -ForegroundColor Cyan
if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
    Write-Host "Testing connection to SQL Server..."
    
    try {
        $sqlPassword = gcloud secrets versions access latest --secret=sql-ci-password --project=$ProjectId 2>$null
        
        if ($sqlPassword) {
            $testResult = sqlcmd -S "$externalIp,1433" -U $SqlUser -P $sqlPassword -C -Q "SELECT @@VERSION" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Connection successful!" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Connection failed. VM might still be starting up." -ForegroundColor Yellow
            }
        } else {
            Write-Host "⚠️ Cannot fetch password from Secret Manager" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Connection test failed" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ sqlcmd not installed locally, skipping connection test" -ForegroundColor Yellow
    Write-Host "To test manually:"
    Write-Host "  sqlcmd -S $externalIp,1433 -U $SqlUser -P <PASSWORD> -C -Q 'SELECT @@VERSION'"
}

Write-Host ""
Write-Host "✅ Connection information retrieved successfully!" -ForegroundColor Green
Write-Host ""

# Export as environment variables
Write-Host "📝 Environment Variables (copy to .env):" -ForegroundColor Cyan
Write-Host "SQL_SERVER_HOST=$externalIp"
Write-Host "SQL_SERVER_PORT=1433"
Write-Host "SQL_SERVER_DATABASE=$Database"
Write-Host "SQL_SERVER_USER=$SqlUser"
Write-Host "SQL_SERVER_PASSWORD=<get from Secret Manager: sql-ci-password>"
Write-Host ""

# Generate JSON output
Write-Host "📋 JSON Output (for automation):" -ForegroundColor Cyan
$jsonOutput = @{
    vm_name = $VMName
    status = $vmStatus
    zone = $Zone
    external_ip = $externalIp
    internal_ip = $internalIp
    database = $Database
    username = $SqlUser
    port = 1433
    connection_string = "Server=$externalIp,1433;Database=$Database;User Id=$SqlUser;Password=<PASSWORD>;TrustServerCertificate=True;"
} | ConvertTo-Json

Write-Host $jsonOutput
Write-Host ""
