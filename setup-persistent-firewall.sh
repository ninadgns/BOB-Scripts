#!/bin/bash
# Standalone script to set up persistent TOPH firewall
# This script can be downloaded and run independently

echo "Setting up persistent TOPH firewall..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install iptables-persistent if not already installed
echo "Installing iptables-persistent..."
apt update
apt install -y iptables-persistent

# Create iptables directory if it doesn't exist
mkdir -p /etc/iptables

# Create the systemd service file inline
echo "Creating systemd service..."
cat > /etc/systemd/system/toph-firewall.service << 'EOF'
[Unit]
Description=TOPH Dynamic Firewall Service
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=/dynamic-toph-firewall.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable the service
systemctl daemon-reload
systemctl enable toph-firewall.service

# Check if dynamic-toph-firewall.sh exists in the same directory
if [ -f "${SCRIPT_DIR}/dynamic-toph-firewall.sh" ]; then
    echo "Found dynamic-toph-firewall.sh in script directory, copying to root..."
    cp "${SCRIPT_DIR}/dynamic-toph-firewall.sh" /dynamic-toph-firewall.sh
    chmod +x /dynamic-toph-firewall.sh
    echo "Applying firewall rules..."
    /dynamic-toph-firewall.sh
else
    echo "dynamic-toph-firewall.sh not found in script directory."
    echo "Please ensure dynamic-toph-firewall.sh is in the same directory as this script."
    echo "Or download it separately and place it in /dynamic-toph-firewall.sh"
    exit 1
fi

echo "Persistent firewall setup complete!"
echo "The firewall will now automatically apply on boot."
echo ""
echo "To manually start/stop the service:"
echo "  sudo systemctl start toph-firewall"
echo "  sudo systemctl stop toph-firewall"
echo "  sudo systemctl status toph-firewall"
