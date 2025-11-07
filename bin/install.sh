#!/usr/bin/env bash


# Smart Installation Script for the 'msg' command-line tool.
# Handles compatibility, authentication, prerequisites, cloning, and cleanup.


# Exit immediately if a command exits with a non-zero status, and treat unset variables as an error
set -euo pipefail


# --- Configuration & Paths ---
CURRENT_VERSION="1.0.0-ayodele"
INSTALL_ROOT="$HOME/.msg"
INSTALL_DIR="$INSTALL_ROOT/installation"
REPO_NAME="msg_development"
REPO_URL="git@github.com:ooluwgb/msg_development.git"
REPO_PATH="$INSTALL_DIR/$REPO_NAME"
GIT_DIR="$REPO_PATH/.git"
PRIVATE_KEY_FILE="$HOME/.ssh/msg"
VERSION_FILE="$INSTALL_ROOT/config/version.json"
COMPATIBLE_VERSION="darwin_arm64"
CURRENT_USER=$(whoami) 
FINAL_BIN_PATH="$INSTALL_ROOT/bin"
FINAL_CONFIG_PATH="$INSTALL_ROOT/config"


# --- Helper Functions ---


# Function to print a stylized step header
print_step() {
    echo -e "\n\033[1m==> $1\033[0m"
}


# Function to detect Apple Silicon architecture with fallbacks
detect_architecture() {
    local os_name=$(uname -s)
    local arch_name=$(uname -m)
    
    # Normalize OS name
    case "$os_name" in
        Darwin) os_name="darwin" ;;
        Linux) os_name="linux" ;;
        *) os_name=$(echo "$os_name" | tr '[:upper:]' '[:lower:]') ;;
    esac
    
    # Normalize architecture name with Apple Silicon detection
    case "$arch_name" in
        arm64|aarch64) arch_name="arm64" ;;
        x86_64|amd64) arch_name="x86_64" ;;
        i386|i686) arch_name="i386" ;;
        *) arch_name=$(echo "$arch_name" | tr '[:upper:]' '[:lower:]') ;;
    esac
    
    echo "${os_name}_${arch_name}"
}


# Function to detect best Python executable with Homebrew priority on macOS
detect_python() {
    local python_cmd=""
    
    # On macOS M-series, prefer Homebrew Python
    if [[ "$SYSTEM_ID" == "darwin_arm64" ]] && [[ -x "/opt/homebrew/bin/python3" ]]; then
        python_cmd="/opt/homebrew/bin/python3"
    elif [[ -x "/usr/bin/python3" ]]; then
        python_cmd="/usr/bin/python3"
    elif command -v python3 >/dev/null 2>&1; then
        python_cmd=$(command -v python3)
    elif command -v python >/dev/null 2>&1; then
        python_cmd=$(command -v python)
    fi
    
    echo "$python_cmd"
}


# Function to clean up on failure
cleanup_on_fail() {
    local EXIT_CODE=$?
    # Only clean up if the exit code indicates failure (i.e., non-zero) and is NOT the non-fatal code 2
    if [ $EXIT_CODE -ne 0 ] && [ "$EXIT_CODE" -ne 2 ]; then
        echo -e "\n\033[31m❌ Installation failed (Exit Code $EXIT_CODE). Rolling back...\033[0m"
        # Only delete the root directory if we are certain the installation was initiated here
        if [ -d "$INSTALL_ROOT" ]; then
            rm -rf "$INSTALL_ROOT"
            echo "✅ Deleted all installation files in $INSTALL_ROOT."
        fi
    fi
    exit $EXIT_CODE
}


# Set a trap to call cleanup_on_fail function on any error (non-zero exit status)
trap 'cleanup_on_fail' ERR


# --- Main Installation Logic ---


