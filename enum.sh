if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <target IP or IP range>"
    exit 1
fi

TARGET="$1"

##############################
# Step 1: Live Host Discovery
##############################
echo "[*] Scanning for live hosts on $TARGET..."
# -sn performs a ping scan (no port scan)
nmap -sn "$TARGET" > live.txt
echo "[*] Live hosts saved to live.txt."

# Extract IP addresses from live.txt.
# This looks for lines like: "Nmap scan report for <hostname or IP>"
echo "[*] Extracting IP addresses from live.txt..."
hosts=$(grep "Nmap scan report for" live.txt | awk '{print $NF}')

if [ -z "$hosts" ]; then
    echo "[!] No live hosts found. Exiting."
    exit 1
fi

########################################
# Step 2: Open Port Scanning per Host
########################################
echo "[*] Scanning live hosts for open ports..."
# Create or clear ports.txt
: > ports.txt

for host in $hosts; do
    echo "Host: $host" >> ports.txt
    # Scan all TCP ports and output only open ones (--open)
    nmap -p- --open "$host" | grep -E '^[0-9]+/tcp' | awk '{print $1, $2, $3}' >> ports.txt
    echo "------------------------------" >> ports.txt
done
echo "[*] Open port scan results saved to ports.txt."

######################################################
# Step 3: OS Detection and Service/Version Enumeration
######################################################
echo "[*] Performing OS detection and service version enumeration..."
: > enumerated.txt

for host in $hosts; do
    echo "Host: $host" >> enumerated.txt
    # -O enables OS detection; -sV enables version detection
    nmap -O -sV "$host" >> enumerated.txt
    echo "------------------------------------" >> enumerated.txt
done
echo "[*] OS and service enumeration saved to enumerated.txt."

##################################################
# Step 4: Website Screenshot Capture with CutyCapt
##################################################
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

echo "[*] Website screenshots have been saved in the 'screenshots' directory and indexed in web.html."
echo "[*] All tasks completed."
