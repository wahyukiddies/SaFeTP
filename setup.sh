#!/usr/bin/bash
#################################################################
# JALANKAN FILE INI TERLEBIH DAHULU UNTUK MENGINSTAL DEPENDENSI |
# ------------------------------------------------------------- |
# Run program:                                                  |
# 1. chmod a+x setup.sh                                         |
# 2. sudo bash setup.sh                                         |
#################################################################

# Fungsi setup untuk cek internet, update, dan upgrade repositori
initial_setup() {
  echo "[+] Mengecek koneksi internet..."
  is_connected=$(ping -c 3 google.com &> /dev/null)
  if [ $? -eq 0 ]; then
    echo "[+] Koneksi internet OK"
    echo "[+] Update dan upgrade repositori sistem..."
    (sudo apt update && sudo apt upgrade -y) &> /dev/null
    echo "[+] Repositori sistem berhasil diperbarui"
  else
    echo "[-] Tidak ada koneksi internet!"
    echo "[-] Exit dari program!"
    exit 1
  fi
}

# Fungsi install dependensi yang dibutuhkan
install_dependensi() {
  echo "[+] Sedang menginstal dependensi..."
  sudo apt install -y lolcat nmap vsftpd openssl bind9 net-tools &> /dev/null
  sudo ln -s /usr/games/lolcat /usr/bin/lolcat
  wait # Tunggu hingga proses instalasi dependensi selesai.
  echo "[+] Dependensi berhasil diinstal"
}

main() {
  # Jalankan fungsi setup dan install dependensi
  initial_setup

  # Jalankan fungsi install dependensi
  install_dependensi
}

# Jalankan fungsi utama/main
main