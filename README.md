SoftEther VPN with Dynamic DNS Resolution
This project provides a setup for SoftEther VPN to dynamically assign .local DNS entries to VPN clients using dnsmasq. The configuration enables each VPN user to be reachable via a unique hostname (e.g., username.local) corresponding to their local IP address.

Features
Dynamic DNS Resolution: Automatically assigns and removes .local DNS entries for VPN clients based on their session status.
SecureNAT Support: Enables local IP assignment using SecureNAT in SoftEther.
Integration with dnsmasq: Provides flexible DNS resolution for .local domains.
Prerequisites
SoftEther VPN Server installed and configured.
dnsmasq for handling DNS requests.
Setup
1. Install dnsmasq
Ensure dnsmasq is installed on your system.

bash
Copy code
sudo apt update
sudo apt install dnsmasq
2. Configure dnsmasq
Edit the dnsmasq configuration to allow dynamic DNS updates:

bash
Copy code
sudo nano /etc/dnsmasq.conf
Add the following lines:

plaintext
Copy code
conf-dir=/etc/dnsmasq.d/,*.conf
Then create a file for VPN user entries:

bash
Copy code
sudo touch /etc/dnsmasq.d/vpn_users.conf
3. Configure the update_vpn_dns.sh Script
This script will retrieve the connected VPN users and their assigned local IPs, then update dnsmasq accordingly.

Place the script in /usr/local/bin/ and make it executable:

bash
Copy code
sudo chmod +x /usr/local/bin/update_vpn_dns.sh
Script Content
Here’s the core of the update_vpn_dns.sh script:

bash
Copy code
#!/bin/bash
# Path to the SoftEther vpncmd tool
VPNCMD_PATH="/usr/local/vpnserver/vpncmd"
HUB_NAME="your_hub_name"       # Replace with your actual hub name
PASSWORD="YOUR_PASSWORD"       # Replace with your SoftEther admin password
DNSMASQ_CONF="/etc/dnsmasq.d/vpn_users.conf"

# Clear existing entries
echo "" > $DNSMASQ_CONF

# Fetch IP table information and output results for debugging
echo "Fetching IP table information..."
$VPNCMD_PATH localhost /SERVER /PASSWORD:$PASSWORD /CMD <<EOF > /tmp/vpn_iptable_output.txt
Hub $HUB_NAME
IpTable
EOF

# Parse the IP table output for user sessions and IP addresses
user=""
while IFS="|" read -r key value; do
   key=$(echo "$key" | xargs)
   value=$(echo "$value" | xargs)
   
   if [[ "$key" == "Session Name" && "$value" =~ \[OPENVPN_L3\] ]]; then
       user=$(echo "$value" | sed -E 's/^SID-([^-]+)-.*$/\1/g' | tr '[:upper:]' '[:lower:]')
   elif [[ "$key" == "IP Address" && -n "$user" ]]; then
       ip=$(echo "$value" | sed -E 's/ \(.*\)//g')
       echo "address=/$user.local/$ip" >> $DNSMASQ_CONF
       user=""
   fi
done < /tmp/vpn_iptable_output.txt

# Restart dnsmasq to apply changes
echo "Restarting dnsmasq..."
sudo systemctl restart dnsmasq
4. Automate the Script
Set up a cron job to run the script every minute to update the DNS records dynamically.

bash
Copy code
sudo crontab -e
Add the following line:

plaintext
Copy code
* * * * * /usr/local/bin/update_vpn_dns.sh
5. Test DNS Resolution
After running the script, verify DNS entries by connecting a VPN client and pinging the assigned .local domain (e.g., ping username.local).

Troubleshooting
DNS Resolution Fails: Ensure dnsmasq is running and configured as the primary DNS resolver in /etc/resolv.conf.
Port Conflicts: Disable other services using port 53, such as systemd-resolved.
License
This project is licensed under the MIT License.

Replace "your_hub_name" and "YOUR_PASSWORD" in the script with actual values before use. This README provides the essential steps to set up SoftEther VPN with dnsmasq for dynamic local DNS resolution. Let me know if you'd like any further customization!
