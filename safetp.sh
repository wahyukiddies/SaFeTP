#!/usr/bin/bash
###############################################################
# Tool automasi untuk melakukan instalasi & konfigurasi       |
# FTP Server (vsFTPd) dengan SSL (OpenSSL) supaya lebih aman, |
# dan DNS server (Bind9) untuk kemudahan akses ke FTP server. |
# -------------------------------------------------------------
# Telah diuji pada sistem operasi "Ubuntu Server 22.04.4 LTS" |
# -------------------------------------------------------------
# Author: Kelompok 4 - TMJ 4B                                 |
# 1. Muhammad Khairu Mufid / 2207421031                       |
# 2. Kevin Alonzo Manuel Bakara / 2207421032                  |
# 3. Wahyu Priambodo / 2207421048                             |
# 4. Rizki Alfarisi / 2207421053                              |
# 5. Muhammad Brian Azura Nixon / 2207421056                  |
# 6. Shaquille Arriza Hidayat / 2207421057                    |
# 7. Cornelius Yuli Rosdianto / 2207421059                    |
# -------------------------------------------------------------
# Versi: 1.0                                                  |
# Tanggal: 14 Juli 2024                                       |
# -------------------------------------------------------------
# Run program:                                                |
# 1. chmod a+x safetp.sh                                      |
# 2. sudo bash safetp.sh -l userlist.txt [OPTIONS...]         |
###############################################################

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
  # Dependensi yang dibutuhkan.
  sudo apt install -y lolcat nmap vsftpd openssl bind9 net-tools &> /dev/null
  # Buat simbolik link tool lolcat ke /usr/bin/lolcat (bisa juga dengan copy).
  sudo ln -s /usr/games/lolcat /usr/bin/lolcat
  wait # Tunggu hingga proses instalasi dependensi selesai.
  echo "[+] Dependensi berhasil diinstal"
}

# Fungsi banner untuk menampilkan informasi opsi-opsi yang tersedia pada program
banner() {
  desain_banner="
           ______ _______ _____  
          |  ____|__   __|  __ \ 
 ___  __ _| |__ ___ | |  | |__) |
