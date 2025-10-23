# Example: How to run the local test

# IMPORTANT: Replace these with your actual passwords!
$SA_PASSWORD = "YourStrongSAPassword123!"
$CI_PASSWORD = "YourCIUserPassword456!"

# Run the test
.\test-deploy-local.ps1 `
  -SaPassword $SA_PASSWORD `
  -CiPassword $CI_PASSWORD

# If you need to override other settings:
# .\test-deploy-local.ps1 `
#   -GcpProject "your-project-id" `
#   -GcpZone "us-central1-a" `
#   -VmName "sql-linux-vm" `
#   -SaPassword $SA_PASSWORD `
#   -CiPassword $CI_PASSWORD `
#   -DbName "DemoDB"
