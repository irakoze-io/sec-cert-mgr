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

# Function to increment version (adapted from version.sh)
get_next_version() {
    local current_version=$(sed -nE "s/^version = '([0-9]+)\.([0-9]+)\.([0-9]+)'$/\1.\2.\3/p" "$GRADLE_FILE")
    
    if [ -z "$current_version" ]; then
        echo -e "${RED}Error: Could not parse version in $GRADLE_FILE${NC}" >&2
        exit 1
    fi

    IFS=. read -r major minor patch <<EOF
$current_version
EOF

    patch=$((patch + 1))

    if [ "$patch" -gt 99 ]; then
        patch=0
        minor=$((minor + 1))
    fi

    if [ "$minor" -gt 99 ]; then
        minor=0
        major=$((major + 1))
    fi

    echo "${major}.${minor}.${patch}"
}

NEXT_VERSION=$(get_next_version)

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -m, --mode MODE             Release mode: 'direct' or 'release-branch' (default: release-branch)
    -M, --message MESSAGE       Release message (optional)
    -h, --help                  Show this help message

EXAMPLES:
    # Release using release branch (recommended)
    $0 -M "Release version $NEXT_VERSION"

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
    RELEASE_MESSAGE="Release version $NEXT_VERSION"
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
echo "  Next Version: $NEXT_VERSION"
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

# Step 0: Increment version in build.gradle
echo -e "${BLUE}→ Incrementing version in $GRADLE_FILE...${NC}"
CURRENT_VERSION_STRING=$(sed -nE "s/^version = '(.*)'$/\1/p" "$GRADLE_FILE")
sed -i.bak "s/^version = '${CURRENT_VERSION_STRING}'$/version = '${NEXT_VERSION}'/" "$GRADLE_FILE"
rm "${GRADLE_FILE}.bak"

# Step 0.1: Commit the version bump
run_command "git add $GRADLE_FILE" "Staging $GRADLE_FILE"
run_command "git commit -m 'chore: bump version to $NEXT_VERSION'" "Committing version bump"

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
    run_command "git tag -a v$NEXT_VERSION -m '$RELEASE_MESSAGE'" "Creating version tag v$NEXT_VERSION"

    # Step 5: Push main and tag
    run_command "git push origin main" "Pushing main branch"
    run_command "git push origin v$NEXT_VERSION" "Pushing version tag"

    # Step 6: Merge main back into develop
    run_command "git checkout develop" "Switching back to develop"
    run_command "git merge main --no-edit" "Merging main back into develop"
    run_command "git push origin develop" "Pushing develop branch"

    echo -e "${GREEN}Summary: Released version v$NEXT_VERSION${NC}"
    exit 0
fi

#############################################
# RELEASE BRANCH APPROACH (DEFAULT)
#############################################
if [ "$MODE" = "release-branch" ]; then
    echo -e "${YELLOW}Starting RELEASE BRANCH merge from develop → main${NC}"
    echo ""

    RELEASE_BRANCH="release/$NEXT_VERSION"

    # Step 1: Create and checkout release branch
    run_command "git pull origin develop" "Pulling latest develop"
    run_command "git checkout -b $RELEASE_BRANCH" "Creating release branch: $RELEASE_BRANCH"

    # Step 2: Merge release branch into main
    run_command "git checkout main" "Switching to main"
    run_command "git pull origin main" "Pulling latest main"
    run_command "git merge --no-ff $RELEASE_BRANCH -m 'Merge $RELEASE_BRANCH into main'" "Merging release branch into main"

    # Step 3: Create tag
    run_command "git tag -a v$NEXT_VERSION -m '$RELEASE_MESSAGE'" "Creating version tag v$NEXT_VERSION"

    # Step 4: Push main
    run_command "git push origin main" "Pushing main branch"
    run_command "git push origin v$NEXT_VERSION" "Pushing version tag"

    # Step 5: Merge release branch back into develop
    run_command "git checkout develop" "Switching to develop"
    run_command "git merge --no-ff $RELEASE_BRANCH -m 'Merge $RELEASE_BRANCH back into develop'" "Merging release branch back into develop"
    run_command "git push origin develop" "Pushing develop branch"

    # Step 6: Delete release branch
    run_command "git branch -d $RELEASE_BRANCH" "Deleting local release branch"
    # Note: Only try to delete remote if it was pushed (which we didn't do here, but keeping for completeness if needed)
    # run_command "git push origin --delete $RELEASE_BRANCH" "Deleting remote release branch"

    echo -e "${GREEN}Summary: Released version v$NEXT_VERSION${NC}"
    exit 0
fi
