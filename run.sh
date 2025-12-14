#!/bin/bash

url="$1"

set -eou pipefail

if [ -z "$url" ]; then 
	echo "Usage : $0 <domain>"
	exit 1
fi

echo "[+] Setting up directories..."
mkdir -p "$url/recon/wayback"

echo "[+] Harvesting subdomains with assetfinder..."
assetfinder --subs-only "$url" | sort -u > "$url/recon/asset.txt"

echo "[+] Harvesting subdomains with Amass..."
amass enum -d "$url" -silent | sort -u > "$url/recon/amass.txt"

echo "[+] Combining subdomains..."
cat "$url/recon/"{asset,amass}.txt | sort -u > "$url/recon/final.txt"
rm "$url/recon/"{asset,amass}.txt

echo "[+] Probing for alive domains..."
cat "$url/recon/final.txt" | httprobe -s -p https:443 -p http:80 | sed 's|https\?://||' | sort -u > "$url/recon/alive.txt"

echo "[+] Pulling Wayback URLs..."
cat "$url/recon/alive.txt" | waybackurls > "$url/recon/wayback/wayback_output.txt"

echo "[+] Extracting parameters..."
grep '\?' "$url/recon/wayback/wayback_output.txt" | cut -d '?' -f2 | tr '&' '\n' | cut -d "=" -f1 | sort -u > "$url/recon/wayback/wayback_params.txt"

echo "[+] Done!"
echo "Alive domains saved in : $url/recon/alive.txt"


