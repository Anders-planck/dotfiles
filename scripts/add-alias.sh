#!/bin/bash

# Percorso completo dove si trovano gli script
BACKUP_SCRIPT_PATH="$HOME/scripts/backup-config.sh"
RESTORE_SCRIPT_PATH="$HOME/scripts/restore-config.sh"
UNDO_SCRIPT_PATH="$HOME/scripts/undo-restore.sh"

# Funzione per aggiungere alias al file .zshrc
add_alias() {
    local alias_name=$1
    local command=$2
    local zshrc_file="$HOME/.zshrc"

    # Controlla se il file .zshrc esiste
    if [ ! -f "$zshrc_file" ]; then
        echo "⚠️  File .zshrc non trovato. Creazione di un nuovo file..."
        touch "$zshrc_file"
    fi

    # Controlla se l'alias esiste già nel file .zshrc
    if ! grep -q "^alias $alias_name=" "$zshrc_file"; then
        echo "Aggiungendo alias: $alias_name per il comando: $command"
        echo "alias $alias_name='$command'" >> "$zshrc_file"
    else
        echo "Alias $alias_name già presente nel file .zshrc"
    fi
}

# Aggiungi gli alias per i vari script
add_alias "backup-config" "$BACKUP_SCRIPT_PATH"
add_alias "restore-config" "$RESTORE_SCRIPT_PATH"
add_alias "undo-restore" "$UNDO_SCRIPT_PATH"

# Ricarica il file .zshrc per applicare gli alias
if [ -f "$HOME/.zshrc" ]; then
    echo "Ricaricando il file .zshrc..."
    exec zsh
else
    echo "⚠️  Impossibile ricaricare il file .zshrc perché non esiste."
fi

echo "✅ Alias aggiunti. Ora puoi eseguire gli script con i seguenti comandi:"
echo "  backup-config"
echo "  restore-config"
echo "  undo-restore"