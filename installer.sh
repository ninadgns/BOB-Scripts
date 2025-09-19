#!/bin/bash
set -e

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [SERVER_IP]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -p, --port     Specify server port (default: 8000)"
    echo ""
    echo "Arguments:"
    echo "  SERVER_IP      IP address of the server (optional)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Auto-detect server IP"
    echo "  $0 192.168.1.100                     # Use specific IP"
    echo "  $0 -p 8080 192.168.1.100            # Use specific IP and port"
    echo "  $0 --port 9000 10.0.19.81           # Use specific IP and port"
    echo ""
}

# Function to detect server IP from the download URL
detect_server_ip() {
    # Try to get IP from the referrer or current connection
    local server_ip=""
    
    # Method 1: Try to get IP from wget referrer (if available)
    if [ -n "$HTTP_REFERER" ]; then
        server_ip=$(echo "$HTTP_REFERER" | sed -n 's|http://\([^:]*\):.*|\1|p')
    fi
    
    # Method 2: Try to get IP from network interfaces
    if [ -z "$server_ip" ]; then
        server_ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    fi
    
    # Default fallback
    if [ -z "$server_ip" ]; then
        server_ip="127.0.0.1"
    fi
    
    echo "$server_ip"
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local IFS='.'
        local -a ip_parts=($ip)
        for part in "${ip_parts[@]}"; do
            if ((part > 255)); then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Function to install package if not already installed
install_if_missing() {
    local pkg_name="$1"
    local check_command="$2"
    local deb_filename="$3"
    local server_ip="$4"
    local server_port="${5:-8000}"
    
    if command -v "$check_command" &>/dev/null; then
        echo "$pkg_name is already installed."
    else
        echo "$pkg_name not found. Downloading from server..."
        local deb_url="http://${server_ip}:${server_port}/installer_pkgs/${deb_filename}"
        local deb_path="/tmp/${deb_filename}"
        
        if wget -qO "$deb_path" "$deb_url"; then
            echo "Downloaded $deb_filename successfully."
            sudo dpkg -i "$deb_path" || sudo apt-get -f install -y
            rm -f "$deb_path"
        else
            echo "Failed to download $deb_filename from server. Trying apt-get download..."
            apt-get download "$pkg_name" 2>/dev/null || {
                echo "Warning: Could not download $pkg_name. Skipping..."
                return 1
            }
            local downloaded_deb=$(ls ${pkg_name}_*.deb 2>/dev/null | head -1)
            if [ -n "$downloaded_deb" ]; then
                sudo dpkg -i "$downloaded_deb" || sudo apt-get -f install -y
                rm -f "$downloaded_deb"
            fi
        fi
    fi
}

# Parse command line arguments
SERVER_IP=""
SERVER_PORT="8000"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -p|--port)
            SERVER_PORT="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [ -z "$SERVER_IP" ]; then
                SERVER_IP="$1"
            else
                echo "Multiple IP addresses provided. Please specify only one."
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate IP if provided
if [ -n "$SERVER_IP" ]; then
    if ! validate_ip "$SERVER_IP"; then
        echo "Error: Invalid IP address format: $SERVER_IP"
        echo "Please provide a valid IPv4 address (e.g., 192.168.1.100)"
        exit 1
    fi
    echo "Using provided server IP: $SERVER_IP"
else
    echo "No IP provided, auto-detecting server configuration..."
    SERVER_IP=$(detect_server_ip)
    echo "Detected server IP: $SERVER_IP"
fi

SERVER_URL="http://${SERVER_IP}:${SERVER_PORT}"
echo "Using server: $SERVER_URL"
echo "Installing packages..."

# Install packages from server
install_if_missing "wget" "wget" "wget_1.21.4-1ubuntu4.1_amd64.deb" "$SERVER_IP" "$SERVER_PORT"
install_if_missing "gpg" "gpg" "gpg_2.4.4-2ubuntu17.3_amd64.deb" "$SERVER_IP" "$SERVER_PORT"
install_if_missing "build-essential" "gcc" "build-essential_12.10ubuntu1_amd64.deb" "$SERVER_IP" "$SERVER_PORT"
install_if_missing "gdb" "gdb" "gdb_15.0.50.20240403-0ubuntu1_amd64.deb" "$SERVER_IP" "$SERVER_PORT"
install_if_missing "codeblocks" "codeblocks" "codeblocks_20.03+svn13046-0.3build2_amd64.deb" "$SERVER_IP" "$SERVER_PORT"
install_if_missing "codeblocks-contrib" "codeblocks" "codeblocks-contrib_20.03+svn13046-0.3build2_amd64.deb" "$SERVER_IP" "$SERVER_PORT"
install_if_missing "python3" "python3" "python3_3.12.3-0ubuntu2_amd64.deb" "$SERVER_IP" "$SERVER_PORT"
install_if_missing "openjdk-11-jdk" "javac" "openjdk-11-jdk_11.0.28+6-1ubuntu1~24.04.1_amd64.deb" "$SERVER_IP" "$SERVER_PORT"

# VS Code install
if command -v code &>/dev/null; then
    echo "VS Code is already installed."
else
    echo "Installing VS Code from server..."
    vscode_deb="/tmp/code_latest_amd64.deb"
    if wget -qO "$vscode_deb" "${SERVER_URL}/installer_pkgs/code_latest_amd64.deb"; then
        sudo dpkg -i "$vscode_deb" || sudo apt-get -f install -y
        rm -f "$vscode_deb"
    else
        echo "Failed to download VS Code from server. Downloading from internet..."
        wget -O "$vscode_deb" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
        sudo dpkg -i "$vscode_deb" || sudo apt-get -f install -y
        rm -f "$vscode_deb"
    fi
fi

# Sublime Text install
if command -v subl &>/dev/null; then
    echo "Sublime Text is already installed."
else
    echo "Installing Sublime Text from server..."
    sublime_deb="/tmp/sublime-text_latest_amd64.deb"
    if wget -qO "$sublime_deb" "${SERVER_URL}/installer_pkgs/sublime-text_latest_amd64.deb"; then
        sudo dpkg -i "$sublime_deb" || sudo apt-get -f install -y
        rm -f "$sublime_deb"
    else
        echo "Failed to download Sublime Text from server. Downloading from internet..."
        wget -O "$sublime_deb" "https://download.sublimetext.com/sublime-text_build-3211_amd64.deb"
        sudo dpkg -i "$sublime_deb" || sudo apt-get -f install -y
        rm -f "$sublime_deb"
    fi
fi

echo "All packages installed successfully!"
echo "resolving broken dependencies..."
sudo apt-get -f install -y
echo "All dependencies resolved successfully!"

