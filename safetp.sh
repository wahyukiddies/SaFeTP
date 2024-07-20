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

# Variabel untuk mendapatkan IP address saat ini.
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Fungsi setup untuk cek internet, update, dan upgrade repositori
initial_setup() {
  show_banner
  echo "----------------------------------------------------"
  echo "[+] Mengecek koneksi internet..."
  # Perintah untuk mengecek koneksi internet.
  ping -c 3 google.com &> /dev/null
  if [ $? -eq 0 ]; then
    echo "[+] Koneksi internet OK"
    echo "[+] Update repositori sistem..."
    sudo apt update &> /dev/null
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

  # Install paket-paket yang dibutuhkan.
  sudo apt install -y lolcat vsftpd openssl net-tools nginx python3 python3-pip python3-venv &> /dev/null

  # Install library python untuk running Flask app.
  pip3 install flask flask-restx &> /dev/null

  # Cek jika parameter -d diberikan, maka install bind9 juga.
  if [ -n "$DOMAIN" ]; then
    sudo apt install -y bind9 bind9utils bind9-doc dnsutils &> /dev/null
  fi

  # Buat simbolik link tool lolcat ke /usr/bin/lolcat (bisa juga dengan copy).
  sudo ln -sf /usr/games/lolcat /usr/bin/lolcat
  echo "[+] Dependensi berhasil diinstal"
}

# Fungsi 'show_banner' untuk menampilkan informasi opsi-opsi yang tersedia pada program
show_banner() {
  desain_banner="
           ______ _______ _____  
          |  ____|__   __|  __ \ 
 ___  __ _| |__ ___ | |  | |__) |
