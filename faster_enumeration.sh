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
    nmap -T3 -sS -sV -O $host >> enumerated.txt
done < live.txt
echo "[+] Enumeration results saved to enumerated.txt"

# Step 4: Take screenshots of websites running on port 80 or 443 
echo "[*] Checking for web servers on ports 80 or 443 and capturing screenshots..."
# Create screenshots directory if it doesn't exist
mkdir -p screenshots

# Start building the HTML file
cat <<EOF > web.html
<html>
  <head>
    <meta charset="UTF-8">
    <title>Website Screenshots</title>
  </head>
  <body>
    <h1>Website Screenshots</h1>
EOF

for host in $hosts; do
    # Check if port 80 (HTTP) is open
    if nc -z -w 1 "$host" 80 2>/dev/null; then
        echo "[*] $host: Port 80 is open. Capturing screenshot for http://$host..."
        xvfb-run -a cutycapt --url=http://$host --out=screenshots/${host}-80.png
        cat <<EOF >> web.html
    <h2>http://$host</h2>
    <img src="screenshots/${host}-80.png" alt="Screenshot of http://$host">
EOF
    fi

    # Check if port 443 (HTTPS) is open
    if nc -z -w 1 "$host" 443 2>/dev/null; then
        echo "[*] $host: Port 443 is open. Capturing screenshot for https://$host..."
        xvfb-run -a cutycapt --url=https://$host --out=screenshots/${host}-443.png
        cat <<EOF >> web.html
    <h2>https://$host</h2>
    <img src="screenshots/${host}-443.png" alt="Screenshot of https://$host">
EOF
    fi
done


# Finish the HTML file
cat <<EOF >> web.html
  </body>
</html>
EOF

echo "[+] Screenshots saved to screenshots/ directory and web.html created."

# Final message and cleanup instructions
echo "Script execution completed."
echo "Check the following files:"
echo "- live.txt: List of live hosts"
echo "- ports.txt: List of open ports on live hosts"
echo "- enumerated.txt: OS and service enumeration results"
echo "- web.html: HTML file with screenshots of websites"
