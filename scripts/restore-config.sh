#!/bin/sh

# 📦 Cartella di backup da cui ripristinare
BACKUP_DIR="$HOME/backup-configs"
RESTORE_LOG="$HOME/restore-log.txt"

# 🔍 Verifica che la cartella di backup esista
if [ ! -d "$BACKUP_DIR" ]; then
  echo "❌ Cartella di backup non trovata: $BACKUP_DIR"
  exit 1
fi

# ⚠️ Conferma con l'utente prima di sovrascrivere
echo "⚠️ ATTENZIONE: Verranno copiati i file da:"
echo "   $BACKUP_DIR ➡️ $HOME"
echo "   Eventuali file con lo stesso nome saranno sovrascritti!"

read -p "✅ Vuoi procedere? [y/n] " confirm
if [ "$confirm" != "y" ]; then
  echo "❌ Ripristino annullato."
  exit 0
fi

> "$RESTORE_LOG" # Pulisci il file di log

# 🚀 Avvio ripristino
echo ""
echo "🔄 Ripristino dei file in corso..."

# Usa rsync per copiare i file (senza i file speciali o dispositivi)
rsync -avh --copy-unsafe-links --no-specials --no-devices "$BACKUP_DIR"/. "$HOME" \
  | tee >(grep -E '^\.|\/$' >> "$RESTORE_LOG") \
  | while read -r line; do
    if echo "$line" | grep -q '/$'; then
      echo "📁 Cartella ripristinata: $line"
    elif echo "$line" | grep -q '^\\.'; then
      echo "📄 File ripristinato: $line"
    fi
  done

# 🎉 Messaggio finale
echo ""
echo "✅ Ripristino completato con successo!"
echo "🏠 I file sono stati copiati nella tua home: $HOME"