#!/bin/bash
# Script to change server IP and regenerate index.html

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <new_server_ip> [port]"
    echo "Example: $0 192.168.1.100"
    echo "Example: $0 192.168.1.100 8080"
    echo ""
    echo "Current configuration:"
    source "${SCRIPT_DIR}/config.sh"
    echo "Server IP: $SERVER_IP"
    echo "Server Port: $SERVER_PORT"
    echo "Server URL: $SERVER_URL"
    exit 1
fi

NEW_IP="$1"
NEW_PORT="${2:-8000}"  # Default to 8000 if not provided

echo "Changing server IP from current to: $NEW_IP:$NEW_PORT"

# Update config.sh
cat > "${SCRIPT_DIR}/config.sh" << EOF
#!/bin/bash
# BOB Configuration File
# Centralized configuration for all BOB scripts

# Server Configuration
SERVER_IP="$NEW_IP"
SERVER_PORT="$NEW_PORT"
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
echo "Regenerating index.html..."
"${SCRIPT_DIR}/generate_index.sh"

echo "Configuration updated successfully!"
echo "New server URL: http://$NEW_IP:$NEW_PORT"

