#!/bin/bash

# Initialize files/directories
mkdir -p screenshots
> live.txt
> ports.txt
> enumerated.txt
> web.html

# Scan 1: Live Host Detection
echo "Enter target(s) (CIDR, range, or list):"
read targets
nmap -sn -n $targets | awk '/Up$/{print $2}' > live.txt

# Scan 2: Port Scanning
echo "Scanning open ports..."
while read ip; do
    nmap -T4 -p- $ip | awk -v ip="$ip" '/open/{print ip":"$1}' >> ports.txt
done < live.txt

# Scan 3: Service/OS Detection
echo "Enumerating services..."
nmap -O -sV -iL live.txt -oN enumerated.txt

# Web Screenshots
echo "Capturing web screenshots..."
while read ip; do
    curl -s "http://$ip" -m 3 && \
        cutycapt --url=http://$ip --out=screenshots/${ip}-80.png
    curl -s "https://$ip" -m 3 && \
        cutycapt --url=https://$ip --out=screenshots/${ip}-443.png
done < live.txt

# Generate HTML report
echo "<html><body>" > web.html
find screenshots -name '*.png' | while read img; do
    echo "<h2>${img}</h2><img src='${img}'><hr>" >> web.html
done
echo "</body></html>" >> web.html

echo "Scan completed!"
