#!/bin/bash
set -euo pipefail

INSTALL_DIR="$HOME/FXServer/server"
LOG_FILE="$HOME/fivem_log.txt"
FX_TAR="fx.tar.xz"
PACKAGES="wget curl xz-utils screen"

echo "Bitte gib die Download-URL der neuesten FiveM Linux Build an."
echo "Du findest sie hier: https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
echo "Beispiel einer URL: https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/#####-commitHash/fx.tar.xz"
read -rp "Download-URL: " DOWNLOAD_URL

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "Keine URL eingegeben. Beende."
  exit 1
fi

echo "[*] Pakete installieren (non-interactive)..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq $PACKAGES

echo "[*] Installationsordner erstellen: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "[*] Lade Build herunter von: $DOWNLOAD_URL"
wget -q -O "$FX_TAR" "$DOWNLOAD_URL"

echo "[*] Alte Dateien entfernen..."
rm -rf alpine citizen data nui-builds server fxe* run.sh || true

echo "[*] Entpacke neue Version..."
tar xf "$FX_TAR"
rm "$FX_TAR"

echo "[*] Starte txAdmin in Screen..."
chmod +x ./run.sh
screen -dmS fivem_auto ./run.sh +set serverProfile default +set txAdminPort 40120

CRON_CMD="@reboot bash <(curl -s https://raw.githubusercontent.com/gitoge3/FiveM-Installer/main/FiveM-Installer.sh) >> $LOG_FILE 2>&1"

if ! crontab -l 2>/dev/null | grep -Fq "$CRON_CMD"; then
  echo "[*] Autostart in Crontab eintragen..."
  (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
fi

echo ""
echo "[✓] Fertig! txAdmin läuft unter http://<deine-ip>:40120"
echo "[i] Logs in $LOG_FILE"