main() {
    
    # Ensure the root directory exists before performing checks
    mkdir -p "$INSTALL_ROOT"
    
    # --- 1. Compatibility Check (darwin_arm64 only) ---
    print_step "Checking system compatibility..."
    SYSTEM_ID=$(detect_architecture)
    
    if [[ "$SYSTEM_ID" != "$COMPATIBLE_VERSION" ]]; then
        echo "❌ System Compatibility Error: Access Denied"
        echo "Yikes, $CURRENT_USER! This system ($SYSTEM_ID) isn't compatible with the cool kids' club."
        echo "Time to upgrade that hardware! 💻✨"
        exit 1
    fi
    echo "✅ System check passed: $SYSTEM_ID is compatible."


    # --- 2. Authentication (msg.pub) Check ---
    print_step "Verifying access authentication key..."

    if [ ! -f "$PRIVATE_KEY_FILE" ]; then
        echo "❌ Authentication Failed: Access Denied 🚫"
        echo ""
        echo "Oh no, \033[1m$CURRENT_USER\033[0m! It seems you don't have the golden ticket."
        echo "We can't let you use this super cool tool without the right access."
        echo "We are looking for your private key file: \033[36m$PRIVATE_KEY_FILE\033[0m."
        echo ""
        echo "👉 \033[33mACTION REQUIRED:\033[0m Reach out to your admin to request access."
        echo "Come back and try again before I close up shop! Bye, wink wink 😉"
        exit 1
    fi
    
    # Check SSH key permissions for security
    key_perms=$(stat -f "%Lp" "$PRIVATE_KEY_FILE" 2>/dev/null || stat -c "%a" "$PRIVATE_KEY_FILE" 2>/dev/null)
    if [[ "$key_perms" != "600" ]]; then
        echo "⚠️  Warning: SSH key permissions are $key_perms, should be 600 for security."
        echo "   Fixing permissions: chmod 600 $PRIVATE_KEY_FILE"
        chmod 600 "$PRIVATE_KEY_FILE" || {
            echo "❌ Error: Failed to fix SSH key permissions. Please run: chmod 600 $PRIVATE_KEY_FILE"
            exit 1
        }
    fi
    
    echo "✅ Authentication key found: $PRIVATE_KEY_FILE."


    # --- 3. Python Version Check (v3 required/recommended) ---
    print_step "Checking Python requirements..."

    PYTHON_CMD=$(detect_python)
    PYTHON_VERSION_INT=2 
    
    # Check if a Python executable was found
    if [ -z "$PYTHON_CMD" ]; then
        echo "❌ Fatal: Python not found. Dependencies cannot be installed."
        echo "   On macOS M-series, try: brew install python3"
        exit 1 # Treat missing Python as fatal, as dependency management requires it
    else
        # Safely get the major version (e.g., '3' from '3.9')
        PYTHON_VERSION_INT=$("$PYTHON_CMD" -c 'import sys; print(sys.version_info[0])' 2>/dev/null)
        
        if [ "$PYTHON_VERSION_INT" -lt 3 ]; then
            echo "❌ COMPATIBILITY ISSUE: Python 3+ Required"
            echo ""
            echo "Found: Python $PYTHON_VERSION_INT at $PYTHON_CMD"
            echo "Required: Python 3.0 or higher"
            echo ""
            echo "This application uses modern Python 3 features and cannot run on Python 2.x"
            echo ""
            echo "📋 Upgrade Instructions for your system:"
            echo "   • macOS (Homebrew): brew install python3"
            echo "   • macOS (Official): https://www.python.org/downloads/macos/"
            echo "   • Other systems: https://www.python.org/downloads/"
            echo ""
            read -r -p "Would you like to upgrade to Python 3 now and continue? (y/N): " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                echo ""
                echo "Great choice! Please install Python 3 using the instructions above,"
                echo "then run this installer again."
                echo ""
                echo "👋 See you soon with Python 3! 🐍✨"
                exit 0  # Clean exit for user who wants to upgrade
            else
                echo ""
                echo "No worries! We understand not everyone is ready to upgrade."
                echo "Unfortunately, this means we can't continue with the installation."
                echo ""
                echo "If you change your mind later, Python 3 is really worth it - "
                echo "faster, more secure, and packed with cool features! 🚀"
                echo ""
                echo "👋 Thanks for trying us out! Come back anytime! 😊"
                exit 0  # Clean exit for user who declined
            fi
        fi
        echo "✅ Using Python: $PYTHON_CMD (Major Version $PYTHON_VERSION_INT)."
    fi


    # --- 4. Git Installation Check ---
    print_step "Checking for Git installation..."


    if ! command -v git >/dev/null 2>&1; then
        echo "❌ Git Missing Error:"
        echo "Wait, what?! \033[1m$CURRENT_USER\033[0m, you seriously don't have Git installed? 😱"
        echo "That's like being a chef without a knife! As punishment, you owe your admin \$100."
        echo ""
        echo "But don't worry, I've got your back. Head over to \033[4mhttps://git-scm.com/downloads\033[0m"
        echo "Download it, install it, and make sure it actually works."
        echo "Then swing back here before I close up for the day! ⏰"
        exit 1
    fi
    echo "✅ Git is installed."


    # --- 5. Clean Installation Directory ---
    print_step "Preparing installation directory ($REPO_PATH)..."
    
    # Delete the target installation directory if it exists
    if [ -d "$REPO_PATH" ]; then
        rm -rf "$REPO_PATH"
        echo "✅ Deleted old installation directory."
    fi
    # Ensure the parent directory is created for the clone step
    mkdir -p "$INSTALL_DIR"
    
    
    # --- 6. Check for Existing Up-to-Date Version ---
    print_step "Checking local version..."
    
    if [ -f "$VERSION_FILE" ]; then
        # Use grep to check for the current version string in the JSON file
        if grep -q "$CURRENT_VERSION" "$VERSION_FILE"; then
            echo "✅ Version check passed:"
            echo "Hey \033[1m$CURRENT_USER\033[0m, you're already running the latest version! Nothing to do here. 🎉"
            echo "You just woke me up for nothing! If you want to force a reinstall, use \033[3mmsg --upgrade --force\033[0m."
            exit 0 # Exit cleanly if nothing needs to be done
        fi
    fi
    echo "ℹ️  Starting full installation/upgrade (Version: $CURRENT_VERSION)."


    # --- 7. Clone Repository and Remove .git Directory ---
    print_step "Cloning repository and finalizing local installation..."


    # Set GIT_SSH_COMMAND to use the specific private key
    GIT_SSH_COMMAND="ssh -i $PRIVATE_KEY_FILE -o IdentitiesOnly=yes -o StrictHostKeyChecking=no"
    export GIT_SSH_COMMAND


    # Clone the repository silently (--depth 1 for lightweight clone)
    if git clone --depth 1 "$REPO_URL" "$REPO_PATH" > /dev/null 2>&1; then
        echo "✅ Repository cloned successfully."
    else
        echo "❌ Error: Failed to clone the repository. Check your SSH key ($PRIVATE_KEY_FILE) permissions."
        unset GIT_SSH_COMMAND
        exit 1
    fi
    
    # Force delete the .git directory
    rm -rf "$GIT_DIR" 
    echo "✅ $REPO_NAME is now a standalone directory (removed $GIT_DIR)."


    # Cleanup environment variable
    unset GIT_SSH_COMMAND


    # --- 8. Dependency Installation & Exit Code Management ---
    print_step "Installing dependencies for $SYSTEM_ID..."
    
    # Dependency script name is now the SYSTEM_ID (e.g., darwin_arm64)
    DEPENDENCY_SCRIPT="$REPO_PATH/bin/$SYSTEM_ID"
    
    if [ ! -f "$DEPENDENCY_SCRIPT" ]; then
        echo "❌ FATAL: Dependency script '$SYSTEM_ID' not found in cloned repo."
        exit 1
    fi
    
    # Make the script executable and run it using the detected python
    chmod +x "$DEPENDENCY_SCRIPT"
    # We use the explicitly detected PYTHON_CMD variable
    "$PYTHON_CMD" "$DEPENDENCY_SCRIPT"
    DEPENDENCY_EXIT_CODE=$?
    
    if [ $DEPENDENCY_EXIT_CODE -eq 1 ]; then
        echo "❌ FATAL: Dependency installation failed. Stopping."
        exit 1 # Re-exit with 1 to trigger the trap/cleanup
    elif [ $DEPENDENCY_EXIT_CODE -eq 2 ]; then
        echo "⚠️ WARNING: Dependency installation finished with non-fatal issues (Exit Code 2)."
        # Exit code 2 is preserved for informational use, but install continues (trap is skipped)
    else
        echo "✅ Dependencies installed successfully (Exit Code 0)."
    fi


    # --- 9. File Movement & Final Cleanup ---
    print_step "Finalizing file structure..."
    
    SRC_DIR="$REPO_PATH"
    DST_ROOT="$INSTALL_ROOT"
    
    # Create necessary destination folders first to ensure rsync targets exist
    mkdir -p "$DST_ROOT/custom_load" 
    mkdir -p "$FINAL_BIN_PATH" 
    mkdir -p "$FINAL_CONFIG_PATH"
    mkdir -p "$DST_ROOT/.nltk_data"  # Create hidden NLTK data directory
    
    # Use rsync for smart, safe copy/move
    # --exclude='custom_config.yaml' and --exclude='custom_load/' preserve existing custom files
    rsync -a --delete-excluded \
        --exclude='custom_config.yaml' \
        --exclude='custom_load/' \
        "$SRC_DIR/" "$DST_ROOT/"
    
    echo "✅ Application files moved to $DST_ROOT, preserving custom files."
    
    # Delete the temporary installation source folder
    rm -rf "$SRC_DIR"
    echo "✅ Cleaned up installation source directory."

    # --- 10. Create Global Command Access ---
    print_step "Setting up global 'msg' command access..."
    
    DISPATCHER_PATH="$FINAL_BIN_PATH/dispatcher"
    SYMLINK_TARGET="/usr/local/bin/msg"
    
    # Make the dispatcher executable
    chmod +x "$DISPATCHER_PATH"
    
    # Try to create symlink in /usr/local/bin (requires appropriate permissions)
    if [ -w "/usr/local/bin" ] 2>/dev/null; then
        ln -sf "$DISPATCHER_PATH" "$SYMLINK_TARGET" 2>/dev/null && {
            echo "✅ Global symlink created: $SYMLINK_TARGET -> $DISPATCHER_PATH"
        } || {
            echo "⚠️  Warning: Failed to create global symlink, will add to PATH instead."
            setup_path_modification
        }
    else
        echo "ℹ️  No write access to /usr/local/bin, adding to user PATH instead."
        setup_path_modification
    fi
    
    # Return the dependency exit code to preserve warnings
    exit $DEPENDENCY_EXIT_CODE
}


