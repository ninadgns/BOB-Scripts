#!/bin/bash
# BOB Server Startup Script
# This script asks for IP, updates configuration, and starts the Python HTTP server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to get current IP addresses
get_available_ips() {
    echo "Available IP addresses on this system:"
    echo "----------------------------------------"
    
    # Get all IP addresses (excluding loopback and docker)
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | while read ip; do
        interface=$(ip route get "$ip" | awk '{print $3}' | head -1)
        echo "  $ip (interface: $interface)"
    done
    
    echo "  127.0.0.1 (localhost)"
    echo "----------------------------------------"
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

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1  # Port is in use
    else
        return 0  # Port is available
    fi
}

# Function to find available port
find_available_port() {
    local start_port=$1
    local port=$start_port
    
    while ! check_port $port; do
        port=$((port + 1))
        if [ $port -gt $((start_port + 100)) ]; then
            print_color $RED "No available ports found starting from $start_port"
            exit 1
        fi
    done
    
    echo $port
}

# Main script
print_color $BLUE "=========================================="
print_color $BLUE "        BOB Server Startup Script"
print_color $BLUE "=========================================="
echo ""

# Show current configuration
print_color $YELLOW "Current configuration:"
source "${SCRIPT_DIR}/config.sh" 2>/dev/null || true
if [ -n "$SERVER_IP" ]; then
    echo "  Server IP: $SERVER_IP"
    echo "  Server Port: $SERVER_PORT"
    echo "  Server URL: $SERVER_URL"
else
    echo "  No configuration found"
fi
echo ""

# Show available IPs
get_available_ips
echo ""

# Get IP from user
while true; do
    read -p "Enter server IP address (or press Enter for current IP): " input_ip
    
    if [ -z "$input_ip" ]; then
        # Use current IP or default
        if [ -n "$SERVER_IP" ]; then
            new_ip="$SERVER_IP"
        else
            new_ip="127.0.0.1"
        fi
        break
    elif validate_ip "$input_ip"; then
        new_ip="$input_ip"
        break
    else
        print_color $RED "Invalid IP address format. Please try again."
    fi
done

# Get port from user
while true; do
    read -p "Enter server port (or press Enter for 8000): " input_port
    
    if [ -z "$input_port" ]; then
        new_port="8000"
        break
    elif [[ "$input_port" =~ ^[0-9]+$ ]] && [ "$input_port" -ge 1 ] && [ "$input_port" -le 65535 ]; then
        new_port="$input_port"
        break
    else
        print_color $RED "Invalid port number. Please enter a number between 1-65535."
    fi
done

# Check if port is available
if ! check_port $new_port; then
    print_color $YELLOW "Port $new_port is already in use."
    read -p "Would you like to find an available port? (y/n): " find_port
    
    if [[ "$find_port" =~ ^[Yy]$ ]]; then
        new_port=$(find_available_port $new_port)
        print_color $GREEN "Using port $new_port instead."
    else
        print_color $RED "Exiting. Please choose a different port."
        exit 1
    fi
fi

echo ""
print_color $YELLOW "Updating configuration..."

# Update configuration
cat > "${SCRIPT_DIR}/config.sh" << EOF
#!/bin/bash
# BOB Configuration File
# Centralized configuration for all BOB scripts

# Server Configuration
SERVER_IP="$new_ip"
SERVER_PORT="$new_port"
SERVER_URL="http://\${SERVER_IP}:\${SERVER_PORT}"

# Export variables for use in other scripts
export SERVER_IP
export SERVER_PORT  
export SERVER_URL

# Function to get server URL
get_server_url() {
    echo "\$SERVER_URL"
}

# Function to get server IP
get_server_ip() {
    echo "\$SERVER_IP"
}

# Function to get server port
get_server_port() {
    echo "\$SERVER_PORT"
}
EOF

# Regenerate index.html
print_color $YELLOW "Regenerating index.html..."
"${SCRIPT_DIR}/generate_index.sh"

print_color $GREEN "Configuration updated successfully!"
print_color $GREEN "Server URL: http://$new_ip:$new_port"
echo ""

# Start the server
print_color $BLUE "Starting Python HTTP server..."
print_color $YELLOW "Press Ctrl+C to stop the server"
echo ""

# Change to script directory
cd "$SCRIPT_DIR"

# Start Python HTTP server
print_color $GREEN "Server is running at: http://$new_ip:$new_port"
print_color $GREEN "Access the web interface at: http://$new_ip:$new_port/index.html"
echo ""

# Use Python 3 if available, otherwise Python 2
if command -v python3 &> /dev/null; then
    python3 -m http.server $new_port --bind $new_ip
else
    python -m SimpleHTTPServer $new_port
fi
