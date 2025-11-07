# Test SQL Server connection through IAP tunnel
# Make sure sql-tunnel-iap.ps1 is running before executing this

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Testing SQL Connection via IAP Tunnel" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Connection details
$server = "localhost,51433"
$database = "DemoDB"
$username = "ci_user"
$password = "ChangeMe_UseStrongPwd#2025!"

Write-Host "Testing connection to: $server" -ForegroundColor Yellow
Write-Host "Database: $database" -ForegroundColor Yellow
Write-Host "User: $username`n" -ForegroundColor Yellow

# Test 1: Check if port is listening
Write-Host "[1/3] Checking if tunnel port is open..." -ForegroundColor Green
$portTest = Test-NetConnection -ComputerName localhost -Port 51433 -WarningAction SilentlyContinue
if ($portTest.TcpTestSucceeded) {
    Write-Host "      [OK] Port 51433 is listening`n" -ForegroundColor Green
} else {
    Write-Host "      [FAIL] Port 51433 is NOT listening!" -ForegroundColor Red
    Write-Host "      Run .\sql-tunnel-iap.ps1 in another window first!`n" -ForegroundColor Yellow
    exit 1
}

# Test 2: Try SQL connection with .NET SqlClient
Write-Host "[2/3] Testing SQL Server connection..." -ForegroundColor Green
try {
    $connectionString = "Server=$server;Database=$database;User Id=$username;Password=$password;TrustServerCertificate=True;Connection Timeout=10;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    Write-Host "      [OK] Connected successfully!`n" -ForegroundColor Green
    
    # Test 3: Execute a simple query
    Write-Host "[3/3] Executing test query..." -ForegroundColor Green
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT @@VERSION AS SqlVersion, DB_NAME() AS CurrentDB, GETDATE() AS CurrentTime"
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        Write-Host "      [OK] Query executed successfully!`n" -ForegroundColor Green
        Write-Host "Results:" -ForegroundColor Cyan
        Write-Host "  Database: " -NoNewline -ForegroundColor White
        Write-Host $reader["CurrentDB"] -ForegroundColor Yellow
        Write-Host "  Time: " -NoNewline -ForegroundColor White
        Write-Host $reader["CurrentTime"] -ForegroundColor Yellow
        Write-Host "  Version: " -NoNewline -ForegroundColor White
        Write-Host $reader["SqlVersion"].ToString().Split("`n")[0] -ForegroundColor Yellow
    }
    
    $reader.Close()
    $connection.Close()
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  [SUCCESS] All tests passed!" -ForegroundColor Green
    Write-Host "  You can now connect SSMS to:" -ForegroundColor Green
    Write-Host "  Server: localhost,51433" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Green
    
} catch {
    Write-Host "      [FAIL] Connection failed!`n" -ForegroundColor Red
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host "`nTroubleshooting:" -ForegroundColor Cyan
    Write-Host "1. Ensure sql-tunnel-iap.ps1 is running" -ForegroundColor White
    Write-Host "2. Check VM is running: gcloud compute instances list" -ForegroundColor White
    Write-Host "3. Verify SQL container: .\ssh-iap.ps1, then 'sudo docker ps'`n" -ForegroundColor White
    exit 1
}
