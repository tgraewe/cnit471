#!/bin/bash

# Ensure the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Prompt user for target input
echo "Enter your target subnet or IP range (e.g., 192.168.0.0/24, 192.168.0.1-10, or 192.168.0.1,192.168.0.4):"
read targets

# Create output directories
mkdir -p screenshots

# Step 1: Scan for live hosts
echo "[*] Scanning for live hosts..."
nmap -sn $targets -oG - | awk '/Up$/{print $2}' > live.txt
echo "[+] Live hosts saved to live.txt"

# Step 2: Scan for open ports on live hosts
echo "[*] Scanning for open ports on live hosts..."
while read host; do
    nmap -p- --open $host | awk '/open/{print "'$host': " $1}' >> ports.txt
done < live.txt
echo "[+] Open ports saved to ports.txt"

# Step 3: Identify OS and services running on each port
echo "[*] Enumerating OS and services on live hosts..."
while read host; do
    nmap -sS -sV -O $host >> enumerated.txt
done < live.txt
echo "[+] Enumeration results saved to enumerated.txt"

# Step 4: Take screenshots of websites running on port 80 or 443
echo "[*] Taking screenshots of websites..."
echo "<html><body>" > web.html

while read host; do
    for port in 80 443; do
        if grep -q "$host:$port" ports.txt; then
            screenshot_file="screenshots/${host}_port${port}.png"
            url="http://$host"
            [[ $port -eq 443 ]] && url="https://$host"
            
            wkhtmltoimage --quiet $url $screenshot_file
            
            if [[ -f $screenshot_file ]]; then
                echo "<h3>$host:$port</h3><img src=\"$screenshot_file\" style=\"width:600px;\"><br>" >> web.html
            fi
        fi
    done
done < live.txt

echo "</body></html>" >> web.html

echo "[+] Screenshots saved to screenshots/ directory and web.html created."

# Start Apache server (optional)
echo "[*] Starting Apache server..."
systemctl start apache2 && echo "[+] Apache started."

# Final message and cleanup instructions
echo "Script execution completed."
echo "Check the following files:"
echo "- live.txt: List of live hosts"
echo "- ports.txt: List of open ports on live hosts"
echo "- enumerated.txt: OS and service enumeration results"
echo "- web.html: HTML file with screenshots of websites"
