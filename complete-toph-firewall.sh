#!/bin/bash
# Complete TOPH Firewall Setup with Persistence
# This script combines firewall setup and persistence in one go

ALLOWED_DOMAINS_FILE="/toph_domains.txt"
IPTABLES_RULES_FILE="/toph_iptables.sh"

# Function to get all IPs for a domain
get_domain_ips() {
    local domain=$1
    dig +short $domain A
    dig +short $domain AAAA 2>/dev/null
}

# Common domains that toph.co might use (update after analysis)
DOMAINS=(
    "toph.co"
    "www.toph.co"
    "api.toph.co"
    "cdn.toph.co"
    # Add CDN providers commonly used
    "cloudflare.com"
    "fastly.com"
    "amazonaws.com"
    "googleusercontent.com"
    "gstatic.com"
    "jsdelivr.net"
    "cdnjs.cloudflare.com"
)

echo "Setting up complete TOPH firewall with persistence..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Step 1: Install iptables-persistent BEFORE blocking internet
echo "Installing iptables-persistent..."
apt update
apt install -y iptables-persistent

# Create iptables directory if it doesn't exist
mkdir -p /etc/iptables

# Step 2: Create the systemd service file
echo "Creating systemd service..."
cat > /etc/systemd/system/toph-firewall.service << 'EOF'
[Unit]
Description=TOPH Dynamic Firewall Service
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=/complete-toph-firewall.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable the service
systemctl daemon-reload
systemctl enable toph-firewall.service

# Step 3: Generate firewall rules
echo "Generating firewall rules..."
echo "#!/bin/bash" > $IPTABLES_RULES_FILE
echo "# Auto-generated iptables rules for toph.co" >> $IPTABLES_RULES_FILE
echo "" >> $IPTABLES_RULES_FILE

# Flush and set defaults
echo "iptables -F OUTPUT" >> $IPTABLES_RULES_FILE
echo "iptables -P OUTPUT DROP" >> $IPTABLES_RULES_FILE
echo "" >> $IPTABLES_RULES_FILE

# Basic rules
echo "# Allow loopback and established connections" >> $IPTABLES_RULES_FILE
echo "iptables -A OUTPUT -o lo -j ACCEPT" >> $IPTABLES_RULES_FILE
echo "iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT" >> $IPTABLES_RULES_FILE
echo "" >> $IPTABLES_RULES_FILE

# DNS
echo "# Allow DNS" >> $IPTABLES_RULES_FILE
echo "iptables -A OUTPUT -p udp --dport 53 -j ACCEPT" >> $IPTABLES_RULES_FILE
echo "iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT" >> $IPTABLES_RULES_FILE
echo "" >> $IPTABLES_RULES_FILE

# Process each domain
for domain in "${DOMAINS[@]}"; do
    echo "Processing domain: $domain"
    echo "# Rules for $domain" >> $IPTABLES_RULES_FILE
    
    for ip in $(get_domain_ips $domain); do
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "iptables -A OUTPUT -d $ip -p tcp --dport 80 -j ACCEPT" >> $IPTABLES_RULES_FILE
            echo "iptables -A OUTPUT -d $ip -p tcp --dport 443 -j ACCEPT" >> $IPTABLES_RULES_FILE
        fi
    done
    echo "" >> $IPTABLES_RULES_FILE
done

# Step 4: Apply firewall rules
echo "Applying firewall rules..."
bash $IPTABLES_RULES_FILE

# Step 5: Save the rules to make them persistent
echo "Saving iptables rules..."
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Step 6: Copy this script to root for systemd service
cp "$0" /complete-toph-firewall.sh
chmod +x /complete-toph-firewall.sh

echo "--------------------------------"
echo "Complete TOPH firewall setup finished!"
echo "The firewall is now active and will persist across reboots."
echo ""
echo "To manually control the service:"
echo "  sudo systemctl start toph-firewall"
echo "  sudo systemctl stop toph-firewall"
echo "  sudo systemctl status toph-firewall"
echo ""
echo "To reset firewall (allow all internet):"
echo "  sudo /reset.sh"
