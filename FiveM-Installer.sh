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

echo "[*] Installationsordner erstellen: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "[*] Neueste Buildnummer ermitteln..."
LATEST_BUILD=$(curl -s "$FX_ARTIFACTS_URL" | grep -oP '(?<=href=")[0-9]+-[a-f0-9]+(?=/")' | sort -n | tail -1)
DOWNLOAD_URL="${FX_ARTIFACTS_URL}${LATEST_BUILD}/fx.tar.xz"

echo "[*] Neueste Version herunterladen..."
wget -q -O "$FX_TAR" "$DOWNLOAD_URL"

echo "[*] Alte Dateien entfernen..."
rm -rf alpine citizen data nui-builds server fxe* run.sh || true

echo "[*] Entpacke neue Version..."
tar xf "$FX_TAR"
rm "$FX_TAR"

echo "[*] txAdmin starten..."
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
