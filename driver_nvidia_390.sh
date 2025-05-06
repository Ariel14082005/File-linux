#!/bin/bash

# 2. Memastikan bahwa direktori Downloads ada
if [ ! -d "$HOME/Downloads" ]; then
    echo "Direktori Downloads tidak ditemukan. Membuat direktori Downloads..."
    mkdir -p "$HOME/Downloads"
fi

# 3. Masuk ke direktori Downloads
cd "$HOME/Downloads" || { echo "Gagal masuk ke direktori Downloads"; exit 1; }

# 4. Mengunduh driver legacy NVIDIA 390.157 dari situs resmi NVIDIA
echo "Mengunduh driver NVIDIA 390.157..."
wget -c https://us.download.nvidia.com/XFree86/Linux-x86_64/390.157/NVIDIA-Linux-x86_64-390.157.run

# 5. Memeriksa apakah file berhasil diunduh
if [ ! -f "NVIDIA-Linux-x86_64-390.157.run" ]; then
    echo "Gagal mengunduh file driver NVIDIA. Pastikan koneksi internet Anda aktif dan coba lagi."
    exit 1
fi

# 6. Memberikan izin eksekusi pada file
echo "Memberikan izin eksekusi pada file driver..."
chmod +x NVIDIA-Linux-x86_64-390.157.run

# 7. Mengecek apakah driver sudah dapat dieksekusi
if [ ! -x "NVIDIA-Linux-x86_64-390.157.run" ]; then
    echo "File driver tidak dapat dieksekusi. Periksa izin atau unduh ulang."
    exit 1
fi

# 8. Beralih ke mode teks (non-GUI)
echo "Beralih ke mode teks (non-GUI)..."
sudo systemctl isolate multi-user.target

# 9. Menjalankan installer driver NVIDIA
echo "Menjalankan installer NVIDIA..."
sudo ./NVIDIA-Linux-x86_64-390.157.run --no-opengl-files

# 10. Memeriksa apakah instalasi berhasil
if [ $? -ne 0 ]; then
    echo "Instalasi driver gagal. Periksa log untuk detail kesalahan."
    exit 1
fi

# 11. Reboot sistem
echo "Instalasi selesai. Me-reboot sistem..."
sudo reboot