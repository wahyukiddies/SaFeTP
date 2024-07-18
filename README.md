# SaFeTP (Safe FTP)

## Introduction

Merupakan sebuah proyek yang berfokus pada pemanfaatan shell script sebagai media untuk melakukan automasi FTP server, dalam hal ini kami menggunakan software **vsftpd**. Selain itu, kami juga memberikan opsi lain berupa konfigurasi DNS server untuk kemudahan akses, tetapi dengan syarat **alamat IP yang digunakan itu statis** (tidak berubah-ubah!). Fitur lain yang kami tambahkan yaitu adanya akses ke **aplikasi manajemen user FTP melalui web**, sehingga tidak perlu susah payah masuk ke server hanya untuk menambahkan user baru ke dalam allowed user file.

## Testing Environment

Kami telah mencobanya di **Ubuntu Server 22.04.4 (LTS version)** dan **hasilnya work**.

## Softwares

- FTP Server: **vsftpd**
- DNS Server: **bind9**
- Web: **Python Flask + Bootstrap**

## Usage

### Auto install

> Jika ingin menggunakan opsi auto install, maka daftar nama user FTP harus diinputkan secara manual ke dalam file "**userlist.txt**".

```bash
sudo apt install -y curl && \
curl -fsSL "https://raw.githubusercontent.com/wahyukiddies/SaFeTP/main/safetp.sh" | sudo tee -a $(pwd)/safetp.sh && \
sudo bash safetp.sh -l userlist.txt
```

### Manual install

```bash
# Clone the repository first.
git clone https://github.com/wahyukiddies/SaFeTP.git && chmod a+x safetp.sh

# And then, run the safetp.sh script with 1 required parameters!
# Change with your own userlist file!.
sudo bash safetp.sh -l userlist-sample.txt

# You can change the port by provide -p.
sudo bash safetp.sh -l userlist.txt -p 2121 # by default is 21.

# And also you can change the directory name for each allowed users:
sudo bash safetp.sh -l userlist.txt -p 2121 -dir ftpdir # by default is "$HOME/ftp".
```

Jika terdapat error ketika mencoba menjalankan di environment Linux, cobalah untuk mengubahnya ke format UNIX/Linux menggunakan tool `dos2unix`:

```sh
sudo apt install -y dos2unix
```

## References

- Konfigurasi DNS Server:
  1. [Jurnal 1 - JNCA](https://jurnal.netplg.com/index.php/jnca/article/view/61/37)
  2. [Jurnal 2 - STMIK Dian Cipta Cendikia Kotabumi](https://www.dcckotabumi.ac.id/ojs/index.php/jik/article/view/236/169)

- Konfigurasi FTP Server:
  1. [Jurnal 1 - STMIK IBBI](https://ijcoreit.org/index.php/coreit/article/view/300)
  2. [Jurnal 2 - Poltek Tegal](https://perpustakaan.poltektegal.ac.id/index.php/index.php?p=fstream-pdf&fid=18923&bid=12369)

- Konfigurasi SSL pada FTP Server:
  1. [Jurnal 1 - UNESA](https://ejournal.unesa.ac.id/index.php/jinacs/article/view/60908/46839)
  2. [Jurnal 2 - UNHAS](https://journal.unhas.ac.id/index.php/juteks/article/view/5150/3325)
  3. [Jurnal 3 - GoretanPena](https://jurnal.goretanpena.com/index.php/JSSR/article/view/471/411)

## Articles

- [https://adindammb22.mb.student.pens.ac.id/UAS%20Praktikum%20Jaringan%20Komputer/FTP_Dinda.pdf](https://adindammb22.mb.student.pens.ac.id/UAS%20Praktikum%20Jaringan%20Komputer/FTP_Dinda.pdf)
