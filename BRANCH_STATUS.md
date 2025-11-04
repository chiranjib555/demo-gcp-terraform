# Git Branch Status Checker

This repository includes scripts to check the commit status of git branches, showing how many commits a branch is ahead or behind another branch.

## Scripts

### PowerShell Script: `check-branch-status.ps1`

For Windows users or those with PowerShell installed.

#### Usage

```powershell
# Check current branch against main (default)
.\check-branch-status.ps1

# Check specific branch against main
.\check-branch-status.ps1 -CompareBranch feature-branch

# Compare two specific branches
.\check-branch-status.ps1 -BaseBranch develop -CompareBranch feature-branch
```

#### Parameters

- `BaseBranch` (optional): The base branch to compare against. Default is `main`.
- `CompareBranch` (optional): The branch to compare. Default is the current branch.

### Bash Script: `check-branch-status.sh`

For Linux, macOS, and other Unix-like systems.

#### Usage

```bash
# Check current branch against main (default)
./check-branch-status.sh

# Check specific branch against main
./check-branch-status.sh main feature-branch

# Compare two specific branches
./check-branch-status.sh develop feature-branch
```

#### Parameters

1. Base branch (optional): The base branch to compare against. Default is `main`.
2. Compare branch (optional): The branch to compare. Default is the current branch.

## Features

Both scripts provide:

- ✅ Automatic detection of current branch
- ✅ Fetching latest changes from remote
- ✅ Ahead/behind commit counts
- ✅ Detailed commit list for differences
- ✅ Helpful suggestions for syncing branches
- ✅ Color-coded output for easy reading
- ✅ Error handling for missing branches

## Output Example

```
========================================
  GIT BRANCH COMMIT STATUS CHECK
========================================

📊 Comparing branches:
  Base Branch:    main
  Compare Branch: feature-branch

🔄 Fetching latest changes from remote...
  ✅ Fetch complete

📈 Branch Status:

  ⬆️  Ahead:  3 commits
  ⬇️  Behind: 2 commits

📝 Commits in feature-branch not in main (ahead):

* abc1234 Add new feature
* def5678 Update documentation
* ghi9012 Fix bug

📝 Commits in main not in feature-branch (behind):

* jkl3456 Update dependencies
* mno7890 Security patch

💡 Suggestions:
  To update feature-branch with changes from main:
    git checkout feature-branch
    git merge main
    # or
    git rebase main
  To push feature-branch commits:
    git push origin feature-branch

========================================
  STATUS CHECK COMPLETE
========================================
```

## Common Use Cases

### Before Creating a Pull Request

Check if your feature branch is up to date with the main branch:

```bash
# Bash
./check-branch-status.sh main my-feature-branch

# PowerShell
.\check-branch-status.ps1 -BaseBranch main -CompareBranch my-feature-branch
```

### Regular Branch Maintenance

Check if your current branch needs updating:

```bash
# Bash
./check-branch-status.sh

# PowerShell
.\check-branch-status.ps1
```

### Comparing Feature Branches

See the difference between two feature branches:

```bash
# Bash
./check-branch-status.sh feature-a feature-b

# PowerShell
.\check-branch-status.ps1 -BaseBranch feature-a -CompareBranch feature-b
```

## Requirements

- Git must be installed and available in the system PATH
- Must be run from within a git repository
- Internet connection for fetching remote changes (optional, will work with local data if fetch fails)

## Troubleshooting

### "Not in a git repository" Error

Make sure you're running the script from within a git repository directory.

### "Branch not found" Error

The script will automatically try to find the branch as `origin/branch-name` if the local branch doesn't exist. Make sure you've fetched the latest changes or that the branch name is correct.

### "Could not fetch from remote" Warning

The script will continue with local data if it can't fetch from remote. This is normal if you're offline or don't have push/pull access to the remote repository.