/ __|/ _\` |  __/ _ \| |  |  ___/ 
\__ \ (_| | | |  __/| |  | |     
|___/\__,_|_|  \___||_|  |_|     
v1.0 | Kelompok 4 - TMJ 4B
"

  # Cek apakah lolcat terinstall.
  dpkg -l | grep lolcat &> /dev/null
  # Jika lolcat terinstall, maka tampilkan banner dengan warna random.
  [[ $? -ne 0 ]] && (echo "$desain_banner") || (echo "$desain_banner" | lolcat)
}

show_help() {
  echo "----------------------------------------------------"
  echo -e "Usage: sudo bash safetp.sh -l \$args [OPTIONS...]\n
  Options:\n
    -l, --userlist: File daftar user yang dapat mengakses server FTP (WAJIB!),\n
    -dir, --directory: Root direktori untuk tiap user (default: /home/\$user/ftp),\n
    -p, --port: Port untuk server FTP (default: 21),\n
    -d, --domain: Nama domain untuk DNS server,\n
    -h, --help: Menampilkan opsi yang tersedia."
  echo "----------------------------------------------------"
}

configure_secure_ftp() {
  # 1. Cek service vsftpd apakah sudah berjalan atau belum.
  echo "[+] Memulai konfigurasi FTP server..."

  # Perintah untuk mengecek apakah service FTP server sudah berjalan atau belum.
  netstat -tanp | grep :21 &> /dev/null

  # Cek port 21 (FTP) apakah sudah terbuka atau belum. 
  if [ $? -eq 0 ]; then
    echo "[+] Service FTP server sudah berjalan"
  else
    echo "[-] Service FTP server belum berjalan"
    sudo systemctl start -q vsftpd.service
    sleep 1 # tunggu 1 detik.
    echo "[+] Service FTP server berhasil dijalankan"
  fi

  # 2. Matikan service FTP server terlebih dahulu.
  echo "[+] Menonaktifkan service FTP server sementara..."
  sudo systemctl stop -q vsftpd.service
  sleep 0.5 # tunggu 0.5 detik.

  # 3. Backup file konfigurasi vsftpd.
  echo "[+] Melakukan backup file konfigurasi FTP server..."
  sudo mv -f /etc/vsftpd.conf /etc/vsftpd.conf.default
  sleep 0.5 # tunggu 0.5 detik.

  # 4. Mengkonfigurasi FTP server.
  echo "[+] Membuat file konfigurasi default FTP server..."
  # Membuat konfigurasi FTP server.
  sudo cat <<EOL | sudo tee /etc/vsftpd.conf > /dev/null
###########################################
# CREATED AUTOMATICALLY BY SAFETP PROGRAM #
###########################################

# Konfigurasi dasar FTP server.
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
use_localtime=YES
utf8_filesystem=YES

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

  # Ganti permission allowed file agar bisa diedit oleh python nantinya.
  sudo chmod 777 /etc/safetp/allowed

  # Buat direktori untuk user_conf.
  sudo mkdir -pm755 /etc/safetp/user_conf

  # Buat user dari allowed file dan direktori untuk tiap user tersebut.
  grep -v '^\s*$' /etc/safetp/allowed | sort | uniq | while IFS= read -r username; do
    # Perintah untuk apakah user sudah ada atau belum.
    id "$username" &> /dev/null

    # Cek apakah user tidak ditemukan, jika iya, maka buat user tersebut.
    if [ $? -ne 0 ]; then
      sudo useradd -G sudo -s /bin/bash -m -p '' "$username"
      echo "[+] User $username berhasil ditambahkan."
    else
      echo "[-] User $username sudah ada."
    fi

    # Buat direktori sesuai dengan inputan parameter -dir.
    if [ -n "$DIRECTORY" ]; then
      # Buat direktori sesuai yang diinputkan pada parameter pada direktori /home/$username.
      sudo mkdir -pm700 "/home/$username/$DIRECTORY"
      # Ubah kepemilikan direktori tersebut menjadi user yang bersangkutan.
      sudo chown -R "$username:$username" "/home/$username/$DIRECTORY"
      # Konfigurasi direktori 'user_conf' untuk tiap user.
      echo "local_root=/home/$username/$DIRECTORY" | sudo tee /etc/safetp/user_conf/$username > /dev/null
      # Set permission agar file tidak bisa dimodifikasi oleh user lain.
      sudo chmod 644 "/etc/safetp/user_conf/$username"
    # Jika parameter -dir tidak diberikan, maka direktori default adalah '$HOME/ftp'.
    else
      # Buat direktori default 'ftp' di /home/$username.
      sudo mkdir -pm700 "/home/$username/ftp"
      # Ubah kepemilikan direktori tersebut menjadi user yang bersangkutan.
      sudo chown -R "$username:$username" "/home/$username/ftp"
      # Konfigurasi direktori 'user_conf' untuk tiap user.
      echo "local_root=/home/$username/ftp" | sudo tee /etc/safetp/user_conf/$username > /dev/null
      # Set permission agar file tidak bisa dimodifikasi oleh user lain.
      sudo chmod 644 "/etc/safetp/user_conf/$username"
    fi
  done # Baca per-baris file 'allowed' setiap kali perulangan.

  # Jika parameter -p diberikan, maka ganti 'listen_port' default FTP server.
  [[ -n "$PORT" ]] && sudo sed -i "s/^listen_port=.*/listen_port=$PORT/" /etc/vsftpd.conf

  # Parameter -l diberikan, maka ganti 'userlist_file' dan 'chroot_list_file' pada konfigurasi FTP server.
  if [ -n "$USERLIST" ]; then
    sudo sed -i "s|^userlist_file=.*|userlist_file=/etc/safetp/allowed|" /etc/vsftpd.conf
    sudo sed -i "s|^chroot_list_file=.*|chroot_list_file=/etc/safetp/allowed|" /etc/vsftpd.conf
  fi
  sleep 1 # tunggu 1 detik.

  # 5. Membuat self-signed SSL certificate untuk keamanan FTP server.
  echo "[+] Konfigurasi SSL certificate untuk FTPS..."
  # Jika parameter -d dipassing, maka gunakan "ftp.$DOMAIN".
  if [ -n "$DOMAIN" ]; then
    CN="ftp.$DOMAIN"
  # Jika tidak, maka gunakan alamat IP saat ini.
  else
    CN="$IP_ADDRESS"
  fi

  # Generate self-signed SSL certificate untuk 1 tahun.
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout /etc/ssl/private/safetp.key \
    -out /etc/ssl/certs/safetp.crt \
    -subj "/C=ID/ST=Indonesia/L=/O=/OU=/CN=$CN/emailAddress=/" &> /dev/null 
  sleep 0.5 # tunggu 0.5 detik.
  echo "[+] SSL certificates berhasil dibuat"

  # 6. Restart layanan FTP server.
  echo "[+] Memulai ulang service FTP server..."
  sudo systemctl restart -q vsftpd.service
  # Cek apakah service FTP server sudah berjalan atau belum.
  if [ $? -ne 0 ]; then
    echo "[-] Gagal memulai ulang service FTP server!"
    cleanup_ftp
    exit 1
  fi
  sudo systemctl enable -q vsftpd.service
  sleep 1 # tunggu 1 detik.

  # 7. Menampilkan notif jika konfigurasi FTP server selesai.
  echo -e "[+] Konfigurasi FTP server selesai"
  sleep 0.5 # tunggu 0.5 detik.
  echo "----------------------------------------------------"
}

# Fungsi untuk mengkonfigurasi DNS server.
configure_dns() {
  # Cek apakah parameter -d diberikan atau tidak.
  if [ -n "$DOMAIN" ]; then
    echo "[+] Memulai konfigurasi DNS server..."

    # Mendapatkan oktet terakhir (IP Host) dari alamat IP saat ini.
    local last_ip=$(echo "$IP_ADDRESS" | awk -F. '{print $4}')

    # Membalikkan alamat IP (reverse).
    local reverse_ip_address=$(echo "$IP_ADDRESS" | awk -F. '{print $3"."$2"."$1".in-addr.arpa"}')

    # Konfigurasi file forward '/etc/bind/db.forward'.
    echo "[+] Melakukan konfigurasi pada file 'db.forward'..."
  sudo cat <<EOL | sudo tee /etc/bind/db.forward > /dev/null
;###########################################
;# CREATED AUTOMATICALLY BY SAFETP PROGRAM #
;###########################################
;
; BIND data file for local loopback interface
;
\$TTL    604800
@       IN      SOA     $DOMAIN. root.$DOMAIN. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      nsx1.$DOMAIN.
@       IN      NS      nsx2.$DOMAIN.
@       IN      A       $IP_ADDRESS
@       IN      AAAA    ::1
nsx1    IN      A       $IP_ADDRESS
nsx2    IN      A       $IP_ADDRESS
ftp     IN      A       $IP_ADDRESS
www     IN      A       $IP_ADDRESS
EOL
    sleep 1 # Tunggu 1 detik.

    # Konfigurasi file reverse '/etc/bind/db.reverse'.
    echo "[+] Melakukan konfigurasi pada file 'db.reverse'..."
    sudo cat <<EOL | sudo tee /etc/bind/db.reverse > /dev/null
;###########################################
;# CREATED AUTOMATICALLY BY SAFETP PROGRAM #
;###########################################
;
; BIND reverse data file for local loopback interface
;
\$TTL    604800
@       IN      SOA     $DOMAIN. root.$DOMAIN. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      nsx1.$DOMAIN.
@       IN      NS      nsx2.$DOMAIN.
$last_ip      IN      PTR     $DOMAIN.
$last_ip      IN      PTR     ftp.$DOMAIN.
$last_ip      IN      PTR     www.$DOMAIN.
EOL
    sleep 1 # Tunggu 1 detik.

    echo "[+] Backup file 'named.conf.options'..."
    sudo mv -f /etc/bind/named.conf.options /etc/bind/named.conf.options.default

    # Konfigurasi file bind9 options '/etc/bind/named.conf.options'.
    echo "[+] Melakukan konfigurasi pada file 'named.conf.options'..."
    sudo cat <<EOL | sudo tee /etc/bind/named.conf.options > /dev/null
//###########################################
//# CREATED AUTOMATICALLY BY SAFETP PROGRAM #
//###########################################
options {
  directory "/var/cache/bind";

  // If there is a firewall between you and nameservers you want
  // to talk to, you may need to fix the firewall to allow multiple
  // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

  // If your ISP provided one or more IP addresses for stable
  // nameservers, you probably want to use them as forwarders.
  // Uncomment the following block, and insert the addresses replacing
  // the all-0's placeholder.

  forwarders {
    $IP_ADDRESS;
  };

  //========================================================================
  // If BIND logs error messages about the root key being expired,
  // you will need to update your keys.  See https://www.isc.org/bind-keys
  //========================================================================
  dnssec-validation auto;

  listen-on-v6 { any; };
};
EOL
    sleep 1 # Tunggu 1 detik.

    # Konfigurasi file bind9 local '/etc/bind/named.conf.local'.
    echo "[+] Melakukan backup file 'named.conf.local'..."
    sudo mv -f /etc/bind/named.conf.local /etc/bind/named.conf.local.default

    echo "[+] Melakukan konfigurasi pada file 'named.conf.local'..."
    sudo cat <<EOL | sudo tee /etc/bind/named.conf.local > /dev/null
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "$DOMAIN" {
  type master;
  file "/etc/bind/db.forward";
};

zone "$reverse_ip_address" {
  type master;
  file "/etc/bind/db.reverse";
};
EOL
    sleep 1 # Tunggu 1 detik.

    # Cek konfigurasi file 'db.forward'.
    echo "[+] Cek konfigurasi file 'db.forward'..."
    # Perintah untuk mengecek apakah konfigurasi forward zone sudah benar atau belum.
    sudo named-checkzone "$DOMAIN" /etc/bind/db.forward &> /dev/null

    # Jika ada error, maka tampilkan pesan error lalu exit.
    if [ $? -ne 0 ]; then
      echo "[-] Ada error pada konfigurasi file 'db.forward'!"
      exit 1
    else
      echo "[+] Konfigurasi file 'db.forward' OK"
      sleep 0.5 # Tunggu 0.5 detik.
    fi

    # Cek konfigurasi file 'db.reverse'.
    echo "[+] Cek konfigurasi file 'db.reverse'..."

    # Perintah untuk mengecek apakah konfigurasi reverse zone sudah benar atau belum.
    sudo named-checkzone "$IP_ADDRESS" /etc/bind/db.reverse &> /dev/null
    # Jika ada error, maka tampilkan pesan error lalu exit.
    if [ $? -ne 0 ]; then
      echo "[-] Ada error pada konfigurasi DNS server!"
      exit 1
    else
      echo "[+] Konfigurasi file 'db.forward' OK"
      echo "[+] Konfigurasi DNS server selesai"
      sleep 0.5 # Tunggu 0.5 detik.
    fi

    # Menyalakan ulang service bind9.
    echo "[+] Menyalakan ulang service bind9..."
    sudo systemctl restart -q bind9.service
    sleep 1 # Tunggu 1 detik.

    # Cek service bind9 apakah sudah berhasil running atau belum.
    echo "[+] Check service bind9 running..."
    # Jika sudah, maka tambahkan alamat IP saat ini ke file resolv.conf pada baris pertama.
    if [ $? -ne 0 ]; then
      echo "[-] Gagal memulai ulang service DNS server!"
      cleanup_dns
      exit 1
    fi

    echo "[+] Service bind9 berhasil running..."
    # Menambahkan alamat IP saat ini ke file resolv.conf pada baris pertama.
    echo "[+] Menambahkan alamat IP saat ini ke file '/etc/resolv.conf'..." 
    echo "DNS=$IP_ADDRESS" | sudo tee -a /etc/systemd/resolved.conf > /dev/null
    sudo systemctl restart -q systemd-resolved
    sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    sleep 0.5 # Tunggu 0.5 detik.
    echo "[+] Konfigurasi DNS server selesai"
    echo "----------------------------------------------------"
  fi
}

deploy_web() {
  echo "[+] Memulai deploy SaFeTP Flask App..."

  # 1. Pindahkan folder current web app ke /var/www/
  echo "[+] Memindahkan folder web app ke direktori '/var/www/'"
  local ip_address=$(hostname -I | awk '{print $1}')
  local WEB_APP_PATH="$(pwd)/web"
  sudo cp -rf $WEB_APP_PATH /var/www/

  # 2. Ganti kepemilikan folder web app
  echo "[+] Mengganti kepemilikan folder web app"
  sudo chown -R www-data:www-data /var/www/web

  # 3. Ganti permission folder web app
  echo "[+] Mengganti permission folder web app"
  sudo chmod -R 755 /var/www/web

  # 4. Jalankan flask app di background.
  echo "[+] Menjalankan SaFeTP Flask App di background"
  nohup python3 /var/www/web/app.py > /var/log/safetp_web.log 2>&1 &
  sleep 1 # tunggu 1 detik.

  # Jika parameter -d diberikan, maka deploy web app sesuai dengan domain yang diberikan.
  echo "[+] Membuat SSL certificate untuk web"

  # Jika parameter -d dipassing, maka gunakan "www.$DOMAIN".
  if [ -n "$DOMAIN" ]; then
    CN="www.$DOMAIN"
  # Jika tidak, maka gunakan alamat IP saat ini.
  else
    CN="$IP_ADDRESS"
  fi

  sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout /etc/ssl/private/safetp_web.key \
    -out /etc/ssl/certs/safetp_web.crt \
    -subj "/C=ID/ST=Indonesia/L=/O=/OU=/CN=$CN/emailAddress=/" &> /dev/null
  sleep 0.5 # tunggu 0.5 detik.

  # Buat file konfigurasi Nginx untuk web app.
  echo "[+] Membuat file konfigurasi Nginx"

  # Cek aaakah parameter -d diberikan atau tidak.
  if [ -n "$DOMAIN" ]; then
    # Buat konfigurasi Nginx untuk domain yang diberikan.
    sudo cat <<EOL | sudo tee /etc/nginx/sites-available/safetp_web.conf > /dev/null
server {
  listen 80;
  server_name $DOMAIN www.$DOMAIN;
  return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl;
  server_name www.$DOMAIN;

  ssl_certificate /etc/ssl/certs/safetp_web.crt;
  ssl_certificate_key /etc/ssl/private/safetp_web.key;

  location / {
    include proxy_params;
    proxy_pass http://$DOMAIN:8080/;
  }
}
EOL
  else
    sudo cat <<EOL | sudo tee /etc/nginx/sites-available/safetp_web.conf > /dev/null
server {
  listen 80 default_server;
  server_name $IP_ADDRESS;
  return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl default_server;
  server_name $IP_ADDRESS;

  ssl_certificate /etc/ssl/certs/safetp_web.crt;
  ssl_certificate_key /etc/ssl/private/safetp_web.key;

  location / {
    include proxy_params;
    proxy_pass http://$IP_ADDRESS:8080/;
  }
}
EOL
    sleep 0.5 # tunggu 0.5 detik.
  fi

  # 7. Buat simbolik link ke sites-enabled dan hapus default config.
  echo "[+] Membuat symlink ke folder 'sites-enabled'"
  sudo ln -sf /etc/nginx/sites-available/safetp_web.conf /etc/nginx/sites-enabled/safetp_web.conf

  # 8. Menghapus default konfigurasi Nginx.
  echo "[+] Menghapus default konfigurasi Nginx"
  sudo rm -f /etc/nginx/sites-enabled/default
  sleep 1 # tunggu 1 detik.

  # Cek konfigurasi nginx dan reload service Nginx.
  echo "[+] Mengecek konfigurasi Nginx"
  # Perintah untuk mengecek konfigurasi Nginx dan reload service Nginx.
  sudo nginx -t &> /dev/null && sudo systemctl reload -q nginx.service

  # Jika konfigurasi Nginx berhasil, maka deploy web app.
  if [ $? -eq 0 ]; then
    # Menyalakan ulang service Nginx.
    echo "[+] Menyalakan ulang service Nginx"
    sudo systemctl restart -q nginx.service
    sleep 1 # tunggu 1 detik.

    echo "[+] Proses deploy SaFeTP Flask App berhasil!"
    sleep 0.5 # tunggu 0.5 detik.
  else
    echo "[-] Gagal deploy SaFeTP Flask App!"
    cleanup_web
    exit 1
  fi
  echo "----------------------------------------------------"
}

# Fungsi untuk menghapus direktori dan file konfigurasi FTP server
cleanup_ftp() {
  # Clean up semua folder dan file terkait.
  echo "[+] Clean up konfigurasi FTP server..."
  sudo rm -rf /etc/safetp /etc/vsftpd.conf /etc/vsftpd.conf.default /etc/ssl/certs/safetp.crt /etc/ssl/private/safetp.key

  # Hapus semua user FTP.
  echo "[+] Menghapus semua user FTP..."
  grep -v '^\s*$' /etc/safetp/allowed | sort | uniq | while IFS= read -r username; do
    sudo groupdel -f $username 2>/dev/null
    sudo userdel -r "$username" 2>/dev/null
  done

  # Mengonfigurasi ulang FTP server.
  configure_secure_ftp
}

# Fungsi untuk menghapus direktori dan file konfigurasi DNS server
cleanup_dns() {
  # Clean up semua folder dan file terkait.
  echo "[+] Clean up konfigurasi DNS server..."
  sudo rm -rf /etc/bind /var/cache/bind

  # Mengonfigurasi ulang DNS server.
  configure_dns
}

cleanup_web() {
  # Clean up semua folder dan file terkait.
  echo "[+] Clean up konfigurasi web server..."
  sudo rm -rf /var/www/web /etc/nginx/sites-available/safetp_web.conf /etc/nginx/sites-enabled/safetp_web.conf /etc/ssl/certs/safetp_web.crt /etc/ssl/private/safetp_web.key

  # Mengonfigurasi ulang web server.
  deploy_web
}

main() {
  # Cek apakah user menjalankan program ini sebagai root atau tidak.
  if [ "$EUID" -ne 0 ]; then
    show_banner
    show_help
    echo -e "\e[31m[-] Tolong jalankan program ini sebagai root!\e[1m"
    exit 1
  fi

  # Menampilkan banner jika user tidak memasukkan parameter apapun.
  if [ $# -eq 0 ]; then
    show_banner
    show_help
    exit 0
  fi

  # Lakukan perulangan untuk membaca parameter yang diberikan.
  while [ "$#" -gt 0 ]; do
    case $1 in
      -l|--userlist)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        USERLIST="$2"
        shift
      else
        show_banner
        show_help
        echo -e "\e[31m[-] Opsi $1 memerlukan argumen yang valid\e[0m"
        exit 1
      fi
      ;;
      -dir|--directory)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          DIRECTORY="$2"
          shift
        else
          show_banner
          show_help
          echo -e "\e[31m[-] Opsi $1 memerlukan argumen yang valid\e[0m"
          exit 1
        fi
        ;;
      -p|--port)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          PORT="$2"
          shift
        else
          show_banner
          show_help
          echo -e "\e[31m[-] Opsi $1 memerlukan argumen yang valid\e[0m"
          exit 1
        fi
        ;;
      -d|--domain)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          DOMAIN="$2"
          shift
        else
          show_banner
          show_help
          echo -e "\e[31m[-] Opsi $1 memerlukan argumen yang valid\e[0m"
          exit 1
        fi
        ;;
      -h|--help)
        show_banner
        show_help
        exit 0
        ;;
      *)
        show_banner
        show_help
        echo -e "\e[31m[-] Opsi $1 TIDAK VALID!\e[1m"
        exit 1
        ;;
    esac
    shift
  done

  # Pastikan parameter USERLIST diberikan.
  if [ -z "$USERLIST" ]; then
    show_banner
    show_help
    echo -e "\e[31m[-] Parameter -l / --userlist wajib diberikan!\e[1m"
    exit 1
  fi

  # Cek apakah parameter -l / --userlist filenya ada atau tidak.
  if [ ! -f "$USERLIST" ]; then
    show_banner
    show_help
    echo -e "\e[31m[-] File userlist tidak ditemukan!\e[1m"
    exit 1
  fi

  # Initial setup terlebih dahulu untuk cek internet dan update repo.
  initial_setup

  # Install dependensi yang dibutuhkan.
  install_dependensi

  # Panggil fungsi 'configure_secure_ftp'.
  configure_secure_ftp

  # Panggil fungsi 'configure_dns'.
  configure_dns

  # Panggil fungsi 'deploy_web'.
  deploy_web

  if [ -n "$DOMAIN" ]; then
    echo -e "\e[34m[+] Silahkan tambahkan alamat IP: $IP_ADDRESS ke file '/etc/resolv.conf' ke Linux client, atau jalankan script 'dns_config.sh' di Linux client!\e[1m"

    echo -e "\e[32m[+] Silahkan akses FTP server menggunakan domain: ftp.${DOMAIN} di port: ${PORT:-21}\e[1m"
    echo -e "\e[32m[+] Silahkan akses SaFeTP web menggunakan domain: www.${DOMAIN}\e[1m"
  else
    echo -e "\e[32m[+] Silahkan akses FTP server menggunakan alamat IP: $IP_ADDRESS di port: ${PORT:-21}\e[1m"
    echo -e "\e[32m[+] Silahkan akses SaFeTP web menggunakan alamat IP: $IP_ADDRESS\e[1m"
  fi
  echo -e "\e[32m[OK] Instalasi dan konfigurasi SaFeTP selesai!\e[1m"
}

# Jalankan fungsi main
main "$@"