# Function to add msg to user's PATH via shell profile
setup_path_modification() {
    local shell_profile=""
    local msg_bin_path="$FINAL_BIN_PATH"
    
    # Detect user's shell and appropriate profile file
    case "$SHELL" in
        */zsh) shell_profile="$HOME/.zshrc" ;;
        */bash) shell_profile="$HOME/.bashrc" ;;
        */fish) shell_profile="$HOME/.config/fish/config.fish" ;;
        *) shell_profile="$HOME/.profile" ;;  # Fallback
    esac
    
    # Check if PATH modification already exists
    if [ -f "$shell_profile" ] && grep -q "/.msg/bin" "$shell_profile"; then
        echo "✅ PATH already configured in $shell_profile"
        # Update current session PATH even if already configured
        export PATH="$msg_bin_path:$PATH"
        return
    fi
    
    # Add PATH modification to shell profile
    echo "" >> "$shell_profile"
    echo "# Added by msg installer" >> "$shell_profile"
    echo "export PATH=\"$msg_bin_path:\$PATH\"" >> "$shell_profile"
    
    echo "✅ Added $msg_bin_path to PATH in $shell_profile"
    
    # Update PATH for current session
    export PATH="$msg_bin_path:$PATH"
    echo "✅ Updated PATH for current session"
    
    # Attempt to notify user about sourcing based on their shell
    local current_shell=$(basename "$SHELL")
    echo ""
    echo "📝 To use 'msg' in other open terminals, either:"
    echo "   1. Restart your terminal, or"
    echo "   2. Run: source $shell_profile"
    echo ""
    echo "🎉 You can use 'msg' command immediately in THIS terminal!"
    
}


main "$@"


# Disable trap upon successful completion
trap - ERR