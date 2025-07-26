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

# Target directories
HOOKS_TARGET="$CLAUDE_DIR/hooks"
COMMANDS_TARGET="$CLAUDE_DIR/commands"
AGENTS_TARGET="$CLAUDE_DIR/agents"

# Backup directory with timestamp
BACKUP_DIR="$CLAUDE_DIR/backups/$(date +%Y%m%d_%H%M%S)"

# Installation mode (copy or symlink)
INSTALL_MODE=""

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

# Function to prompt for installation mode
get_install_mode() {
    echo ""
    echo "Installation Mode Selection"
    echo "---------------------------"
    echo "1) Copy files (default) - Creates independent copies in ~/.claude"
    echo "2) Symlink files - Creates symbolic links to your source files"
    echo ""
    echo "Symlinks are useful for development as changes to source files"
    echo "are immediately reflected without reinstalling."
    echo ""
    read -p "Select installation mode (1 or 2) [1]: " mode_choice
    
    case $mode_choice in
        2)
            INSTALL_MODE="symlink"
            print_status "info" "Using symlink mode"
            ;;
        *)
            INSTALL_MODE="copy"
            print_status "info" "Using copy mode"
            ;;
    esac
}

# Function to show backup information
show_backup_info() {
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR)" ]; then
        echo ""
        echo "Backup Information"
        echo "------------------"
        print_status "info" "Backups saved to: $BACKUP_DIR"
        
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
    
    # Show installed files summary
    echo ""
    echo "Installed Files Summary"
    echo "-----------------------"
    
    for dir in "$HOOKS_TARGET" "$COMMANDS_TARGET" "$AGENTS_TARGET"; do
        if [ -d "$dir" ] && [ "$(ls -A $dir)" ]; then
            local type=$(basename "$dir")
            echo ""
            echo "$type:"
            for file in "$dir"/*; do
                if [ -e "$file" ]; then
                    if [ -L "$file" ]; then
                        # Show symlink target
                        local target=$(readlink "$file")
                        echo "  - $(basename "$file") -> $target"
                    else
                        echo "  - $(basename "$file")"
                    fi
                fi
            done
        fi
    done
    
    # Show mode-specific information
    echo ""
    if [ "$INSTALL_MODE" == "symlink" ]; then
        print_status "info" "Files are symlinked - changes to source files will be reflected immediately"
    else
        print_status "info" "Files are copied - run this script again to update after changes"
    fi
}

# Run the main function
main