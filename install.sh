#!/bin/bash

# Claude Code Installation Script
# This script installs custom hooks, commands, and agents to the Claude directory
# Features: backup existing files, option to symlink instead of copy

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default Claude directory in home
CLAUDE_DIR="$HOME/.claude"

# Source directories (adjust these to match your setup)
SOURCE_DIR="$(pwd)"
HOOKS_SOURCE="$SOURCE_DIR/hooks"
COMMANDS_SOURCE="$SOURCE_DIR/commands"
AGENTS_SOURCE="$SOURCE_DIR/agents"
SCRIPTS_SOURCE="$SOURCE_DIR"

# Target directories
HOOKS_TARGET="$CLAUDE_DIR/hooks"
COMMANDS_TARGET="$CLAUDE_DIR/commands"
AGENTS_TARGET="$CLAUDE_DIR/agents"
SCRIPTS_TARGET="$HOME/.local/bin"

# Backup directory with timestamp
BACKUP_DIR="$CLAUDE_DIR/backups/$(date +%Y%m%d_%H%M%S)"
BACKUPS_BASE_DIR="$CLAUDE_DIR/backups"

# Installation mode (copy or symlink)
INSTALL_MODE=""

# Maximum number of backups to keep
MAX_BACKUPS=2

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "success")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "warning")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "error")
            echo -e "${RED}✗${NC} $message"
            ;;
        "info")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
}

# Function to create directory if it doesn't exist
ensure_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "success" "Created directory: $dir"
    else
        print_status "info" "Directory already exists: $dir"
    fi
}

# Function to backup existing file
backup_file() {
    local file=$1
    local type=$2
    
    if [ -f "$file" ] || [ -L "$file" ]; then
        local filename=$(basename "$file")
        local backup_subdir="$BACKUP_DIR/$type"
        
        ensure_directory "$backup_subdir" > /dev/null 2>&1
        
        if [ -L "$file" ]; then
            # If it's a symlink, copy the symlink itself
            cp -P "$file" "$backup_subdir/$filename"
            print_status "info" "Backed up symlink: $filename"
        else
            # If it's a regular file, copy it
            cp "$file" "$backup_subdir/$filename"
            print_status "info" "Backed up file: $filename"
        fi
        
        return 0
    fi
    
    return 1
}

# Function to install specific scripts
install_scripts() {
    local source_dir=$1
    local target=$2
    
    ensure_directory "$target"
    
    local script_files=("new-worktree.sh")
    local count=0
    local backed_up=0
    
    for script in "${script_files[@]}"; do
        local source_file="$source_dir/$script"
        if [ -f "$source_file" ]; then
            local target_name="${script%.sh}"  # Remove .sh extension
            local target_file="$target/$target_name"
            
            # Backup existing file if it exists
            if backup_file "$target_file" "scripts"; then
                ((backed_up++))
            fi
            
            # Remove existing file/symlink
            if [ -e "$target_file" ] || [ -L "$target_file" ]; then
                rm -f "$target_file"
            fi
            
            if [ "$INSTALL_MODE" == "symlink" ]; then
                # Create symlink
                ln -s "$(realpath "$source_file")" "$target_file"
                print_status "success" "Symlinked script: $target_name"
            else
                # Copy file
                cp "$source_file" "$target_file"
                chmod +x "$target_file"
                print_status "success" "Installed script: $target_name"
            fi
            
            ((count++))
        else
            print_status "warning" "Script not found: $script"
        fi
    done
    
    if [ $backed_up -gt 0 ]; then
        print_status "info" "Backed up $backed_up existing script(s)"
    fi
    
    if [ $count -gt 0 ]; then
        local action_verb=$([[ "$INSTALL_MODE" == "symlink" ]] && echo "Symlinked" || echo "Installed")
        print_status "info" "$action_verb $count script(s) to $target"
        
        # Check if target directory is in PATH
        if [[ ":$PATH:" != *":$target:"* ]]; then
            print_status "warning" "$target is not in your PATH"
            print_status "info" "Add this line to your shell configuration (.bashrc, .zshrc, etc.):"
            echo "    export PATH=\"\$PATH:$target\""
        fi
    fi
}

