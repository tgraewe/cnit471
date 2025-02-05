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
