#!/usr/bin/env bash
# Install these dotfiles.
#
#   ./install.sh              packages + symlinks + verification
#   ./install.sh --link-only  skip `brew bundle`
#   ./install.sh --dry-run    show what would change, touch nothing
#
# Everything under home/ is mirrored into $HOME as symlinks, file by file.
# Re-running is safe: existing symlinks are refreshed, and anything real that
# would be overwritten is moved to ~/.dotfiles-backup/<timestamp>/ first.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
src="$repo/home"
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

link_only=0
dry=0
for arg in "$@"; do
	case "$arg" in
		--link-only) link_only=1 ;;
		--dry-run) dry=1 ;;
		-h | --help)
			sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
			exit 0
			;;
		*)
			printf 'unknown option: %s\n' "$arg" >&2
			exit 2
			;;
	esac
done

say() { printf '\033[0;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33mwarn\033[0m %s\n' "$1"; }

[ -d "$src" ] || {
	printf 'missing %s\n' "$src" >&2
	exit 1
}

# ---- 1. packages ------------------------------------------------------------
if [ "$link_only" -eq 0 ] && [ -f "$repo/Brewfile" ]; then
	if command -v brew >/dev/null 2>&1; then
		say "brew bundle"
		if [ "$dry" -eq 1 ]; then
			brew bundle check --file="$repo/Brewfile" || true
		else
			brew bundle --file="$repo/Brewfile"
		fi
	else
		warn "Homebrew not installed — skipping packages. See https://brew.sh"
		warn "(deliberately not piping an installer from the network)"
	fi
fi

# ---- 2. symlinks ------------------------------------------------------------
# ~/.gitconfig shadows ~/.config/git/config: git reads the XDG file ONLY when
# ~/.gitconfig does not exist. Move it aside or the new config is silently dead.
if [ -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
	if [ "$dry" -eq 1 ]; then
		say "would move ~/.gitconfig aside (it shadows ~/.config/git/config)"
	else
		mkdir -p "$backup"
		mv -- "$HOME/.gitconfig" "$backup/"
		say "moved ~/.gitconfig -> $backup/ (it shadows ~/.config/git/config)"
	fi
fi

say "linking $src -> \$HOME"
linked=0
skipped=0
while IFS= read -r file; do
	rel="${file#"$src"/}"
	dst="$HOME/$rel"

	if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$file" ]; then
		skipped=$((skipped + 1))
		continue
	fi

	if [ "$dry" -eq 1 ]; then
		printf '  would link %s\n' "$rel"
		linked=$((linked + 1))
		continue
	fi

	mkdir -p -- "$(dirname -- "$dst")"
	if [ -e "$dst" ] && [ ! -L "$dst" ]; then
		mkdir -p -- "$backup/$(dirname -- "$rel")"
		mv -- "$dst" "$backup/$rel"
		printf '  backup %s\n' "$rel"
	fi
	ln -sfn -- "$file" "$dst"
	printf '  link   %s\n' "$rel"
	linked=$((linked + 1))
done < <(find "$src" -type f ! -name '.DS_Store' | sort)

say "$linked linked, $skipped already current"

# Prune links left behind by files that have since been removed from home/.
# Without this, deleting a config here leaves a dangling symlink in $HOME
# forever — and a dangling ~/.config/zsh/conf.d/*.zsh makes zsh error on start.
# Only look where we actually install: $HOME at depth 1, plus the top-level
# directories home/ provides. Walking all of $HOME takes minutes.
#
# Collected into a variable first, deliberately. macOS ships bash 3.2, whose
# parser mishandles a comment inside a `{ ... }` group inside `<( ... )` when the
# group also contains a `-print0 | while read -d ''` pipeline: the comment text
# is re-read as a command ("plus: command not found", "0: ambiguous redirect").
# Keeping the collection flat sidesteps it, and a here-doc feeds the loop without
# the subshell a pipeline would create — so the counter below survives.
collect_links() {
	find "$HOME" -maxdepth 1 -type l 2>/dev/null
	find "$src" -mindepth 1 -maxdepth 1 -type d 2>/dev/null |
		while IFS= read -r top; do
			d="$HOME/$(basename "$top")"
			[ -d "$d" ] && find "$d" -type l 2>/dev/null
		done
	return 0
}

pruned=0
while IFS= read -r dead; do
	[ -n "$dead" ] || continue
	[ -e "$dead" ] && continue # link still resolves — leave it
	target=$(readlink "$dead") || continue
	case "$target" in
		"$src"/*) ;;
		*) continue ;; # not ours — leave it alone
	esac
	if [ "$dry" -eq 1 ]; then
		printf '  would prune %s\n' "${dead#"$HOME"/}"
	else
		rm -- "$dead"
		printf '  prune  %s\n' "${dead#"$HOME"/}"
	fi
	pruned=$((pruned + 1))
done <<EOF
$(collect_links | sort -u)
EOF
[ "$pruned" -gt 0 ] && say "$pruned dangling link(s) pruned"

# ---- 3. secrets -------------------------------------------------------------
if [ "$dry" -eq 0 ]; then
	mkdir -p "$HOME/.config/zsh"
	chmod 700 "$HOME/.config/zsh"
	if [ ! -e "$HOME/.config/zsh/secrets.zsh" ]; then
		cp -- "$src/.config/zsh/secrets.zsh.example" "$HOME/.config/zsh/secrets.zsh"
		chmod 600 "$HOME/.config/zsh/secrets.zsh"
		say "seeded ~/.config/zsh/secrets.zsh (0600) — put your tokens there"
	fi

	# update_zsh on PATH, in a directory we can actually write to.
	bindir="$HOME/.local/bin"
	[ -w "$HOME/bin" ] && bindir="$HOME/bin"
	mkdir -p "$bindir"
	ln -sfn -- "$repo/bin/update" "$bindir/update_zsh" 2>/dev/null ||
		warn "could not write $bindir/update_zsh"
	for stale in "$HOME/bin/update_zsh" "$HOME/.local/bin/update_zsh"; do
		[ -L "$stale" ] && [ "$stale" != "$bindir/update_zsh" ] &&
			warn "stale updater on PATH: $stale -> $(readlink "$stale") (sudo rm it)"
	done
fi

# ---- 4. verify --------------------------------------------------------------
if [ "$dry" -eq 0 ] && [ -x "$repo/bin/bootstrap" ]; then
	say "verifying tools"
	"$repo/bin/bootstrap" --check || warn "some tools are missing — run bin/bootstrap"
fi

say "done"
[ -d "$backup" ] && say "replaced files are in $backup"
exit 0
