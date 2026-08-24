if type zoxide &> /dev/null; then
	# Cached: `zoxide init zsh` shells out, so pay it once. See 04_evalcache.zsh.
	# The fallback matters on a cold machine: 04_evalcache.zsh only defines
	# _evalcache when z4h has already cloned mroth/evalcache into $Z4H. Without
	# it this line used to fail with "command not found" and `z` was never
	# defined at all — the cache is an optimisation, not a dependency.
	if type _evalcache &> /dev/null; then
		_evalcache zoxide init zsh
	else
		eval "$(zoxide init zsh)"
	fi
else
	# Deliberately do NOT auto-install here. Piping `curl … | sh` from a startup
	# file is an unattended network fetch that can hang the shell before any
	# output is visible.
	print -ru2 -- 'zoxide not installed — run: brew install zoxide'
fi