/ __|/ _\` |  __/ _ \| |  |  ___/ 
\__ \ (_| | | |  __/| |  | |     
|___/\__,_|_|  \___||_|  |_|     
v1.0 | Kelompok 4 - TMJ 4B
"

  echo "$desain_banner" | lolcat

  echo "----------------------------------------------------"
  echo -e "Usage: sudo bash safetp.sh -l \$args [OPTIONS...]\n
  Options:\n
    -l, --userlist: File daftar user yang dapat mengakses server FTP (WAJIB!),\n
    -dir, --directory: Root direktori untuk tiap user (default: /home/\$user/ftp),\n
    -p, --port: Port untuk server FTP (default: 21),\n
    -ip, --ip-address: Alamat IP untuk DNS server,\n
    -d, --domain: Nama domain untuk DNS server,\n
    -h, --help: Menampilkan opsi yang tersedia\n"
  echo "----------------------------------------------------"
}

configure_ftp() {
  # 1. Cek service vsftpd apakah sudah berjalan atau belum.
  echo "[+] Mengecek status service FTP server..."
  sleep 0.5 # tunggu 0.5 detik.
  is_vsftpd_running=$(netstat -tanp | grep :21 &> /dev/null)
  if [ $? -eq 0 ]; then
    echo "[+] Service FTP server sudah berjalan"
  else
    echo "[-] Service FTP server belum berjalan"
    sudo systemctl start -q vsftpd.service
    sleep 1 # tunggu 1 detik.
    echo "[+] Service FTP server berhasil dijalankan"
  fi

  # 2. Matikan service FTP server terlebih dahulu.
  echo "[+] Menonaktifkan service FTP server..."
  sudo systemctl stop -q vsftpd.service
  sleep 0.5 # tunggu 0.5 detik.

  # 3. Backup file konfigurasi vsftpd.
  echo "[+] Backup file konfigurasi FTP server..."
  sudo mv -f /etc/vsftpd.conf /etc/vsftpd.conf.default
  sleep 0.5 # tunggu 0.5 detik.

  # 4. Mengkonfigurasi FTP server.
  echo "[+] Membuat file konfigurasi default FTP server..."
  # Membuat konfigurasi FTP server.
  sudo cat <<EOL | sudo tee -a /etc/vsftpd.conf > /dev/null
###########################################
# CREATED AUTOMATICALLY BY SAFETP PROGRAM #
###########################################

listen=YES
listen_ipv6=NO
listen_port=${PORT:-21}
anonymous_enable=NO
local_enable=YES
write_enable=YES
ftpd_banner=saFeTP : Layanan FTP Server
xferlog_enable=YES
log_ftp_protocol=YES
dirmessage_enable=YES
delete_failed_uploads=YES

# Konfigurasi chroot jail pada setiap user FTP yang diizinkan.
chroot_list_enable=YES
chroot_list_file=/etc/safetp/allowed
allow_writeable_chroot=YES

# Mengatur list user yang dapat mengakses FTP server.
userlist_enable=YES
userlist_deny=NO
userlist_file=/etc/safetp/allowed
user_config_dir=/etc/safetp/user_conf

# Konfigurasi SSL untuk tambahan lapisan keamanan.
rsa_cert_file=/etc/ssl/certs/safetp.crt
rsa_private_key_file=/etc/ssl/private/safetp.key
ssl_enable=YES
require_ssl_reuse=NO
ssl_ciphers=HIGH
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
EOL

  # Buat direktori sebagai tempat allowed userlist file.
  sudo mkdir -pm755 /etc/safetp

  # Copy file userlist ke direktori /etc/safetp/ dan ganti nama filenya menjadi 'allowed'.
  sudo cp -f "$USERLIST" /etc/safetp/allowed

  # Ganti permission allowed file agar tidak bisa dimodifikasi oleh user lain.
  sudo chmod 644 /etc/safetp/allowed

  # Buat direktori untuk user_conf.
  sudo mkdir -pm755 /etc/safetp/user_conf

  # Buat user dari allowed file dan direktori untuk tiap user tersebut.
  grep -v '^\s*$' /etc/safetp/allowed | while IFS= read -r username; do
    sudo useradd -G sudo -s /bin/bash -m -p '' "$username"
    # Buat direktori sesuai dengan inputan parameter -dir.
    if [ -n "$DIRECTORY" ]; then
      # Buat direktori sesuai yang diinputkan pada parameter pada direktori /home/$username.
      sudo mkdir -pm700 "/home/$username/$DIRECTORY"
      # Ubah kepemilikan direktori tersebut menjadi user yang bersangkutan.
      sudo chown -R "$username:$username" "/home/$username/$DIRECTORY"
      # Konfigurasi direktori 'user_conf' untuk tiap user.
      echo "local_root=/home/$username/$DIRECTORY" | sudo tee -a /etc/safetp/user_conf/$username > /dev/null
      # Set permission agar file tidak bisa dimodifikasi oleh user lain.
      sudo chmod 644 "/etc/safetp/user_conf/$username"
    # Jika parameter -dir tidak diberikan, maka direktori default adalah '$HOME/ftp'.
    else
      # Buat direktori default 'ftp' di /home/$username.
      sudo mkdir -pm700 "/home/$username/ftp"
      # Ubah kepemilikan direktori tersebut menjadi user yang bersangkutan.
      sudo chown -R "$username:$username" "/home/$username/ftp"
      # Konfigurasi direktori 'user_conf' untuk tiap user.
      echo "local_root=/home/$username/ftp" | sudo tee -a /etc/safetp/user_conf/$username > /dev/null
      # Set permission agar file tidak bisa dimodifikasi oleh user lain.
      sudo chmod 644 "/etc/safetp/user_conf/$username"
    fi
  done # Baca per-baris file 'allowed' setiap kali perulangan.

  # Jika parameter -p diberikan, maka ganti 'listen_port' default FTP server.
  [[ -n "$PORT" ]] && sudo sed -i "s/^listen_port=.*/listen_port=$PORT/" /etc/vsftpd.conf

  # Parameter -l diberikan, maka ganti 'userlist_file' dan 'chroot_list_file' pada konfigurasi FTP server.
  if [[ -n "$USERLIST" ]]; then
    sudo sed -i "s|^userlist_file=.*|userlist_file=/etc/safetp/allowed|" /etc/vsftpd.conf
    sudo sed -i "s|^chroot_list_file=.*|chroot_list_file=/etc/safetp/allowed|" /etc/vsftpd.conf
  fi
  sleep 1 # tunggu 1 detik.

  # 5. Membuat self-signed SSL certificate untuk keamanan FTP server.
  echo "[+] Konfigurasi SSL certificate untuk FTPS..."
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/safetp.key -out /etc/ssl/certs/safetp.crt -subj "/C=ID/ST=Indonesia/L=/O=/OU=/CN=/emailAddress=/" &> /dev/null # Generate self-signed SSL certificate untuk 1 tahun.
  sleep 0.5 # tunggu 0.5 detik.

  # 6. Restart layanan FTP server.
  echo "[+] Memulai ulang service FTP server..."
  sudo systemctl restart -q vsftpd.service
  sudo systemctl enable -q vsftpd.service
  sleep 1 # tunggu 1 detik.

  # 7. Menampilkan notif jika konfigurasi FTP server selesai.
  echo "[OK] Konfigurasi FTP server selesai" | lolcat
  echo "[OK] FTP server dapat diakses melalui port: ${PORT:-21}" | lolcat
  sleep 0.5 # tunggu 0.5 detik.
}

# Fungsi untuk mengkonfigurasi DNS server.
#configure_dns() {
#}

main() {
  # Cek apakah software vsftpd sudah terinstall atau belum
  is_vsftpd_installed=$(sudo dpkg -l | grep vsftpd &> /dev/null)
  # Jika belum terinstall, maka jalankan fungsi 'initial_setup' dan 'install_dependensi'.
  if [[ $? -ne 0 ]]; then
    initial_setup
    install_dependensi
  fi

  # Parse command line arguments
  if [ $# -eq 0 ]; then
    banner
    exit 1
  fi

  # Lakukan perulangan untuk membaca parameter yang diberikan.
  while [[ "$#" -gt 0 ]]; do
    # Cek parameter yang diberikan.
    case $1 in
      -l|--userlist) [[ -n "$USERLIST" ]] && { echo "Duplicate parameter: $1"; exit 1; }; USERLIST="$2"; shift ;;
      -dir|--directory) [[ -n "$DIRECTORY" ]] && { echo "Duplicate parameter: $1"; exit 1; }; DIRECTORY="$2"; shift ;;
      -p|--port) [[ -n "$PORT" ]] && { echo "Duplicate parameter: $1"; exit 1; }; PORT="$2"; shift ;;
      -ip|--ip-address) [[ -n "$IP_ADDRESS" ]] && { echo "Duplicate parameter: $1"; exit 1; }; IP_ADDRESS="$2"; shift ;;
      -d|--domain) [[ -n "$DOMAIN" ]] && { echo "Duplicate parameter: $1"; exit 1; }; DOMAIN="$2"; shift ;;
      -h|--help) banner; exit 0 ;;
      *) echo "Unknown parameter passed: $1"; banner; exit 1 ;;
    esac
    shift
  done

  # Cek apakah parameter -l sudah diberikan atau belum.
  if [[ -z "$USERLIST" ]]; then
    echo "[-] File userlist bersifat WAJIB!"
    banner
    exit 1
  fi

  # Menjalankan fungsi 'configure_ftp'.
  configure_ftp

  # Menjalankan fungsi 'configure_dns' jika parameter -ip dan -d diberikan.
  if [[ -n "$IP_ADDRESS" && -n "$DOMAIN" ]]; then
    configure_dns
  fi
}

# Jalankan fungsi main
main "$@"