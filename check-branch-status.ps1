param(
    [string]$BaseBranch = "main",
    [string]$CompareBranch = ""
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GIT BRANCH COMMIT STATUS CHECK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is available
try {
    $null = Get-Command git -ErrorAction Stop
} catch {
    Write-Host "❌ git command not found. Please install Git." -ForegroundColor Red
    exit 1
}

# Check if we're in a git repository
$isGitRepo = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not in a git repository." -ForegroundColor Red
    exit 1
}

# If no compare branch specified, use current branch
if ([string]::IsNullOrWhiteSpace($CompareBranch)) {
    $CompareBranch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Could not determine current branch." -ForegroundColor Red
        exit 1
    }
}

Write-Host "📊 Comparing branches:" -ForegroundColor Yellow
Write-Host "  Base Branch:    $BaseBranch" -ForegroundColor White
Write-Host "  Compare Branch: $CompareBranch" -ForegroundColor White
Write-Host ""

# Fetch latest changes from remote
Write-Host "🔄 Fetching latest changes from remote..." -ForegroundColor Yellow
$fetchOutput = git fetch --all 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ⚠️  Warning: Could not fetch from remote." -ForegroundColor Yellow
    Write-Host "  Continuing with local data..." -ForegroundColor Gray
} else {
    Write-Host "  ✅ Fetch complete" -ForegroundColor Green
}
Write-Host ""

# Check if base branch exists
$baseBranchExists = git rev-parse --verify $BaseBranch 2>$null
if ($LASTEXITCODE -ne 0) {
    # Try to check if it exists as origin/branch
    $baseBranchExists = git rev-parse --verify "origin/$BaseBranch" 2>$null
    if ($LASTEXITCODE -eq 0) {
        $BaseBranch = "origin/$BaseBranch"
    } else {
        Write-Host "❌ Base branch '$BaseBranch' not found." -ForegroundColor Red
        Write-Host ""
        Write-Host "Available branches:" -ForegroundColor Yellow
        git branch -a
        exit 1
    }
}

# Check if compare branch exists
$compareBranchExists = git rev-parse --verify $CompareBranch 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Compare branch '$CompareBranch' not found." -ForegroundColor Red
    exit 1
}

# Get ahead/behind counts
$counts = git rev-list --left-right --count "$BaseBranch...$CompareBranch" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Could not compare branches." -ForegroundColor Red
    exit 1
}

$behind, $ahead = $counts -split '\s+'

Write-Host "📈 Branch Status:" -ForegroundColor Yellow
Write-Host ""

if ($ahead -eq 0 -and $behind -eq 0) {
    Write-Host "  ✅ Branches are in sync!" -ForegroundColor Green
    Write-Host "  $CompareBranch is up to date with $BaseBranch" -ForegroundColor White
} else {
    if ($ahead -gt 0) {
        Write-Host "  ⬆️  Ahead:  " -NoNewline -ForegroundColor Green
        Write-Host "$ahead commit$(if ($ahead -ne 1) { 's' })" -ForegroundColor White
    }
    if ($behind -gt 0) {
        Write-Host "  ⬇️  Behind: " -NoNewline -ForegroundColor Yellow
        Write-Host "$behind commit$(if ($behind -ne 1) { 's' })" -ForegroundColor White
    }
}

Write-Host ""

# Show commit details if there are differences
if ($ahead -gt 0 -or $behind -gt 0) {
    if ($ahead -gt 0) {
        Write-Host "📝 Commits in $CompareBranch not in $BaseBranch (ahead):" -ForegroundColor Cyan
        Write-Host ""
        git log --oneline --graph --decorate "$BaseBranch..$CompareBranch" --color=always
        Write-Host ""
    }
    
    if ($behind -gt 0) {
        Write-Host "📝 Commits in $BaseBranch not in $CompareBranch (behind):" -ForegroundColor Cyan
        Write-Host ""
        git log --oneline --graph --decorate "$CompareBranch..$BaseBranch" --color=always
        Write-Host ""
    }
    
    Write-Host "💡 Suggestions:" -ForegroundColor Yellow
    if ($behind -gt 0) {
        Write-Host "  To update $CompareBranch with changes from ${BaseBranch}:" -ForegroundColor White
        Write-Host "    git checkout $CompareBranch" -ForegroundColor Gray
        Write-Host "    git merge $BaseBranch" -ForegroundColor Gray
        Write-Host "    # or" -ForegroundColor Gray
        Write-Host "    git rebase $BaseBranch" -ForegroundColor Gray
    }
    if ($ahead -gt 0) {
        Write-Host "  To push $CompareBranch commits:" -ForegroundColor White
        Write-Host "    git push origin $CompareBranch" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  STATUS CHECK COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
