#!/bin/bash
# Save as dynamic-toph-firewall.sh

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
echo "--------------------------------"
sudo bash $IPTABLES_RULES_FILE

# Save the rules to make them persistent
echo "Saving iptables rules..."
sudo iptables-save > /etc/iptables/rules.v4
sudo ip6tables-save > /etc/iptables/rules.v6

echo "Done! Rules have been applied and saved."

