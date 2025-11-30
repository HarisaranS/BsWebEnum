#!/bin/bash

url=$1

if [ ! -d "$url" ];then
			mkdir $url
fi

if [ ! -d "$url/recon" ];then 
			mkdir $url/recon
fi

echo "[+] Harvesting subdomains with assetfinder..."
assetfinder $url >> $url/recon/asset.txt
cat $url/recon/asset.txt | grep $url | sort -u >> $url/recon/final.txt
rm $url/recon/asset.txt
