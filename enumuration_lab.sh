#!/bin/bash

# Define target IP addresses
TARGETS=("44.106.251.30" "44.106.251.40" "44.106.251.60")

# Output directory for saving results
OUTPUT_DIR="enum_results"
mkdir -p "$OUTPUT_DIR"

# Function to perform enumeration on a single target
enumerate_target() {
    local target=$1
    local output_file="$OUTPUT_DIR/enum_$target.txt"

    echo "[*] Starting enumeration on target: $target"
    echo "============================================"

    # Initial TCP scan to identify open ports
    echo "[*] Running initial TCP scan on $target..."
    nmap -p- -T4 --open -oN "$output_file" "$target"

    # Extract open ports from the initial scan
    open_ports=$(grep -oP '\d+/tcp' "$output_file" | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')

    if [[ -z "$open_ports" ]]; then
        echo "[!] No open TCP ports found on $target. Skipping further enumeration."
        return
    fi

    # Perform detailed service and version detection on open ports
    echo "[*] Running service and version detection on open ports: $open_ports..."
    nmap -p "$open_ports" -sV -sC -O -oN "$output_file" "$target"

    # Check for web services (HTTP/HTTPS)
    if grep -q -E '80/tcp|443/tcp' "$output_file"; then
        echo "[*] Web services detected. Running additional HTTP enumeration..."
        nikto -h "$target" -output "$OUTPUT_DIR/nikto_$target.txt"
    fi

    echo "[*] Enumeration completed for target: $target"
    echo "============================================"
    echo ""
}

# Main loop to enumerate all targets
for target in "${TARGETS[@]}"; do
    enumerate_target "$target"
done

echo "[*] Enumeration completed for all targets. Results saved in $OUTPUT_DIR."
