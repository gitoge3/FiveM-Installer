#!/bin/bash

set -e

INSTALL_DIR="$HOME/FXServer/server"
FX_ARTIFACTS_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
FX_TAR="fx.tar.xz"
LOG_FILE="$HOME/fivem_log.txt"

echo "[*] Pakete installieren (ohne Nachfrage)..."
sudo apt-get update -qq
sudo apt-get install -y -qq wget curl xz-utils screen dos2unix

echo "[*] Installationsordner anlegen: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "[*] Windows-Zeilenenden aus vorherigen Dateien entfernen (sicherheitscheck)..."
find . -type f -exec dos2unix {} + 2>/dev/null || true

echo "[*] Ermittle neueste FiveM-Build..."
LATEST_BUILD_URL=$(curl -s "$FX_ARTIFACTS_URL" | grep -oP '(?<=href=")[0-9]+-[a-f0-9]+(?=/")' | sort -n | tail -1)
DOWNLOAD_URL="${FX_ARTIFACTS_URL}${LATEST_BUILD_URL}/fx.tar.xz"

echo "[*] Lade Build $LATEST_BUILD_URL herunter..."
wget -q -O "$FX_TAR" "$DOWNLOAD_URL"

echo "[*] Alte Serverdateien entfernen..."
rm -rf alpine citizen data nui-builds server fxe* run.sh || true

echo "[*] Entpacke neue Version..."
tar xf "$FX_TAR"
rm "$FX_TAR"

echo "[*] txAdmin starten..."
chmod +x ./run.sh
screen -dmS fivem_auto ./run.sh +set serverProfile default +set txAdminPort 40120

# Crontab-Eintrag setzen (einmalig)
CRON_CMD="@reboot /bin/bash $INSTALL_DIR/$(basename "$0") >> $LOG_FILE 2>&1"
if ! crontab -l 2>/dev/null | grep -Fq "$CRON_CMD"; then
  echo "[*] Trage Autostart in crontab ein..."
  (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
fi

echo ""
echo "[✓] Installation & Setup abgeschlossen!"
echo "[✓] txAdmin läuft jetzt unter http://<deine-ip>:40120"
echo "[✓] Bei jedem Neustart wird automatisch die neuste Version geladen und gestartet."
echo "[i] Logs: $LOG_FILE"
