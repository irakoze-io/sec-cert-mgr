#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Find project root (one level up from scripts/)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"

# Move to project root to ensure git commands work correctly
cd "$PROJECT_ROOT"

# Default values
MODE="release-branch"  # or "direct"
RELEASE_MESSAGE=""
GRADLE_FILE="build.gradle"

# Function to check git status
check_git_status() {
    if ! git diff-index --quiet HEAD --; then
        echo -e "${RED}Error: Uncommitted changes detected. Please commit all changes first.${NC}"
        exit 1
    fi
}

# Check if on develop branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "develop" ]; then
    echo -e "${RED}Error: You must be on the 'develop' branch to run this script.${NC}"
    echo -e "Current branch: $CURRENT_BRANCH"
    exit 1
fi

# Ensure build.gradle exists
if [ ! -f "$GRADLE_FILE" ]; then
    echo -e "${RED}Error: $GRADLE_FILE not found in $PROJECT_ROOT.${NC}"
    exit 1
fi

# Read version from build.gradle
VERSION=$(sed -nE "s/^version = '(.*)'$/\1/p" "$GRADLE_FILE")

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Could not find version in $GRADLE_FILE${NC}"
    exit 1
fi

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -m, --mode MODE             Release mode: 'direct' or 'release-branch' (default: release-branch)
    -M, --message MESSAGE       Release message (optional)
    -h, --help                  Show this help message

EXAMPLES:
    # Release using release branch (recommended)
    $0 -M "Release version $VERSION"

    # Direct merge approach
    $0 -m direct
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -M|--message)
            RELEASE_MESSAGE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

# Default message
if [ -z "$RELEASE_MESSAGE" ]; then
    RELEASE_MESSAGE="Release version $VERSION"
fi

# Validate mode
if [[ "$MODE" != "release-branch" && "$MODE" != "direct" ]]; then
    echo -e "${RED}Error: Mode must be 'release-branch' or 'direct'${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Git Flow Release Merge Script                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Version: $VERSION (from $GRADLE_FILE)"
echo "  Mode: $MODE"
echo "  Message: $RELEASE_MESSAGE"
echo "  Branch: $CURRENT_BRANCH"
echo ""

# Confirm before proceeding
read -p "$(echo -e ${YELLOW}Proceed with release?${NC}) (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted.${NC}"
    exit 1
fi

echo ""

check_git_status

# Function to run command with error handling
run_command() {
    local cmd="$1"
    local desc="$2"
    echo -e "${BLUE}→ $desc${NC}"
    if ! eval "$cmd"; then
        echo -e "${RED}✗ Failed: $desc${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ $desc${NC}"
    echo ""
}

#############################################
# DIRECT MERGE APPROACH
#############################################
if [ "$MODE" = "direct" ]; then
    echo -e "${YELLOW}Starting DIRECT merge from develop → main${NC}"
    echo ""

    # Step 1: Update develop
    run_command "git pull origin develop" "Pulling latest develop"

    # Step 2: Update main
    run_command "git checkout main" "Switching to main branch"
    run_command "git pull origin main" "Pulling latest main"

    # Step 3: Merge develop into main
    run_command "git merge develop --no-edit" "Merging develop into main"

    # Step 4: Create tag
    run_command "git tag -a v$VERSION -m '$RELEASE_MESSAGE'" "Creating version tag v$VERSION"

    # Step 5: Push main and tag
    run_command "git push origin main" "Pushing main branch"
    run_command "git push origin v$VERSION" "Pushing version tag"

    # Step 6: Merge main back into develop
    run_command "git checkout develop" "Switching back to develop"
    run_command "git merge main --no-edit" "Merging main back into develop"
    run_command "git push origin develop" "Pushing develop branch"

    echo -e "${GREEN}Summary: Released version v$VERSION${NC}"
    exit 0
fi

#############################################
# RELEASE BRANCH APPROACH (DEFAULT)
#############################################
if [ "$MODE" = "release-branch" ]; then
    echo -e "${YELLOW}Starting RELEASE BRANCH merge from develop → main${NC}"
    echo ""

    RELEASE_BRANCH="release/$VERSION"

    # Step 1: Create and checkout release branch
    run_command "git pull origin develop" "Pulling latest develop"
    run_command "git checkout -b $RELEASE_BRANCH" "Creating release branch: $RELEASE_BRANCH"

    # Step 2: Merge release branch into main
    run_command "git checkout main" "Switching to main"
    run_command "git pull origin main" "Pulling latest main"
    run_command "git merge --no-ff $RELEASE_BRANCH -m 'Merge release/$VERSION into main'" "Merging release branch into main"

    # Step 3: Create tag
    run_command "git tag -a v$VERSION -m '$RELEASE_MESSAGE'" "Creating version tag v$VERSION"

    # Step 4: Push main
    run_command "git push origin main" "Pushing main branch"
    run_command "git push origin v$VERSION" "Pushing version tag"

    # Step 5: Merge release branch back into develop
    run_command "git checkout develop" "Switching to develop"
    run_command "git merge --no-ff $RELEASE_BRANCH -m 'Merge release/$VERSION back into develop'" "Merging release branch back into develop"
    run_command "git push origin develop" "Pushing develop branch"

    # Step 6: Delete release branch
    run_command "git branch -d $RELEASE_BRANCH" "Deleting local release branch"
    run_command "git push origin --delete $RELEASE_BRANCH" "Deleting remote release branch"

    echo -e "${GREEN}Summary: Released version v$VERSION${NC}"
    exit 0
fi
