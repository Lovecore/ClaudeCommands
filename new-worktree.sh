#!/bin/bash

set -e

WORKTREE_DIR="worktrees"
FEATURE_NAME=""
ISSUE_NUMBER=""

usage() {
    echo "Usage: $0 [-f feature-name] [-i issue-number]"
    echo "  -f: Feature name (e.g., 'user-auth')"
    echo "  -i: Issue number (e.g., '123')"
    echo "Example: $0 -f user-login"
    echo "Example: $0 -i 456"
    exit 1
}

while getopts "f:i:h" opt; do
    case $opt in
        f)
            FEATURE_NAME="$OPTARG"
            ;;
        i)
            ISSUE_NUMBER="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done

if [[ -z "$FEATURE_NAME" && -z "$ISSUE_NUMBER" ]]; then
    echo "Error: Either feature name (-f) or issue number (-i) must be provided."
    usage
fi

if [[ -n "$FEATURE_NAME" && -n "$ISSUE_NUMBER" ]]; then
    BRANCH_NAME="feature/issue-${ISSUE_NUMBER}-${FEATURE_NAME}"
    WORKTREE_PATH="${WORKTREE_DIR}/issue-${ISSUE_NUMBER}-${FEATURE_NAME}"
elif [[ -n "$FEATURE_NAME" ]]; then
    BRANCH_NAME="feature/${FEATURE_NAME}"
    WORKTREE_PATH="${WORKTREE_DIR}/${FEATURE_NAME}"
else
    BRANCH_NAME="feature/issue-${ISSUE_NUMBER}"
    WORKTREE_PATH="${WORKTREE_DIR}/issue-${ISSUE_NUMBER}"
fi

echo "Creating worktree for branch: $BRANCH_NAME"
echo "Worktree path: $WORKTREE_PATH"

if [[ ! -d "$WORKTREE_DIR" ]]; then
    echo "Creating worktree directory: $WORKTREE_DIR"
    mkdir -p "$WORKTREE_DIR"
fi

if [[ -d "$WORKTREE_PATH" ]]; then
    echo "Worktree already exists at $WORKTREE_PATH"
    echo "Navigating to existing worktree..."
    cd "$WORKTREE_PATH"
else
    echo "Creating new worktree..."
    git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
    echo "Navigating to new worktree..."
    cd "$WORKTREE_PATH"
fi

echo "Current directory: $(pwd)"
echo "Current branch: $(git branch --show-current)"
echo "Worktree setup complete!"