#!/bin/bash

# FiveM Installer + Auto-Updater via GitHub (1-Datei-Version)
# https://github.com/Squex0978/linux-fiveminstaller

set -e

INSTALL_DIR="$HOME/FXServer/server"
FX_ARTIFACTS_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
FX_TAR="fx.tar.xz"
LOG_FILE="$HOME/fivem_log.txt"
SCRIPT_URL="https://raw.githubusercontent.com/Squex0978/linux-fiveminstaller/main/fiveminstaller.sh"

echo "[*] Abhängigkeiten installieren..."
sudo apt update
sudo apt install -y wget curl xz-utils screen

echo "[*] Installationsverzeichnis vorbereiten: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "[*] Neueste FiveM-Version wird ermittelt..."
LATEST_BUILD=$(curl -s "$FX_ARTIFACTS_URL" | grep -oP '(?<=href=")[0-9]+-[a-f0-9]+(?=/")' | sort -n | tail -1)
DOWNLOAD_URL="${FX_ARTIFACTS_URL}${LATEST_BUILD}/fx.tar.xz"

echo "[*] Lade Build $LATEST_BUILD herunter..."
wget -q -O "$FX_TAR" "$DOWNLOAD_URL"

echo "[*] Alte Dateien entfernen..."
rm -rf alpine citizen data nui-builds server fxe* run.sh || true

echo "[*] Entpacke neue Version..."
tar xf "$FX_TAR"
rm "$FX_TAR"

echo "[*] Starte txAdmin in screen..."
chmod +x ./run.sh
screen -dmS fivem_auto ./run.sh +set serverProfile default +set txAdminPort 40120

# === Crontab @reboot hinzufügen ===
CRON_CMD="@reboot bash <(curl -s $SCRIPT_URL) >> $LOG_FILE 2>&1"
crontab -l 2>/dev/null | grep -F "$SCRIPT_URL" >/dev/null || (
    echo "[*] Trage Autostart in crontab ein..."
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
)

echo ""
echo "[✓] Installation abgeschlossen!"
echo "[✓] txAdmin läuft auf http://<deine-ip>:40120"
echo "[✓] Bei jedem Neustart wird die neueste Version automatisch installiert."
echo "[📄] Log-Datei: $LOG_FILE"
