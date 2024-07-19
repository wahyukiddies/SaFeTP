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

# 1. Cek apakah service bind9 ada atau tidak.
is_bind9_exist=$(systemctl list-unit-files | grep -w bind9.service | awk '{print $1}')

# 2. Uninstall program vsftpd dan bind9 (jika ada).
if [[ $is_bind9_exist == "bind9.service" ]]; then
  # Stop service terlebih dahulu.
  echo "[+] Menghentikan service vsftpd dan bind9 terlebih dahulu"
  sudo systemctl stop -q vsftpd.service
  sudo systemctl stop -q bind9.service
  sleep 0.5 # Tunggu 0.5 detik.
  echo "[+] Service vsftpd dan bind9 berhasil dihentikan"

  # Setelah itu, hapus program vsftpd dan bind9.
  echo "[+] Menghapus program vsftpd dan bind9"
  sudo apt autoremove -y vsftpd bind9 &> /dev/null
  sleep 0.5 # Tunggu 0.5 detik.
  echo "[+] Program vsftpd dan bind9 berhasil dihapus"
else
  # Stop service terlebih dahulu
  echo "[+] Menghentikan service vsftpd terlebih dahulu"
  sudo systemctl stop -q vsftpd.service
  sleep 0.5 # Tunggu 0.5 detik.
  echo "[+] Service vsftpd berhasil dihentikan"

  # Setelah itu, hapus program vsftpd dan bind9.
  echo "[+] Menghapus program vsftpd"
  sudo apt autoremove -y vsftpd
  sleep 0.5 # Tunggu 0.5 detik.
  echo "[+] Program vsftpd berhasil dihapus"
fi

# 3. Hapus semua user FTP.
echo "[+] Menghapus semua user FTP"
grep -v '^\s*$' /etc/safetp/allowed | sort | uniq | while IFS= read -r username; do
  sudo userdel -r $username 2>/dev/null
done
sleep 0.5 # Tunggu 0.5 detik.
echo "[+] Semua user FTP berhasil dihapus"

# 4. Hapus semua file yang ada di dalam folder /etc/safetp 
echo "[+] Menghapus folder 'safetp' dan semua file di dalamnya"
sudo rm -rf /etc/safetp
sleep 0.5 # Tunggu 0.5 detik.
echo "[+] Folder "safetp" dan semua file di dalamnya berhasil dihapus"

# 5. Hapus file backup "/etc/vsftpd.conf.default"
echo "[+] Menghapus file backup 'vsftpd.conf.default'"
if [ -f /etc/vsftpd.conf.default ]; then
  sudo rm -f /etc/vsftpd.conf.default
  sleep 0.5 # Tunggu 0.5 detik.
  echo "[+] File backup 'vsftpd.conf.default' berhasil dihapus"
else
  echo "[-] File backup 'vsftpd.conf.default' tidak ditemukan"
fi

# 6. Hapus self-signed SSL certificate.
echo "[+] Menghapus sertifikat SSL"
if [ -f /etc/ssl/certs/safetp.crt ]; then
  sudo rm -f /etc/ssl/certs/safetp.crt
  echo "[+] Sertifikat SSL 'safetp.crt' berhasil dihapus"
  sleep 0.5 # Tunggu 0.5 detik.
else
  echo "[-] Sertifikat SSL 'safetp.crt' tidak ditemukan"
fi

if [ -f /etc/ssl/private/safetp.key ]; then
  sudo rm -f /etc/ssl/private/safetp.key
  echo "[+] Sertifikat SSL 'safetp.key' berhasil dihapus"
  sleep 0.5 # Tunggu 0.5 detik.
else
  echo "[-] Sertifikat SSL 'safetp.key' tidak ditemukan"
fi

echo -e "\e[32m[OK] Uninstall program safetp berhasil\e[1m"