#!/bin/sh

# 📁 Directory di destinazione del backup
DEST_DIR="${BACKUP_DIR:-$HOME/Desktop/backup-configs}"

# 🧹 Lista di directory e file da escludere (editabile)
EXCLUDE="
.cache
.local
.Trash
.android
.vscode
.idea
.kube
.flutter-devtools
.pub-cache
.dart
.dart-tool
.dartServer
.cocoapods
.nuget
.console-ninja
.cursor
.cursor-tutor
.expo
.degit
.skiko
.livekit
.tamagui-repo-cache
.terminfo
.symfony5
.gem
.bun
.npm
.yarn
.nvm
.pnpm
.node-gyp
.nodules
.serverless
.parallels-desktop-vscode
.aws
.composer
.p2
.gk
.redhat
.hawtjni
.zsh_sessions
.matplotlib
.Library
.Music
.Movies
.Pictures
.gradle
.app-store
.eclipse
.docker
.emulator_console_auth_token
.swiftpm
.vscode-react-native
.crewai
.kaggle
.adonis_v6_repl_history
.CFUserTextEncoding
.flutter
.config/flutter
.config/zed
.config/swi-prolog
.config/configstore
.yarnrc.yml
.yarnrc
.bash_history
.zsh_history
Downloads
Documents
Library
"

# 🔧 Crea la directory di backup se non esiste
mkdir -p "$DEST_DIR"

# 🛡️ Costruisci le opzioni di esclusione per rsync
EXCLUDES=""
for path in $EXCLUDE; do
  EXCLUDES="$EXCLUDES --exclude=$path"
done

# 🚀 Inizio del processo
echo "🔄 Inizio backup dei dotfiles in: $DEST_DIR"
echo "📦 File e cartelle escluse:"

# 📋 Mostra la lista esclusa
for item in $EXCLUDE; do
  echo "  ⛔ $item"
done

echo ""
echo "📂 Copia dei file in corso..."

# 🧠 Rsync con log riga per riga e icone
rsync -avh --copy-unsafe-links --no-specials --no-devices $EXCLUDES "$HOME"/.[!.]* "$DEST_DIR" \
  | while read -r line; do
    if echo "$line" | grep -q '/$'; then
      echo "📁 Cartella: $line"
    elif echo "$line" | grep -q '^\.';
    then
      echo "📄 File: $line"
    fi
  done

# 🎉 Messaggio finale
echo ""
echo "✅ Backup completato con successo!"
echo "📍 Posizione: $DEST_DIR"