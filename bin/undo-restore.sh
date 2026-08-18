#!/bin/sh

RESTORE_LOG="$HOME/restore-log.txt"

# 🔍 Verifica se esiste il log del restore
if [ ! -f "$RESTORE_LOG" ]; then
  echo "❌ Nessun file di log trovato. Impossibile annullare il ripristino."
  exit 1
fi

echo "⚠️ ATTENZIONE: Verranno eliminati i file e le cartelle ripristinati da $RESTORE_LOG"
read -p "✅ Sei sicuro? [y/n] " confirm
if [ "$confirm" != "y" ]; then
  echo "❌ Annullamento operazione."
  exit 0
fi

# 🧽 Rimozione file
echo ""
echo "🗑️ Cancellazione file e cartelle ripristinati..."

# Elimina in ordine inverso (prima i file, poi le cartelle vuote)
tac "$RESTORE_LOG" | while read -r path; do
  FULL_PATH="$HOME/$path"
  if [ -f "$FULL_PATH" ]; then
    rm -f "$FULL_PATH" && echo "❌ File rimosso: $path"
  elif [ -d "$FULL_PATH" ]; then
    rmdir "$FULL_PATH" 2>/dev/null && echo "🗑️ Cartella rimossa (vuota): $path"
  fi
done

echo ""
echo "✅ Ripristino annullato con successo!"
rm "$RESTORE_LOG"