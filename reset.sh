#!/bin/bash
# Enhanced reset script that removes persistent firewall restrictions

echo "Resetting firewall and removing persistent restrictions..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Step 1: Disable and stop the persistent firewall service
echo "Disabling persistent firewall service..."
systemctl stop toph-firewall.service 2>/dev/null
systemctl disable toph-firewall.service 2>/dev/null

# Step 2: Remove the systemd service file
echo "Removing systemd service..."
rm -f /etc/systemd/system/toph-firewall.service
systemctl daemon-reload

# Step 3: Reset iptables rules
echo "Resetting iptables rules..."
iptables -F OUTPUT
iptables -P OUTPUT ACCEPT

# Step 4: Clear persistent iptables rules
echo "Clearing persistent iptables rules..."
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Step 5: Remove firewall script files
echo "Cleaning up firewall files..."
rm -f /complete-toph-firewall.sh
rm -f /toph_iptables.sh
rm -f /toph_domains.txt

echo "--------------------------------"
echo "✅ Firewall restrictions completely removed!"
echo "✅ Persistent firewall service disabled!"
echo "✅ Internet access fully restored!"
echo ""
echo "The system will no longer apply firewall restrictions on boot."