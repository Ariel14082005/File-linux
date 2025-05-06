#!/bin/bash

# Update sistem dan instal dependensi dasar
echo "Mengupdate daftar paket..."
sudo apt update -y
sudo apt upgrade -y

# Instal Python3 dan pip
echo "Menginstal Python3 dan pip..."
sudo apt install python3 python3-pip -y

# Instal modul Python untuk Telegram Bot
echo "Menginstal python-telegram-bot..."
pip3 install --upgrade pip
pip3 install python-telegram-bot==13.15

# Instal lm-sensors untuk membaca suhu
echo "Menginstal lm-sensors..."
sudo apt install lm-sensors -y
sudo sensors-detect --auto

# Membuat file Python untuk bot
echo "Membuat bot_suhu.py..."
cat <<EOL > /home/$USER/bot_suhu.py
#!/usr/bin/env python3
from telegram import Update
from telegram.ext import Updater, CommandHandler, CallbackContext
import subprocess
import threading
import time
import re

API_TOKEN = "7630725240:AAHsPYgs9cvVy9NWN6CeCjxweaiWrwnmT_k"
CHAT_ID = 8192169924
BATAS_CELSIUS = 60.0  # Batas suhu untuk kirim otomatis

def get_temperature():
    try:
        result = subprocess.check_output(["sensors"]).decode("utf-8")
        return result
    except Exception as e:
        return f"Error: {e}"

def get_max_temp(text):
    temps = re.findall(r'\+([\d.]+)°C', text)
    temps = [float(t) for t in temps]
    return max(temps) if temps else 0

def start(update: Update, context: CallbackContext):
    update.message.reply_text("Halo! Kirim /temp untuk melihat suhu sekarang.")

def suhu(update: Update, context: CallbackContext):
    temp = get_temperature()
    update.message.reply_text(f"Suhu:\n{temp}")

def auto_send_temp(bot):
    while True:
        data = get_temperature()
        max_temp = get_max_temp(data)
        if max_temp >= BATAS_CELSIUS:
            try:
                bot.send_message(chat_id=CHAT_ID, text=f"[PERINGATAN] Suhu tinggi ({max_temp}°C):\n{data}")
            except Exception as e:
                print(f"Error: {e}")
        time.sleep(300)

updater = Updater(API_TOKEN)
dispatcher = updater.dispatcher

dispatcher.add_handler(CommandHandler("start", start))
dispatcher.add_handler(CommandHandler("temp", suhu))

# Jalankan thread pengirim suhu berkala jika melewati ambang batas
threading.Thread(target=auto_send_temp, args=(updater.bot,), daemon=True).start()

updater.start_polling()
updater.idle()
EOL

# Memberikan izin eksekusi pada file bot
echo "Memberikan izin eksekusi pada bot_suhu.py..."
chmod +x /home/$USER/bot_suhu.py

# Membuat service systemd untuk bot
echo "Membuat bot_suhu.service..."
SERVICE_FILE="/etc/systemd/system/bot_suhu.service"

cat <<EOL | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=Bot Suhu Telegram
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/$USER/bot_suhu.py
WorkingDirectory=/home/$USER
StandardOutput=inherit
StandardError=inherit
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOL

# Set permission dan enable service
echo "Mengatur permission dan mengaktifkan service..."
sudo chmod 644 $SERVICE_FILE
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable bot_suhu.service
sudo systemctl start bot_suhu.service

echo "Bot suhu berhasil dijalankan sebagai service!"