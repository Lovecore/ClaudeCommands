#!/bin/bash

# Git Worktree Manager - Enhanced Edition
# A robust script for managing git worktrees with improved UX and features

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration (can be overridden with environment variables)
WORKTREE_BASE_DIR="${GIT_WORKTREE_DIR:-tree}"  # Allow custom base directory
DEFAULT_BASE_BRANCH="${GIT_DEFAULT_BRANCH:-main}"  # Configurable base branch
AUTO_SETUP_HOOKS="${GIT_WORKTREE_AUTO_HOOKS:-true}"  # Auto-setup hooks
AUTO_INSTALL_DEPS="${GIT_WORKTREE_AUTO_DEPS:-false}"  # Auto-install dependencies

# Helper functions
print_error() {
    echo -e "${RED}✗ Error:${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}✓ Success:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ Warning:${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ Info:${NC} $1"
}

print_header() {
    echo -e "\n${BOLD}$1${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

# Function to validate branch name
validate_branch_name() {
    local branch="$1"
    
    # Check for empty name
    if [[ -z "$branch" ]]; then
        print_error "Branch name cannot be empty"
        return 1
    fi
    
    # Check for invalid characters
    if [[ "$branch" =~ [[:space:]] ]]; then
        print_error "Branch name cannot contain spaces"
        return 1
    fi
    
    # Check for invalid patterns
    if [[ "$branch" =~ ^[-.]|[-.]$ ]]; then
        print_error "Branch name cannot start or end with - or ."
        return 1
    fi
    
    # Check for consecutive dots
    if [[ "$branch" =~ \.\. ]]; then
        print_error "Branch name cannot contain consecutive dots"
        return 1
    fi
    
    # Check for Git reserved names
    if [[ "$branch" == "HEAD" ]] || [[ "$branch" == "FETCH_HEAD" ]]; then
        print_error "Branch name '$branch' is reserved by Git"
        return 1
    fi
    
    return 0
}

# Function to suggest branch name based on type
suggest_branch_name() {
    echo -e "\n${BOLD}Branch name suggestions:${NC}"
    echo "  • feature/description  - For new features"
    echo "  • bugfix/issue-number  - For bug fixes"
    echo "  • hotfix/urgent-fix    - For production hotfixes"
    echo "  • experiment/idea      - For experiments"
    echo "  • refactor/component   - For refactoring"
    echo ""
}

# Function to check for uncommitted changes in main worktree
check_uncommitted_changes() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        print_warning "You have uncommitted changes in the current worktree"
        read -p "Do you want to stash them before creating new worktree? (y/n): " stash_changes
        if [[ "$stash_changes" == "y" ]]; then
            git stash push -m "Auto-stash before creating worktree $(date +%Y-%m-%d_%H:%M:%S)"
            print_success "Changes stashed"
        fi
    fi
}

# Function to setup the new worktree
setup_worktree() {
    local worktree_path="$1"
    local branch_name="$2"
    
    cd "$worktree_path"
    
    # Copy git hooks if they exist
    if [[ "$AUTO_SETUP_HOOKS" == "true" ]] && [[ -d "$repo_root/.git/hooks" ]]; then
        print_info "Setting up git hooks..."
        cp -r "$repo_root/.git/hooks" ".git/" 2>/dev/null || true
    fi
    
    # Auto-install dependencies based on detected package manager
    if [[ "$AUTO_INSTALL_DEPS" == "true" ]]; then
        if [[ -f "package.json" ]]; then
            if command -v npm &> /dev/null; then
                print_info "Installing npm dependencies..."
                npm install
            fi
        elif [[ -f "requirements.txt" ]]; then
            if command -v pip &> /dev/null; then
                print_info "Installing Python dependencies..."
                pip install -r requirements.txt
            fi
        elif [[ -f "Gemfile" ]]; then
            if command -v bundle &> /dev/null; then
                print_info "Installing Ruby dependencies..."
                bundle install
            fi
        elif [[ -f "go.mod" ]]; then
            if command -v go &> /dev/null; then
                print_info "Downloading Go modules..."
                go mod download
            fi
        fi
    fi
    
    # Create a .env file if template exists
    if [[ -f "$repo_root/.env.template" ]] && [[ ! -f ".env" ]]; then
        cp "$repo_root/.env.template" ".env"
        print_info "Created .env file from template"
    fi
}

