# Recon Automation Script

A Bash-based reconnaissance automation script for bug bounty hunting and security assessments.  
It performs **subdomain enumeration, service probing, takeover detection, scanning, fingerprinting, and historical URL collection** in a structured and repeatable way.

---

## Features

- Subdomain enumeration using **assetfinder** and **amass**
- Live host detection with **httprobe**
- Subdomain takeover checks via **subjack**
- Port and service scanning using **nmap**
- Web technology fingerprinting with **whatweb**
- Historical URL collection using **waybackurls**
- Parameter and interesting file extraction
- Optional web screenshots with **EyeWitness**
- Clean, organized output directory per target domain

---

## Requirements

The following tools must be installed and available in your `$PATH`:

- assetfinder  
- amass  
- httprobe  
- waybackurls  
- whatweb  
- nmap  
- subjack  
- python3 (for EyeWitness, optional)

### Optional
- EyeWitness (for screenshots and reporting)

> The script will exit if any required tool is missing.

---

## Installation

Clone the repository and make the script executable:

```bash
git clone https://github.com/yourusername/recon-script.git
cd recon-script
chmod +x recon.sh
```

Usage
```bash
./recon.sh <domain>
```

## Notes

- Uses set -euo pipefail for safer Bash execution
- EyeWitness is optional and skipped if not installed
- Designed for automation and repeatability

## Legal Disclaimer

- This tool is intended for authorized security testing only.
