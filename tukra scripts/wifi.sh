#!/bin/bash

# WiFi Restriction Management Script
# This script manages WiFi access restrictions for specific users using NetworkManager polkit rules

set -e  # Exit on any error

# Configuration
POLICY_DIR="/etc/polkit-1/localauthority/50-local.d"
POLICY_FILE="$POLICY_DIR/restrict-wifi.pkla"
SCRIPT_NAME="$(basename "$0")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_usage() {
    echo "Usage: $SCRIPT_NAME [OPTION] [USERNAME]"
    echo ""
    echo "Manage WiFi access restrictions for users using NetworkManager polkit rules."
    echo ""
    echo "OPTIONS:"
    echo "  add USERNAME      Add WiFi restriction for specified user"
    echo "  remove USERNAME   Remove WiFi restriction for specified user"
    echo "  list             List all users with WiFi restrictions"
    echo "  status USERNAME   Check WiFi restriction status for specified user"
    echo "  clear            Remove all WiFi restrictions"
    echo "  help             Display this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $SCRIPT_NAME add john        # Restrict WiFi for user 'john'"
    echo "  $SCRIPT_NAME remove john     # Remove WiFi restriction for user 'john'"
    echo "  $SCRIPT_NAME list            # List all restricted users"
    echo "  $SCRIPT_NAME status john     # Check if 'john' is restricted"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_networkmanager() {
    if ! systemctl is-active --quiet NetworkManager; then
        print_error "NetworkManager is not running. This script requires NetworkManager."
        exit 1
    fi
    print_info "NetworkManager is running"
}

user_exists() {
    local username="$1"
    if ! id "$username" &>/dev/null; then
        print_error "User '$username' does not exist"
        return 1
    fi
    return 0
}

create_policy_dir() {
    if [[ ! -d "$POLICY_DIR" ]]; then
        print_info "Creating polkit directory: $POLICY_DIR"
        mkdir -p "$POLICY_DIR"
    fi
}

backup_policy_file() {
    if [[ -f "$POLICY_FILE" ]]; then
        local backup_file="${POLICY_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Creating backup: $backup_file"
        cp "$POLICY_FILE" "$backup_file"
    fi
}

add_wifi_restriction() {
    local username="$1"
    
    if ! user_exists "$username"; then
        return 1
    fi
    
    # Check if user is already restricted
    if [[ -f "$POLICY_FILE" ]] && grep -q "unix-user:$username" "$POLICY_FILE"; then
        print_warning "User '$username' is already restricted from WiFi access"
        return 0
    fi
    
    create_policy_dir
    backup_policy_file
    
    print_info "Adding WiFi restriction for user '$username'"
    
    # Create or append to policy file
    cat >> "$POLICY_FILE" << EOF

[Deny WiFi for user $username]
Identity=unix-user:$username
Action=org.freedesktop.NetworkManager.wifi.*
ResultAny=no
ResultInactive=no
ResultActive=no
EOF
    
    # Set proper permissions
    chmod 644 "$POLICY_FILE"
    
    print_success "WiFi restriction added for user '$username'"
    print_info "User '$username' can still use wired connections"
    print_warning "Changes will take effect after the user logs out and back in"
}

remove_wifi_restriction() {
    local username="$1"
    
    if ! user_exists "$username"; then
        return 1
    fi
    
    if [[ ! -f "$POLICY_FILE" ]]; then
        print_warning "No WiFi restrictions are currently in place"
        return 0
    fi
    
    if ! grep -q "unix-user:$username" "$POLICY_FILE"; then
        print_warning "User '$username' does not have WiFi restrictions"
        return 0
    fi
    
    backup_policy_file
    
    print_info "Removing WiFi restriction for user '$username'"
    
    # Create temporary file without the user's restriction
    local temp_file=$(mktemp)
    local in_section=false
    local skip_section=false
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^\[.*user[[:space:]]+$username\] ]]; then
            skip_section=true
            continue
        elif [[ "$line" =~ ^\[ ]] && [[ "$skip_section" == true ]]; then
            skip_section=false
        fi
        
        if [[ "$skip_section" == false ]]; then
            echo "$line" >> "$temp_file"
        fi
    done < "$POLICY_FILE"
    
    # Replace original file with cleaned version
    mv "$temp_file" "$POLICY_FILE"
    chmod 644 "$POLICY_FILE"
    
    # Remove file if empty (except for whitespace)
    if [[ ! -s "$POLICY_FILE" ]] || [[ -z "$(grep -v '^[[:space:]]*$' "$POLICY_FILE")" ]]; then
        rm -f "$POLICY_FILE"
        print_info "Removed empty policy file"
    fi
    
    print_success "WiFi restriction removed for user '$username'"
    print_warning "Changes will take effect after the user logs out and back in"
}

list_restricted_users() {
    if [[ ! -f "$POLICY_FILE" ]]; then
        print_info "No WiFi restrictions are currently in place"
        return 0
    fi
    
    print_info "Users with WiFi restrictions:"
    echo ""
    
    local users_found=false
    while IFS= read -r line; do
        if [[ "$line" =~ Identity=unix-user:([^[:space:]]+) ]]; then
            echo "  - ${BASH_REMATCH[1]}"
            users_found=true
        fi
    done < "$POLICY_FILE"
    
    if [[ "$users_found" == false ]]; then
        print_info "No restricted users found"
    fi
}

check_user_status() {
    local username="$1"
    
    if ! user_exists "$username"; then
        return 1
    fi
    
    if [[ ! -f "$POLICY_FILE" ]]; then
        print_info "User '$username': No WiFi restrictions"
        return 0
    fi
    
    if grep -q "unix-user:$username" "$POLICY_FILE"; then
        print_warning "User '$username': WiFi access RESTRICTED"
    else
        print_info "User '$username': No WiFi restrictions"
    fi
}

clear_all_restrictions() {
    if [[ ! -f "$POLICY_FILE" ]]; then
        print_info "No WiFi restrictions to clear"
        return 0
    fi
    
    backup_policy_file
    
    print_warning "This will remove ALL WiFi restrictions for ALL users."
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$POLICY_FILE"
        print_success "All WiFi restrictions have been removed"
        print_warning "Changes will take effect after affected users log out and back in"
    else
        print_info "Operation cancelled"
    fi
}

# Main script logic
main() {
    case "${1:-}" in
        "add")
            if [[ -z "${2:-}" ]]; then
                print_error "Username required for add operation"
                print_usage
                exit 1
            fi
            check_root
            check_networkmanager
            add_wifi_restriction "$2"
            ;;
        "remove")
            if [[ -z "${2:-}" ]]; then
                print_error "Username required for remove operation"
                print_usage
                exit 1
            fi
            check_root
            check_networkmanager
            remove_wifi_restriction "$2"
            ;;
        "list")
            list_restricted_users
            ;;
        "status")
            if [[ -z "${2:-}" ]]; then
                print_error "Username required for status check"
                print_usage
                exit 1
            fi
            check_user_status "$2"
            ;;
        "clear")
            check_root
            clear_all_restrictions
            ;;
        "help"|"--help"|"-h")
            print_usage
            ;;
        "")
            print_error "No option specified"
            print_usage
            exit 1
            ;;
        *)
            print_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
