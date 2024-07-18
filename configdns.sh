#!/usr/bin/bash
#Script Untuk Konfigurasi DNS Server Automatis

#check root user
check_root(){
    if [ $(id -u) -ne 0 ]; then
        echo "[-] Harus dijalankan sebagai root!"
        echo "[-] Exit dari program!"
        exit 1
    fi
}

#check bind9 dnsutils
check_install(){
    if [ $(dpkg-query -W -f='${Status}' bind9 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        echo "[-] Bind9 belum terinstall!"
        echo "[+] Install bind9..."
        sudo apt install bind9 bind9utils bind9-doc -y &> /dev/null
        sleep 5
    fi

    if [ $(dpkg-query -W -f='${Status}' dnsutils 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        echo "[-] Dnsutils belum terinstall!"
        echo "[+] Install dnsutils..."
        sudo apt install dnsutils -y &> /dev/null
    fi

}



#Config Forwarder dan Reverse
config_for_rev(){
# Yang Akan di Konfig
# - db.forward
# - db.reverse
# - named.conf.options
# - named.conf.local 

    #check_ip saat ini 
    ip=$(hostname -I | awk '{print $1}')

    #mendapatkan digit terakhir dari ip saat ini
    digit=$(echo $ip | awk -F. '{print $4}')

    #Reverse IP saat ini
    reverse_ip=$(echo $ip | awk -F. '{print $4"."$3"."$2".in-addr.arpa"}')

    # config /etc/bind/db.forward
    echo "[+] Melakukan config db.forward..."
    sudo cat <<EOL | sudo tee /etc/bind/db.forward > /dev/null
;###########################################
;# CREATED AUTOMATICALLY BY SAFETP PROGRAM #
;###########################################
;
; BIND data file for local loopback interface
;
\$TTL    604800
@       IN      SOA     localhost. root.localhost. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      nsx1.$domain.
@       IN      NS      nsx2.$domain.
@       IN      A       $ip
@       IN      AAAA    ::1
nsx1    IN      A       $ip
nsx2    IN      A       $ip
EOL

    # config /etc/bind/db.reverse
    echo "[+] Melakukan config db.reverse..."
    sudo cat <<EOL | sudo tee /etc/bind/db.reverse > /dev/null
;###########################################
;# CREATED AUTOMATICALLY BY SAFETP PROGRAM #
;###########################################
;
; BIND reverse data file for local loopback interface
;
\$TTL    604800
@       IN      SOA     localhost. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      nsx1.$domain.
@       IN      NS      nsx2.$domain.
$digit  IN      PTR     $domain.
EOL

    echo "[+] Backup file named.conf.options..."
    sudo mv /etc/bind/named.conf.options /etc/bind/named.conf.options.bak

    # config /etc/bind/named.conf.options
    echo "[+] Melakukan config named.conf.options..."
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
                $ip;
        };

        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================
        dnssec-validation auto;

        listen-on-v6 { any; };
};
EOL
#---------------------------------------------------------------------------------
    # config /etc/bind/named.conf.local
    echo "[+] Melakukan backup file named.conf.local..."
    sudo mv /etc/bind/named.conf.local /etc/bind/named.conf.local.bak

    echo "[+] Melakukan config named.conf.local..."
    sudo cat <<EOL | sudo tee /etc/bind/named.conf.local > /dev/null
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "$domain" {
        type master;
        file "/etc/bind/db.forward";
};

zone "$reverse_ip" {
        type master;
        file "/etc/bind/db.reverse";
};
EOL

    #Restart bind9
    echo "[+] Restart bind9..."
    sudo systemctl restart bind9

    #check service bind9 berjalan
    echo "[+] Check service bind9 berjalan..."
    if [ $(systemctl is-active bind9) == "active" ]; then
        echo "[+] Bind9 service berhasil berjalan..."
        
        #Menambahkan IP saat ini ke file resolv.conf pada baris pertama 
        echo "[+] Menambahkan IP saat ini ke file resolv.conf..." 
        sudo sed -i "1s/^/nameserver $ip\n/" /etc/resolv.conf

        echo "[+] Konfigurasi DNS Server telah selesai..."
        echo ""
        echo "[+] Silahkan kunjungin >>> $domain <<<"

    else
        echo "[-] Bind9 service gagal berjalan..."
        echo "[-] Ulangin proses setelah menyelesaikan masalah..."
        echo "[-] Mulai script configdns.sh dengan parameter --reset"
    fi
}

# Apabila bind terinstall namun terjadi kesalahan konfigurasi
# Menghapus semua konfigurasi bind 
reset_bind9(){
    echo "[+] Resetting bind9 configuration..."
    sudo apt remove --purge bind9 bind9utils bind9-doc -y &> /dev/null
    sudo rm -rf /etc/bind
    sudo rm -rf /var/cache/bind
    echo "[+] Bind9 and its configurations have been reset."
}

main(){
    if [ "$1" == "--reset" ]; then
        reset_bind9
        exit 0
    fi
    check_root
    check_install
    echo "[+] Masukan nama domain: "
    echo -n "[>] "
    read domain 
    config_for_rev $domain
}

main "$@"