#!/usr/bin/bash
#################################################################################
# THIS ADDITIONAL FILE IS USED TO AUTOMATICALLY CONFIGURING DNS SERVER IN LINUX #
# --------------------------------------------------------------------------------
# Run program: sudo bash dnsconfig.sh [server_ip_address]
#################################################################################

# Cek apakah parameter alamat IP DNS sudah diinputkan
if [ -z "$1" ]; then
  echo "[-] Alamat IP DNS server belum diinputkan!"
  echo "[-] Exit dari program!"
  exit 1
fi

echo "[+] Sedang mengkonfigurasi file 'resolv.conf'..."
echo "DNS=$1" | sudo tee -a /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
echo "[+] IP address DNS server berhasil ditambahkan ke file 'resolv.conf'"