# Function to list existing worktrees
list_worktrees() {
    print_header "Existing Worktrees"
    git worktree list | while IFS= read -r line; do
        # Extract path and branch info
        path=$(echo "$line" | awk '{print $1}')
        branch=$(echo "$line" | awk '{print $3}' | tr -d '[]')
        
        # Make output prettier
        if [[ "$path" == "$repo_root" ]]; then
            echo -e "${GREEN}●${NC} [main] $path"
        else
            echo -e "${BLUE}●${NC} [$branch] $path"
        fi
    done
    echo ""
}

# Function to clean up old worktrees
cleanup_worktrees() {
    print_info "Pruning stale worktree references..."
    git worktree prune
    
    # Check for merged branches that can be cleaned
    local merged_branches=$(git branch --merged "$DEFAULT_BASE_BRANCH" | grep -v "^\*" | grep -v "$DEFAULT_BASE_BRANCH" || true)
    
    if [[ -n "$merged_branches" ]]; then
        print_warning "The following branches have been merged and their worktrees can be removed:"
        echo "$merged_branches"
        read -p "Remove worktrees for merged branches? (y/n): " remove_merged
        if [[ "$remove_merged" == "y" ]]; then
            echo "$merged_branches" | while read -r branch; do
                branch=$(echo "$branch" | xargs)  # Trim whitespace
                worktree_path=$(git worktree list | grep "\[$branch\]" | awk '{print $1}' || true)
                if [[ -n "$worktree_path" ]]; then
                    git worktree remove "$worktree_path"
                    print_success "Removed worktree for $branch"
                fi
            done
        fi
    fi
}

