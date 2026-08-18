if type zoxide &> /dev/null; then
	# Cached: `zoxide init zsh` shells out, so pay it once. See 04_evalcache.zsh.
	_evalcache zoxide init zsh
else
	# Deliberately do NOT auto-install here. Piping `curl … | sh` from a startup
	# file is an unattended network fetch that can hang the shell before any
	# output is visible.
	print -ru2 -- 'zoxide not installed — run: brew install zoxide'
fi
