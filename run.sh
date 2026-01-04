#!/bin/bash
set -euo pipefail

DOMAIN="${1:-}"

if [[ -z "$DOMAIN" ]]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

TOOLS=(assetfinder amass httprobe waybackurls whatweb nmap subjack)

for tool in "${TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        echo "[-] Missing required tool: $tool"
        exit 1
    fi
done

EYEWITNESS=$(command -v EyeWitness.py || true)

BASE="$DOMAIN/recon"
mkdir -p \
    "$BASE"/{scans,httprobe,wayback/{params,extensions},potential_takeovers,whatweb,eyewitness}

echo "[+] Running assetfinder..."
assetfinder --subs-only "$DOMAIN" | sort -u > "$BASE/assetfinder.txt"

echo "[+] Running amass..."
amass enum -d "$DOMAIN" -silent | sort -u > "$BASE/amass.txt"

echo "[+] Combining subdomains..."
cat "$BASE"/{assetfinder,amass}.txt | sort -u > "$BASE/final.txt"
rm "$BASE"/{assetfinder,amass}.txt

echo "[+] Probing for alive domains..."
cat "$BASE/final.txt" | \
    httprobe -s -p https:443 -p http:80 | \
    sort -u > "$BASE/httprobe/alive_urls.txt"

sed 's|https\?://||' "$BASE/httprobe/alive_urls.txt" > "$BASE/httprobe/alive_hosts.txt"

echo "[+] Checking for subdomain takeovers..."
SUBJACK_FP="$(dirname "$(command -v subjack)")/fingerprints.json"

subjack \
    -w "$BASE/httprobe/alive_hosts.txt" \
    -t 100 \
    -timeout 30 \
    -ssl \
    -c "$SUBJACK_FP" \
    -v 3 \
    -o "$BASE/potential_takeovers/takeovers.txt" || true

echo "[+] Running nmap..."
nmap -iL "$BASE/httprobe/alive_hosts.txt" -T4 -oA "$BASE/scans/nmap"

echo "[+] Running whatweb..."
while read -r host; do
    safe_host=$(echo "$host" | tr '/:' '_')
    mkdir -p "$BASE/whatweb/$safe_host"
    whatweb -v -t 50 "$host" > "$BASE/whatweb/$safe_host/output.txt"
done < "$BASE/httprobe/alive_hosts.txt"

echo "[+] Fetching Wayback URLs..."
cat "$BASE/httprobe/alive_hosts.txt" | waybackurls | sort -u > "$BASE/wayback/wayback_urls.txt"

echo "[+] Extracting parameters..."
grep '\?' "$BASE/wayback/wayback_urls.txt" | \
    cut -d '?' -f2 | tr '&' '\n' | cut -d '=' -f1 | \
    sort -u > "$BASE/wayback/params/params.txt"

echo "[+] Extracting interesting files..."
while read -r url; do
    clean_url="${url%%\?*}"
    ext="${clean_url##*.}"

    case "$ext" in
        js|php|json|aspx|jsp|html)
            echo "$url" >> "$BASE/wayback/extensions/$ext.txt"
            ;;
    esac
done < "$BASE/wayback/wayback_urls.txt"

for f in "$BASE/wayback/extensions/"*.txt; do
    [[ -f "$f" ]] && sort -u "$f" -o "$f"
done

if [[ -n "$EYEWITNESS" ]]; then
    echo "[+] Running EyeWitness..."
    python3 "$EYEWITNESS" \
        --web \
        -f "$BASE/httprobe/alive_urls.txt" \
        -d "$BASE/eyewitness" \
        --resolve \
        --no-prompt
else
    echo "[!] EyeWitness not found, skipping screenshots."
fi

echo "[✓] Recon complete!"
echo "[✓] Alive URLs   : $BASE/httprobe/alive_urls.txt"
echo "[✓] Alive Hosts  : $BASE/httprobe/alive_hosts.txt"
echo "[✓] Subdomains   : $BASE/final.txt"
echo "[✓] Wayback URLs : $BASE/wayback/wayback_urls.txt"