# Main script starts here
main() {
    print_header "Git Worktree Manager"
    
    # Ensure we're in a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Get the repository root
    repo_root=$(git rev-parse --show-toplevel)

    # Ensure the worktree base directory is in .gitignore
    gitignore_path="$repo_root/.gitignore"
    if [[ -f "$gitignore_path" ]]; then
        # Check if the worktree directory is already in .gitignore
        if ! grep -q "^${WORKTREE_BASE_DIR}/\?$" "$gitignore_path"; then
            print_info "Adding '${WORKTREE_BASE_DIR}/' to .gitignore"
            # Ensure file ends with newline before appending
            if [[ -s "$gitignore_path" ]] && [[ $(tail -c1 "$gitignore_path" | wc -l) -eq 0 ]]; then
                echo "" >> "$gitignore_path"
            fi
            echo "${WORKTREE_BASE_DIR}/" >> "$gitignore_path"
        fi
    else
        # Create .gitignore with the worktree directory
        print_info "Creating .gitignore with '${WORKTREE_BASE_DIR}/'"
        echo "${WORKTREE_BASE_DIR}/" > "$gitignore_path"
    fi

    # Check if we want to list existing worktrees
    if [[ "${1:-}" == "--list" ]] || [[ "${1:-}" == "-l" ]]; then
        list_worktrees
        exit 0
    fi
    
    # Check if we want to cleanup
    if [[ "${1:-}" == "--cleanup" ]] || [[ "${1:-}" == "-c" ]]; then
        cleanup_worktrees
        exit 0
    fi
    
    # Show existing worktrees
    list_worktrees
    
    # Check for uncommitted changes
    check_uncommitted_changes
    
    # Suggest branch naming
    suggest_branch_name
    
    # Prompt for branch name or use argument
    if [[ -n "${1:-}" ]]; then
        branch_name="$1"
    else
        read -p "Enter new branch name (or 'exit' to quit): " branch_name
    fi
    
    # Allow user to exit
    if [[ "$branch_name" == "exit" ]] || [[ "$branch_name" == "quit" ]]; then
        print_info "Exiting..."
        exit 0
    fi
    
    # Validate branch name
    if ! validate_branch_name "$branch_name"; then
        exit 1
    fi
    
    # Check if branch already exists
    local branch_exists=false
    local base_branch="$DEFAULT_BASE_BRANCH"
    
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        print_warning "Branch '$branch_name' already exists"
        read -p "Do you want to create a worktree for the existing branch? (y/n): " use_existing
        if [[ "$use_existing" != "y" ]]; then
            read -p "Enter a different branch name: " branch_name
            if ! validate_branch_name "$branch_name"; then
                exit 1
            fi
        else
            branch_exists=true
        fi
    fi
    
    # If creating new branch, ask for base branch
    if [[ "$branch_exists" == "false" ]]; then
        print_info "Current branches:"
        git branch -a --format='  %(refname:short)' | head -10
        read -p "Base new branch on (default: $DEFAULT_BASE_BRANCH): " user_base_branch
        if [[ -n "$user_base_branch" ]]; then
            base_branch="$user_base_branch"
        fi
        
        # Verify base branch exists
        if ! git show-ref --verify --quiet "refs/heads/$base_branch" && \
           ! git show-ref --verify --quiet "refs/remotes/origin/$base_branch"; then
            print_error "Base branch '$base_branch' does not exist"
            exit 1
        fi
    fi
    
    # Determine worktree path
    branch_path="$repo_root/$WORKTREE_BASE_DIR/$branch_name"
    
    # Handle branch names with slashes (create nested directories)
    if [[ "$branch_name" == */* ]]; then
        mkdir -p "$(dirname "$branch_path")"
    else
        mkdir -p "$repo_root/$WORKTREE_BASE_DIR"
    fi
    
    # Check if worktree already exists
    if [[ -d "$branch_path" ]]; then
        print_error "Worktree directory already exists: $branch_path"
        read -p "Remove existing directory and recreate? (y/n): " remove_existing
        if [[ "$remove_existing" == "y" ]]; then
            rm -rf "$branch_path"
        else
            exit 1
        fi
    fi
    
    # Create the worktree
    print_info "Creating worktree..."
    
    if [[ "$branch_exists" == "true" ]]; then
        # Branch exists, create worktree for it
        git worktree add "$branch_path" "$branch_name"
    else
        # Create new branch from base and worktree
        git worktree add -b "$branch_name" "$branch_path" "$base_branch"
    fi
    
    print_success "Worktree created at: $branch_path"
    
    # Setup the new worktree (hooks, dependencies, etc.)
    setup_worktree "$branch_path" "$branch_name"
    
    # Provide next steps
    print_header "Next Steps"
    echo -e "1. Navigate to worktree:  ${GREEN}cd $branch_path${NC}"
    echo -e "2. Open in editor:        ${GREEN}code $branch_path${NC}"
    echo -e "3. Start Claude Code:     ${GREEN}cd $branch_path && claude${NC}"
    echo ""
    echo -e "To see all worktrees:     ${BLUE}git worktree list${NC}"
    echo -e "To remove this worktree:  ${BLUE}git worktree remove $branch_path${NC}"
    
    # Offer to open in VS Code if available
    if command -v code &> /dev/null; then
        read -p "Open in VS Code? (y/n): " open_vscode
        if [[ "$open_vscode" == "y" ]]; then
            code "$branch_path"
        fi
    fi
    
    # Offer to cd into the new worktree
    echo ""
    print_info "Run this command to enter the worktree:"
    echo -e "${GREEN}cd $branch_path${NC}"
}

# Show usage if --help is passed
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
${BOLD}Git Worktree Manager${NC}

${BOLD}Usage:${NC}
  $(basename "$0") [branch-name]     Create a new worktree
  $(basename "$0") --list|-l         List existing worktrees
  $(basename "$0") --cleanup|-c      Clean up merged worktrees
  $(basename "$0") --help|-h         Show this help message

${BOLD}Environment Variables:${NC}
  GIT_WORKTREE_DIR       Base directory for worktrees (default: tree)
  GIT_DEFAULT_BRANCH     Default base branch (default: main)
  GIT_WORKTREE_AUTO_HOOKS Auto-setup git hooks (default: true)
  GIT_WORKTREE_AUTO_DEPS  Auto-install dependencies (default: false)

${BOLD}Examples:${NC}
  $(basename "$0") feature/login     Create worktree for feature/login
  $(basename "$0")                   Interactive mode
  $(basename "$0") --list            Show all worktrees
  
${BOLD}Features:${NC}
  • Validates branch names
  • Handles existing branches
  • Auto-creates nested directories
  • Sets up git hooks
  • Optional dependency installation
  • Cleans up merged branches
  • VS Code integration

EOF
    exit 0
fi

# Run main function
main "$@"
