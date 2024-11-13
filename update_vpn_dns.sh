#!/bin/bash
# Path to the SoftEther vpncmd tool
VPNCMD_PATH="/usr/local/vpnserver/vpncmd"
HUB_NAME="VPN"       # Replace with your actual hub name
PASSWORD="13733731.Amir@"       # Replace with your SoftEther admin password
DNSMASQ_CONF="/etc/dnsmasq.d/vpn_users.conf"

# Clear existing entries
echo "" > $DNSMASQ_CONF

# Fetch IP table information and output results for debugging
echo "Fetching IP table information..."
$VPNCMD_PATH localhost /SERVER /PASSWORD:$PASSWORD /CMD <<EOF > /tmp/vpn_iptable_output.txt
Hub $HUB_NAME
IpTable
EOF

# Check the output
cat /tmp/vpn_iptable_output.txt

# Parse the IP table output for user sessions and IP addresses
user=""
while IFS="|" read -r key value; do
    key=$(echo "$key" | xargs)  # Trim whitespace
    value=$(echo "$value" | xargs)  # Trim whitespace
    
    if [[ "$key" == "Session Name" && "$value" =~ \[OPENVPN_L3\] ]]; then
        # Extract only the username part from the session name and convert to lowercase
        user=$(echo "$value" | sed -E 's/^SID-([^-]+)-.*$/\1/g' | tr '[:upper:]' '[:lower:]')
    elif [[ "$key" == "IP Address" && -n "$user" ]]; then
        # Extract the IP address, stripping any extra annotations like "(DHCP)"
        ip=$(echo "$value" | sed -E 's/ \(.*\)//g')
        echo "address=/$user.local/$ip" >> $DNSMASQ_CONF
        user=""  # Reset user after processing
    fi
done < /tmp/vpn_iptable_output.txt

# Restart dnsmasq to apply changes
echo "Restarting dnsmasq..."
sudo systemctl restart dnsmasq
