#!/bin/bash

# Function to validate IP address format
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to get target input
get_targets() {
    echo "Enter target(s) to scan:"
    read targets

    if [[ $targets == *"/"* ]]; then
        echo $targets
    elif [[ $targets == *"-"* ]]; then
        IFS='-' read -ra ADDR <<< "$targets"
        echo "${ADDR[0]%.*}.${ADDR[0]##*.}-${ADDR[1]}"
    elif [[ $targets == *","* ]]; then
        IFS=',' read -ra ADDR <<< "$targets"
        for i in "${ADDR[@]}"; do
            if validate_ip $i; then
                echo $i
            else
                echo "Invalid IP: $i"
                exit 1
            fi
        done
    else
        echo "Invalid input format"
        exit 1
    fi
}

# Get targets
targets=$(get_targets)

# Scan 1: Check for live hosts
nmap -sn $targets -oG - | awk '/Up$/{print $2}' > live.txt

# Scan 2: Check for open ports on live hosts
while read ip; do
    nmap -p- $ip | awk '/^[0-9]/{print "'$ip' "$1" "$3}' >> ports.txt
done < live.txt

# Scan 3: Identify OS, services, and versions
while read ip; do
    nmap -O -sV $ip >> enumerated.txt
done < live.txt

# Scan 4: Take screenshots of web services
mkdir -p screenshots
echo "<html><body>" > web.html
while read ip; do
    if nmap -p 80,443 $ip | grep -q "open"; then
        cutycapt --url=http://$ip --out=screenshots/$ip.png
        echo "<img src='screenshots/$ip.png'><br>" >> web.html
        cutycapt --url=https://$ip --out=screenshots/$ip_https.png
        echo "<img src='screenshots/$ip_https.png'><br>" >> web.html
    fi
done < live.txt
echo "</body></html>" >> web.html

echo "Scanning complete. Check live.txt, ports.txt, enumerated.txt, and web.html for results."
