# Language runtimes: mise, and only mise.
#
# This file used to initialise five separate managers — pyenv, nodenv, rbenv,
# phpenv, jenv — plus sourcing asdf, each with its own `_evalcache <tool> init`
# and its own PATH shim layer. Combined with nvm/asdf/fnm installed via brew,
# that was up to nine tools competing for the same PATH entries, and the winner
# depended on file load order.
#
# mise replaces all of them: it is a drop-in for nvm/nodenv (reads .nvmrc and
# .node-version), for pyenv, rbenv, and for asdf's plugin ecosystem.
#
#   mise use -g node@24        set a global version
#   mise use python@3.13       pin one for the current project (writes mise.toml)
#   mise ls --current          what is active here and where it came from
#
# Global versions live in ~/.config/mise/config.toml, pinned rather than "latest".
# `mise activate` is wired at the end of .zshrc — this file intentionally does
# nothing but document that.

if ! type mise &> /dev/null; then
	print -ru2 -- 'mise not installed — language runtimes will not resolve. See https://mise.jdx.dev'
fi
