#!/bin/bash

# Scan 1: Check for live hosts
nmap -sn 192.168.1.0/24 -oN live.txt

# Scan 2: Check for open ports on live hosts
awk '/Up$/{print $2}' live.txt | xargs -I % nmap -p- % -oN ports.txt

# Scan 3: Identify OS and services with versions
awk '/Up$/{print $2}' live.txt | xargs -I % nmap -O -sV % -oN enumerated.txt

# Scan 4: Take screenshots of web services
mkdir -p screenshots
echo "<html><body>" > web.html
while read -r ip; do
    if nmap -p 80,443 $ip | grep -q "open"; then
        cutycapt --url=http://$ip --out=screenshots/$ip.png
        echo "<img src='screenshots/$ip.png'><br>" >> web.html
        cutycapt --url=https://$ip --out=screenshots/$ip_https.png
        echo "<img src='screenshots/$ip_https.png'><br>" >> web.html
    fi
done < <(awk '/Up$/{print $2}' live.txt)
echo "</body></html>" >> web.html
