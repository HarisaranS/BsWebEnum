#!/bin/bash

url=$1

if [ ! -d "$url" ]; then
		mkdir $url
fi

if [ ! -d "$url/recon" ]; then 
		mkdir $url/recon
fi

if [ ! -d "$url/recon/wayback" ]; then
		mkdir $url/recon/wayback
fi

echo "[+] Harvesting subdomains with assetfinder..."
assetfinder $url >> $url/recon/asset.txt
cat $url/recon/asset.txt | grep $url | sort -u >> $url/recon/final.txt
rm $url/recon/asset.txt

echo "[+] Harvesting subdomains with Amass..."
amass enum -d $url >> $url/recon/f.txt
sort -u $url/recon/f.txt >> $url/recon/final.txt
rm $url/recon/f.txt

echo "[+] Probing for alive domains..."
cat $url/recon/final.txt | httprobe -s | sed 's/:443$//' >> $url/recon/alive.txt

cat "$url/recon/wayback/wayback_output.txt" | grep '?*=' | cut -d '=' -f1 | sort -u > "$url/recon/wayback/wayback_params.txt"
echo "[+] Pulling and compiling all possible params..."
for line in $(cat "$url/recon/wayback/wayback_params.txt"); do echo "$line="; done

echo "[+] Done!"
echo "Alive domains saved in : $url/recon/alive.txt"


