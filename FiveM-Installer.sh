#!/bin/bash
set -euo pipefail

INSTALL_DIR="$HOME/FXServer/server"
LOG_FILE="$HOME/fivem_log.txt"
FX_TAR="fx.tar.xz"
PACKAGES="wget curl xz-utils screen"

read -rp "Bitte gib die Download-URL der neuesten FiveM Linux Build ein: " DOWNLOAD_URL

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

echo "[*] txAdmin in Screen starten..."
chmod +x ./run.sh

# Screen-Session-Name
SCREEN_NAME="txadmin"

# txAdmin starten
screen -dmS "$SCREEN_NAME" ./run.sh +set serverProfile default +set txAdminPort 40120

echo "[*] Warte 10 Sekunden auf txAdmin-Start..."
sleep 10

echo "[*] Suche Master PIN in Screen-Output..."

# Screen-Log temporär speichern
TMP_LOG=$(mktemp)
screen -S "$SCREEN_NAME" -X hardcopy "$TMP_LOG"

# Master PIN ausgeben (Beispielmuster: Master password: 1234)
MASTER_PIN=$(grep -i 'Master password' "$TMP_LOG" | head -1 || true)

if [[ -n "$MASTER_PIN" ]]; then
  echo ""
  echo "=== txAdmin Master PIN ==="
  echo "$MASTER_PIN"
  echo "=========================="
else
  echo "Master PIN konnte nicht gefunden werden. Öffne die Screen-Session manuell mit:"
  echo "screen -r $SCREEN_NAME"
fi

rm "$TMP_LOG"

echo ""
echo "[✓] Fertig! txAdmin läuft unter http://<deine-ip>:40120"
echo "[i] Logs werden in $LOG_FILE gespeichert (wenn aktiviert)."
