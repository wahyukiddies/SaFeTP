#!/usr/bin/bash
###############################################################
# Script untuk automasi uninstall program safetp.             |
# -------------------------------------------------------------
# Versi: 1.0                                                  |
# Tanggal: 18 Juli 2024                                       |
# -------------------------------------------------------------
# Run program:                                                |
# 1. chmod a+x uninstall.sh                                   |
# 2. sudo bash uninstall.sh                                   |
############################################################### 

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

# 3. Uninstall program vsftpd dan bind9 (jika ada).
bind9_service=$(systemctl list-unit-files | grep -w bind9.service | awk '{print $1}')
if [ "$bind9_service" == "bind9.service" ]; then
  # Stop service terlebih dahulu.
  echo "[+] Menghentikan service vsftpd dan bind9 terlebih dahulu"
  sudo systemctl stop -q vsftpd.service
  sudo systemctl stop -q bind9.service
  sleep 0.5 # Tunggu 0.5 detik.

  # Setelah itu, hapus program vsftpd dan bind9.
  echo "[+] Clean install paket vsftpd dan bind9"
  (sudo apt autoremove -y vsftpd bind9 && sudo apt purge -y vsftpd bind9) &> /dev/null
  # Hapus folder konfigurasi bind9
  sudo rm -rf /etc/bind /var/cache/bind
  sleep 0.5 # Tunggu 0.5 detik.
else
  # Stop service terlebih dahulu
  echo "[+] Menghentikan service vsftpd terlebih dahulu"
  sudo systemctl stop -q vsftpd.service
  sleep 0.5 # Tunggu 0.5 detik.

  # Setelah itu, hapus program vsftpd dan bind9.
  echo "[+] Menghapus program vsftpd"
  (sudo apt autoremove -y vsftpd && sudo apt purge -y vsftpd) &> /dev/null
  sleep 0.5 # Tunggu 0.5 detik.
fi

# 4. Stop service grafana, loki, promtail, dan nginx.
echo "[+] Menghentikan service Grafana, loki, promtail, dan nginx"
sudo systemctl stop -q grafana-server.service && \
sudo systemctl daemon-reload && \
sudo systemctl stop -q promtail.service && \
sudo systemctl stop -q loki.service && \
sudo systemctl stop -q nginx.service
sleep 1 # Tunggu 1 detik.

# 5. Uninstall service grafana, loki, dan promtail.
echo "[+] Menghapus program Grafana, loki, dan promtail"
(sudo apt autoremove -y grafana loki promtail && sudo apt purge -y grafana loki promtail) &> /dev/null
sleep 0.5 # Tunggu 0.5 detik.

# 6. Hapus file konfigurasi promtail bawaan.
echo "[+] Menghapus file backup konfigurasi promtail"
if [ -f /etc/promtail/config.yml.default ]; then
  sudo rm -f /etc/promtail/config.yml.default
  sleep 0.5 # Tunggu 0.5 detik.
else
  echo "[-] File konfigurasi promtail tidak ditemukan. Skip!"
fi

# 6. Setelah itu, hapus program nginx.
echo "[+] Menghapus program nginx"
(sudo apt autoremove -y nginx && sudo apt purge -y nginx) &> /dev/null
sleep 0.5 # Tunggu 0.5 detik.

# 7. Menghapus folder instalasi SaFeTP Web.
echo "[+] Menghapus folder instalasi SaFeTP Web"

if [ -d /var/www/web ]; then
  sudo rm -rf /var/www/web
  sleep 0.5 # Tunggu 0.5 detik.
else
  echo "[-] Folder '/var/www/web' tidak ditemukan. Skip!"
fi

# 8. Hapus semua user FTP.
echo "[+] Menghapus semua user FTP"
grep -qv '^\s*$' /etc/safetp/allowed | sort | uniq | while IFS= read -r username; do
  sudo groupdel -f $username &> /dev/null
  sudo userdel -r $username &> /dev/null
done
sleep 0.5 # Tunggu 0.5 detik.

# 9. Hapus semua file yang ada di dalam folder /etc/safetp 
echo "[+] Menghapus folder '/etc/safetp' dan semua file di dalamnya"
sudo rm -rf /etc/safetp
sleep 0.5 # Tunggu 0.5 detik.

# 10. Hapus file backup "/etc/vsftpd.conf.default"
echo "[+] Menghapus file backup 'vsftpd.conf.default'"
if [ -f /etc/vsftpd.conf.default ]; then
  sudo rm -f /etc/vsftpd.conf.default
  sleep 0.5 # Tunggu 0.5 detik.
  echo "[+] File backup 'vsftpd.conf.default' berhasil dihapus"
else
  echo "[-] File backup 'vsftpd.conf.default' tidak ditemukan. Skip!"
fi

# 11. Hapus self-signed SSL certificate.
echo "[+] Menghapus sertifikat SSL"
if [ -f /etc/ssl/certs/safetp.crt ]; then
  sudo rm -f /etc/ssl/certs/safetp.crt
  echo "[+] Sertifikat SSL 'safetp.crt' berhasil dihapus"
  sleep 0.5 # Tunggu 0.5 detik.
else
  echo "[-] Sertifikat SSL 'safetp.crt' tidak ditemukan. Skip!"
fi

if [ -f /etc/ssl/private/safetp.key ]; then
  sudo rm -f /etc/ssl/private/safetp.key
  echo "[+] Sertifikat SSL 'safetp.key' berhasil dihapus"
  sleep 0.5 # Tunggu 0.5 detik.
else
  echo "[-] Sertifikat SSL 'safetp.key' tidak ditemukan. Skip!"
fi

if [ -f /etc/ssl/certs/safetp_web.crt ]; then
  sudo rm -f /etc/ssl/certs/safetp_web.crt
  echo "[+] Sertifikat SSL 'safetp_web.crt' berhasil dihapus"
  sleep 0.5 # Tunggu 0.5 detik.
else
  echo "[-] Sertifikat SSL 'safetp_web.crt' tidak ditemukan. Skip!"
fi

if [ -f /etc/ssl/private/safetp_web.key ]; then
  sudo rm -f /etc/ssl/private/safetp_web.key
  echo "[+] Sertifikat SSL 'safetp_web.key' berhasil dihapus"
  sleep 0.5 # Tunggu 0.5 detik.
else
  echo "[-] Sertifikat SSL 'safetp_web.key' tidak ditemukan. Skip!"
fi

echo -e "\e[32m[OK] Uninstall program safetp berhasil\e[1m"