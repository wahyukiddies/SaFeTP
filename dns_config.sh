#!/usr/bin/bash
#####################################################################
# Script untuk automasi mengedit file /etc/resolv.conf di PC Client.|
# -------------------------------------------------------------------
# Versi: 1.0                                                        |
# Tanggal: 20 Juli 2024                                             |
# -------------------------------------------------------------------
# Run program:                                                      |
# 1. chmod a+x dns_config.sh                                        |
# 2. sudo bash dns_config.sh [server_ip_address]                    |
#####################################################################

# 1. Menampilkan banner program.
desain_banner="
           ______ _______ _____  
          |  ____|__   __|  __ \ 
 ___  __ _| |__ ___ | |  | |__) |
/ __|/ _\` |  __/ _ \| |  |  ___/ 
\__ \ (_| | | |  __/| |  | |     
|___/\__,_|_|  \___||_|  |_|     
v1.0 | Kelompok 4 - TMJ 4B
"
dpkg -l | grep lolcat &> /dev/null
[[ $? -ne 0 ]] && (echo "$desain_banner") || (echo "$desain_banner" | lolcat)

# 2. Cek apakah user menjalankan program ini sebagai root atau tidak.
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[-] Tolong jalankan program ini sebagai root!\e[1m"
  exit 1
fi

# 3. Cek apakah parameter alamat IP DNS sudah diinputkan
if [ -z "$1" ]; then
  echo "[-] Alamat IP DNS server belum diinputkan!"
  echo "[-] Exit dari program!"
  exit 1
fi

# 4. Menambahkan alamat IP DNS server ke file 'resolv.conf' 
echo "[+] Sedang mengkonfigurasi file 'resolv.conf'..."
echo "DNS=$1" | sudo tee -a /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
sleep 1 # Tunggu 1 detik.
echo -e "\e[32m[OK] IP address DNS server berhasil ditambahkan ke file 'resolv.conf'\e[1m"