# Function to install files from source to target
install_files() {
    local source=$1
    local target=$2
    local type=$3
    
    if [ ! -d "$source" ]; then
        print_status "warning" "Source directory not found: $source"
        return 1
    fi
    
    local count=0
    local backed_up=0
    
    for file in "$source"/*; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local target_file="$target/$filename"
            
            # Backup existing file if it exists
            if backup_file "$target_file" "$type"; then
                ((backed_up++))
            fi
            
            # Remove existing file/symlink
            if [ -e "$target_file" ] || [ -L "$target_file" ]; then
                rm -f "$target_file"
            fi
            
            if [ "$INSTALL_MODE" == "symlink" ]; then
                # Create symlink
                ln -s "$(realpath "$file")" "$target_file"
                print_status "success" "Symlinked $type: $filename"
            else
                # Copy file
                cp "$file" "$target_file"
                chmod +x "$target_file"
                print_status "success" "Installed $type: $filename"
            fi
            
            ((count++))
        fi
    done
    
    if [ $backed_up -gt 0 ]; then
        print_status "info" "Backed up $backed_up existing file(s)"
    fi
    
    if [ $count -eq 0 ]; then
        print_status "warning" "No $type files found in $source"
    else
        local action_verb=$([[ "$INSTALL_MODE" == "symlink" ]] && echo "Symlinked" || echo "Installed")
        print_status "info" "$action_verb $count $type file(s)"
    fi
}

# Function to manage backups
manage_backups() {
    while true; do
        echo ""
        echo "Backup Management"
        echo "================="
        
        # Show current backup status
        if [ -d "$BACKUPS_BASE_DIR" ]; then
            local backup_count=$(find "$BACKUPS_BASE_DIR" -maxdepth 1 -type d -name "*_*" | wc -l | tr -d ' ')
            echo "Backup location: $BACKUPS_BASE_DIR"
            echo "Current backups: $backup_count"
            
            if [ $backup_count -gt 0 ]; then
                echo ""
                echo "Available backups:"
                find "$BACKUPS_BASE_DIR" -maxdepth 1 -type d -name "*_*" -exec basename {} \; | sort -r | sed 's/^/  - /'
            fi
        else
            echo "Backup location: $BACKUPS_BASE_DIR (not created yet)"
            echo "Current backups: 0"
        fi
        
        echo ""
        echo "Options:"
        echo "1) View backup details"
        echo "2) Clear all backups"
        echo "3) Clear old backups (keep $MAX_BACKUPS most recent)"
        echo "4) Change backup retention count"
        echo "5) Return to main menu"
        echo ""
        read -p "Select option (1-5): " backup_option
        
        case $backup_option in
            1)
                show_backup_details
                ;;
            2)
                clear_all_backups
                ;;
            3)
                cleanup_old_backups
                ;;
            4)
                change_backup_retention
                ;;
            5)
                break
                ;;
            *)
                print_status "error" "Invalid option. Please select 1-5."
                ;;
        esac
    done
}

# Function to show detailed backup information
show_backup_details() {
    echo ""
    echo "Backup Details"
    echo "=============="
    
    if [ ! -d "$BACKUPS_BASE_DIR" ] || [ -z "$(ls -A "$BACKUPS_BASE_DIR" 2>/dev/null)" ]; then
        print_status "info" "No backups found"
        return
    fi
    
    for backup_dir in "$BACKUPS_BASE_DIR"/*_*; do
        if [ -d "$backup_dir" ]; then
            local backup_name=$(basename "$backup_dir")
            local backup_date=$(echo "$backup_name" | sed 's/_/ /' | sed 's/\(.*\) \(.*\)/\1 \2/')
            
            echo ""
            echo "Backup: $backup_name"
            echo "Date: $backup_date"
            echo "Size: $(du -sh "$backup_dir" 2>/dev/null | cut -f1)"
            
            if [ -d "$backup_dir" ] && [ "$(ls -A "$backup_dir")" ]; then
                echo "Contents:"
                for type_dir in "$backup_dir"/*; do
                    if [ -d "$type_dir" ] && [ "$(ls -A "$type_dir")" ]; then
                        local type=$(basename "$type_dir")
                        local file_count=$(ls -1 "$type_dir" | wc -l | tr -d ' ')
                        echo "  - $type: $file_count files"
                    fi
                done
            fi
        fi
    done
}

# Function to clear all backups
clear_all_backups() {
    echo ""
    if [ ! -d "$BACKUPS_BASE_DIR" ] || [ -z "$(ls -A "$BACKUPS_BASE_DIR" 2>/dev/null)" ]; then
        print_status "info" "No backups to clear"
        return
    fi
    
    local backup_count=$(find "$BACKUPS_BASE_DIR" -maxdepth 1 -type d -name "*_*" | wc -l | tr -d ' ')
    
    echo "This will permanently delete all $backup_count backup(s)."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$BACKUPS_BASE_DIR"/*_*
        print_status "success" "All backups cleared"
    else
        print_status "info" "Operation cancelled"
    fi
}

# Function to change backup retention count
change_backup_retention() {
    echo ""
    read -p "Enter new backup retention count (current: $MAX_BACKUPS): " new_count
    
    if [[ "$new_count" =~ ^[0-9]+$ ]] && [ "$new_count" -gt 0 ]; then
        MAX_BACKUPS=$new_count
        print_status "success" "Backup retention set to $MAX_BACKUPS"
        
        # Ask if they want to apply the new limit now
        read -p "Apply new limit now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup_old_backups
        fi
    else
        print_status "error" "Invalid count. Please enter a positive number."
    fi
}

# Function to prompt for installation mode
get_install_mode() {
    echo ""
    echo "Installation Configuration"
    echo "========================="
    
    echo ""
    echo "Installation Mode:"
    echo "------------------"
    echo "1) Copy files - Creates independent copies in ~/.claude"
    echo "2) Symlink files (default) - Creates symbolic links to your source files"
    echo "3) Backup management - Manage existing backups"
    echo ""
    echo "Symlinks are useful for development as changes to source files"
    echo "are immediately reflected without reinstalling."
    echo ""
    read -p "Select installation mode (1, 2, or 3) [2]: " mode_choice
    
    case $mode_choice in
        1)
            INSTALL_MODE="copy"
            print_status "info" "Using copy mode"
            ;;
        3)
            manage_backups
            # After backup management, ask again for installation mode
            get_install_mode
            return
            ;;
        *)
            INSTALL_MODE="symlink"
            print_status "info" "Using symlink mode"
            ;;
    esac
    
    echo ""
    echo "Backup Configuration:"
    echo "--------------------"
    echo "The installer creates backups of existing files before replacing them."
    echo "Old backups are automatically cleaned up to save disk space."
    echo ""
    read -p "Number of backups to keep (default: $MAX_BACKUPS): " backup_choice
    if [[ "$backup_choice" =~ ^[0-9]+$ ]] && [ "$backup_choice" -gt 0 ]; then
        MAX_BACKUPS=$backup_choice
        print_status "info" "Will keep $MAX_BACKUPS backup(s)"
    else
        print_status "info" "Using default: $MAX_BACKUPS backup(s)"
    fi
}

# Function to clean up old backups
cleanup_old_backups() {
    if [ ! -d "$BACKUPS_BASE_DIR" ]; then
        return 0
    fi
    
    # Get all backup directories sorted by modification time (newest first)
    local backup_dirs=()
    while IFS= read -r -d '' dir; do
        backup_dirs+=("$dir")
    done < <(find "$BACKUPS_BASE_DIR" -maxdepth 1 -type d -name "*_*" -print0 | sort -z -r)
    
    local count=${#backup_dirs[@]}
    
    if [ $count -gt $MAX_BACKUPS ]; then
        local to_remove=$((count - MAX_BACKUPS))
        print_status "info" "Cleaning up old backups (keeping $MAX_BACKUPS most recent)"
        
        for ((i=MAX_BACKUPS; i<count; i++)); do
            local backup_to_remove="${backup_dirs[i]}"
            if [ -d "$backup_to_remove" ]; then
                rm -rf "$backup_to_remove"
                print_status "info" "Removed old backup: $(basename "$backup_to_remove")"
            fi
        done
        
        print_status "success" "Removed $to_remove old backup(s)"
    fi
}

# Function to show backup information
show_backup_info() {
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR)" ]; then
        echo ""
        echo "Backup Information"
        echo "------------------"
        print_status "info" "Current backup saved to: $BACKUP_DIR"
        
        # Show total number of backups kept
        local total_backups=0
        if [ -d "$BACKUPS_BASE_DIR" ]; then
            total_backups=$(find "$BACKUPS_BASE_DIR" -maxdepth 1 -type d -name "*_*" | wc -l | tr -d ' ')
        fi
        print_status "info" "Total backups maintained: $total_backups (max: $MAX_BACKUPS)"
        
        for type_dir in "$BACKUP_DIR"/*; do
            if [ -d "$type_dir" ] && [ "$(ls -A $type_dir)" ]; then
                local type=$(basename "$type_dir")
                echo ""
                echo "Backed up $type:"
                ls -1 "$type_dir" | sed 's/^/  - /'
            fi
        done
    fi
}

# Main installation process
main() {
    echo "Claude Code Installation Script"
    echo "==============================="
    
    # Check if Claude directory exists
    if [ ! -d "$CLAUDE_DIR" ]; then
        print_status "warning" "Claude directory not found at $CLAUDE_DIR"
        read -p "Do you want to create it? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ensure_directory "$CLAUDE_DIR"
        else
            print_status "error" "Installation cancelled"
            exit 1
        fi
    fi
    
    # Get installation mode
    get_install_mode
    
    # Create subdirectories
    echo ""
    echo "Creating directories..."
    ensure_directory "$HOOKS_TARGET"
    ensure_directory "$COMMANDS_TARGET"
    ensure_directory "$AGENTS_TARGET"
    
    # Install hooks
    echo ""
    echo "Installing hooks..."
    install_files "$HOOKS_SOURCE" "$HOOKS_TARGET" "hooks"
    
    # Install commands
    echo ""
    echo "Installing commands..."
    install_files "$COMMANDS_SOURCE" "$COMMANDS_TARGET" "commands"
    
    # Install agents
    echo ""
    echo "Installing agents..."
    install_files "$AGENTS_SOURCE" "$AGENTS_TARGET" "agents"
    
    # Install scripts
    echo ""
    echo "Installing scripts..."
    install_scripts "$SCRIPTS_SOURCE" "$SCRIPTS_TARGET"
    
    # Clean up old backups
    echo ""
    echo "Managing backups..."
    cleanup_old_backups
    
    # Create example files if no source directories exist
    if [ ! -d "$HOOKS_SOURCE" ] && [ ! -d "$COMMANDS_SOURCE" ] && [ ! -d "$AGENTS_SOURCE" ]; then
        echo ""
        print_status "info" "No source directories found. Creating example structure..."
        
        # Create example directories
        mkdir -p "$SOURCE_DIR/hooks"
        mkdir -p "$SOURCE_DIR/commands"
        mkdir -p "$SOURCE_DIR/agents"
        
        # Create example hook
        cat > "$SOURCE_DIR/hooks/example-hook.sh" << 'EOF'
#!/bin/bash
# Example Claude hook
echo "This is an example hook"
EOF
        chmod +x "$SOURCE_DIR/hooks/example-hook.sh"
        
        # Create example command
        cat > "$SOURCE_DIR/commands/example-command.sh" << 'EOF'
#!/bin/bash
# Example Claude command
echo "This is an example command"
EOF
        chmod +x "$SOURCE_DIR/commands/example-command.sh"
        
        # Create example agent
        cat > "$SOURCE_DIR/agents/example-agent.py" << 'EOF'
#!/usr/bin/env python3
# Example Claude agent
print("This is an example agent")
EOF
        chmod +x "$SOURCE_DIR/agents/example-agent.py"
        
        print_status "success" "Created example files in $SOURCE_DIR"
        echo ""
        print_status "info" "Add your actual hooks, commands, and agents to these directories"
        print_status "info" "Then run this script again to install them"
    fi
    
    # Show backup information if any backups were made
    show_backup_info
    
    echo ""
    print_status "success" "Installation complete!"
    
    # Show main installation summary
    echo ""
    echo "🎉 What was installed:"
    echo "====================="
    
    # Count what was installed
    local hooks_count=0
    local commands_count=0
    local agents_count=0
    local scripts_count=0
    
    if [ -d "$HOOKS_TARGET" ] && [ "$(ls -A $HOOKS_TARGET 2>/dev/null)" ]; then
        hooks_count=$(ls -1 "$HOOKS_TARGET" | wc -l | tr -d ' ')
    fi
    if [ -d "$COMMANDS_TARGET" ] && [ "$(ls -A $COMMANDS_TARGET 2>/dev/null)" ]; then
        commands_count=$(ls -1 "$COMMANDS_TARGET" | wc -l | tr -d ' ')
    fi
    if [ -d "$AGENTS_TARGET" ] && [ "$(ls -A $AGENTS_TARGET 2>/dev/null)" ]; then
        agents_count=$(ls -1 "$AGENTS_TARGET" | wc -l | tr -d ' ')
    fi
    if [ -d "$SCRIPTS_TARGET" ] && [ "$(ls -A $SCRIPTS_TARGET 2>/dev/null)" ]; then
        for file in "$SCRIPTS_TARGET"/*; do
            if [ -e "$file" ] && [[ "$(basename "$file")" =~ ^(new-worktree)$ ]]; then
                ((scripts_count++))
            fi
        done
    fi
    
    echo "  📁 $hooks_count Claude hooks (automated workflows)"
    echo "  🎯 $commands_count Claude commands (chat shortcuts)"  
    echo "  🤖 $agents_count Claude agents (specialized assistants)"
    echo "  🛠️  $scripts_count utility scripts"
    
    # Show key new functionality
    if [ $scripts_count -gt 0 ]; then
        echo ""
        echo "🌟 New Script Available:"
        echo "======================="
        echo "  new-worktree - Git worktree management tool"
        echo ""
        echo "  Usage examples:"
        echo "    new-worktree -f user-auth        # Create feature branch"
        echo "    new-worktree -i 123              # Create issue branch"
        echo "    new-worktree -f login -i 456     # Create combined branch"
        echo ""
        echo "  This creates isolated git worktrees for parallel development"
        echo "  without switching branches in your main working directory."
    fi
    
    # Show installation mode info
    echo ""
    echo "📋 Installation Details:"
    echo "======================="
    if [ "$INSTALL_MODE" == "symlink" ]; then
        echo "  Mode: Symlinked (development mode)"
        echo "  Changes to source files are reflected immediately"
    else
        echo "  Mode: Copied (production mode)"
        echo "  Run './install.sh' again to update after changes"
    fi
    
    # Show Claude usage info
    echo ""
    echo "🚀 Next Steps:"
    echo "============="
    echo "  1. Open Claude Code and type @help to see available commands"
    echo "  2. Try '@compound-issue' or '@dowork' to get started"
    echo "  3. Use 'new-worktree -f feature-name' for git worktrees"
    
    if [[ ":$PATH:" != *":$SCRIPTS_TARGET:"* ]]; then
        echo ""
        print_status "warning" "Add $SCRIPTS_TARGET to your PATH for script access:"
        echo "    echo 'export PATH=\"\$PATH:$SCRIPTS_TARGET\"' >> ~/.zshrc"
        echo "    source ~/.zshrc"
    fi
}

# Run the main function
main