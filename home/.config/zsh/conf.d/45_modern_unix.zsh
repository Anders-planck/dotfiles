# Modern replacements for the classic coreutils. All of these are plain binaries
# with no shell hook, so they cost nothing at startup.
#
# Aliases only affect interactive use — scripts still get the real tool. To reach
# the original from the prompt, prefix it: `command du`, `\du`.

if type dust &> /dev/null; then
	alias du=dust
fi

if type duf &> /dev/null; then
	alias df=duf
fi

if type procs &> /dev/null; then
	alias ps=procs
fi

if type btop &> /dev/null; then
	alias top=btop
	alias htop=btop
fi

if type sd &> /dev/null; then
	# Not aliased over sed: sd takes a different (regex-literal) syntax and would
	# silently break muscle memory. Use it explicitly.
	alias subst=sd
fi

if type yazi &> /dev/null; then
	# Official wrapper: leaves the shell in the directory yazi exited from.
	function y() {
		local tmp cwd
		tmp="$(mktemp -t yazi-cwd.XXXXXX)"
		yazi "$@" --cwd-file="$tmp"
		if cwd="$(command cat -- "$tmp")" && [[ -n $cwd && $cwd != $PWD ]]; then
			builtin cd -- "$cwd"
		fi
		command rm -f -- "$tmp"
	}
fi

if type fastfetch &> /dev/null; then
	alias neofetch=fastfetch
fi
