#!/bin/bash
set -euo pipefail

INSTALL_DIR="$HOME/FXServer/server"
LOG_FILE="$HOME/fivem_log.txt"
FX_ARTIFACTS_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
FX_TAR="fx.tar.xz"
PACKAGES="wget curl xz-utils screen"

echo "[*] Pakete installieren (non-interactive)..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq $PACKAGES

echo "[*] Erstelle Installationsordner: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "[*] Ermittle neueste Buildnummer..."
LATEST_BUILD=$(curl -s "$FX_ARTIFACTS_URL" | grep -oP '(?<=href=")[0-9]+-[a-f0-9]+(?=/")' | sort -n | tail -1)
DOWNLOAD_URL="${FX_ARTIFACTS_URL}${LATEST_BUILD}/fx.tar.xz"

echo "[*] Lade neueste Version herunter..."
wget -q -O "$FX_TAR" "$DOWNLOAD_URL"

echo "[*] Entferne alte Dateien..."
rm -rf alpine citizen data nui-builds server fxe* run.sh || true

echo "[*] Entpacke Download..."
tar xf "$FX_TAR"
rm "$FX_TAR"

echo "[*] Starte txAdmin in Screen..."
chmod +x ./run.sh
screen -dmS fivem_auto ./run.sh +set serverProfile default +set txAdminPort 40120

CRON_CMD="@reboot bash <(curl -s https://raw.githubusercontent.com/gitoge3/FiveM-Installer/main/FiveM-Installer.sh) >> $LOG_FILE 2>&1"

if ! crontab -l 2>/dev/null | grep -Fq "$CRON_CMD"; then
  echo "[*] Trage Autostart in Crontab ein..."
  (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
fi

echo ""
echo "[✓] Fertig! txAdmin läuft unter http://<deine-ip>:40120"
echo "[i] Logs werden in $LOG_FILE geschrieben."
