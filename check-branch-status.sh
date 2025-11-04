#!/bin/bash

# Default parameters
BASE_BRANCH="${1:-main}"
COMPARE_BRANCH="${2:-}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  GIT BRANCH COMMIT STATUS CHECK${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if git is available
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ git command not found. Please install Git.${NC}"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo -e "${RED}❌ Not in a git repository.${NC}"
    exit 1
fi

# If no compare branch specified, use current branch
if [ -z "$COMPARE_BRANCH" ]; then
    COMPARE_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Could not determine current branch.${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}📊 Comparing branches:${NC}"
echo -e "  Base Branch:    ${WHITE}$BASE_BRANCH${NC}"
echo -e "  Compare Branch: ${WHITE}$COMPARE_BRANCH${NC}"
echo ""

# Fetch latest changes from remote
echo -e "${YELLOW}🔄 Fetching latest changes from remote...${NC}"
if git fetch --all 2>&1 > /dev/null; then
    echo -e "  ${GREEN}✅ Fetch complete${NC}"
else
    echo -e "  ${YELLOW}⚠️  Warning: Could not fetch from remote.${NC}"
    echo -e "  ${GRAY}Continuing with local data...${NC}"
fi
echo ""

# Check if base branch exists
if ! git rev-parse --verify "$BASE_BRANCH" &> /dev/null; then
    # Try to check if it exists as origin/branch
    if git rev-parse --verify "origin/$BASE_BRANCH" &> /dev/null; then
        BASE_BRANCH="origin/$BASE_BRANCH"
    else
        echo -e "${RED}❌ Base branch '$BASE_BRANCH' not found.${NC}"
        echo ""
        echo -e "${YELLOW}Available branches:${NC}"
        git branch -a
        exit 1
    fi
fi

# Check if compare branch exists
if ! git rev-parse --verify "$COMPARE_BRANCH" &> /dev/null; then
    echo -e "${RED}❌ Compare branch '$COMPARE_BRANCH' not found.${NC}"
    exit 1
fi

# Get ahead/behind counts
COUNTS=$(git rev-list --left-right --count "$BASE_BRANCH...$COMPARE_BRANCH" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Could not compare branches.${NC}"
    exit 1
fi

BEHIND=$(echo $COUNTS | cut -d' ' -f1)
AHEAD=$(echo $COUNTS | cut -d' ' -f2)

echo -e "${YELLOW}📈 Branch Status:${NC}"
echo ""

if [ "$AHEAD" -eq 0 ] && [ "$BEHIND" -eq 0 ]; then
    echo -e "  ${GREEN}✅ Branches are in sync!${NC}"
    echo -e "  ${WHITE}$COMPARE_BRANCH is up to date with $BASE_BRANCH${NC}"
else
    if [ "$AHEAD" -gt 0 ]; then
        PLURAL_AHEAD=""
        [ "$AHEAD" -ne 1 ] && PLURAL_AHEAD="s"
        echo -e "  ${GREEN}⬆️  Ahead:  ${WHITE}$AHEAD commit$PLURAL_AHEAD${NC}"
    fi
    if [ "$BEHIND" -gt 0 ]; then
        PLURAL_BEHIND=""
        [ "$BEHIND" -ne 1 ] && PLURAL_BEHIND="s"
        echo -e "  ${YELLOW}⬇️  Behind: ${WHITE}$BEHIND commit$PLURAL_BEHIND${NC}"
    fi
fi

echo ""

# Show commit details if there are differences
if [ "$AHEAD" -gt 0 ] || [ "$BEHIND" -gt 0 ]; then
    if [ "$AHEAD" -gt 0 ]; then
        echo -e "${CYAN}📝 Commits in $COMPARE_BRANCH not in $BASE_BRANCH (ahead):${NC}"
        echo ""
        git log --oneline --graph --decorate "$BASE_BRANCH..$COMPARE_BRANCH" --color=always
        echo ""
    fi
    
    if [ "$BEHIND" -gt 0 ]; then
        echo -e "${CYAN}📝 Commits in $BASE_BRANCH not in $COMPARE_BRANCH (behind):${NC}"
        echo ""
        git log --oneline --graph --decorate "$COMPARE_BRANCH..$BASE_BRANCH" --color=always
        echo ""
    fi
    
    echo -e "${YELLOW}💡 Suggestions:${NC}"
    if [ "$BEHIND" -gt 0 ]; then
        echo -e "  ${WHITE}To update $COMPARE_BRANCH with changes from $BASE_BRANCH:${NC}"
        echo -e "    ${GRAY}git checkout $COMPARE_BRANCH${NC}"
        echo -e "    ${GRAY}git merge $BASE_BRANCH${NC}"
        echo -e "    ${GRAY}# or${NC}"
        echo -e "    ${GRAY}git rebase $BASE_BRANCH${NC}"
    fi
    if [ "$AHEAD" -gt 0 ]; then
        echo -e "  ${WHITE}To push $COMPARE_BRANCH commits:${NC}"
        echo -e "    ${GRAY}git push origin $COMPARE_BRANCH${NC}"
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  STATUS CHECK COMPLETE${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
