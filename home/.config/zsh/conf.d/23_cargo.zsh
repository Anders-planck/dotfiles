# Rust comes from rustup, which Homebrew installs keg-only: its rustc/cargo
# proxies live in $HOMEBREW_PREFIX/opt/rustup/bin and are on no PATH by default.
# Without this, `cargo` is missing — or resolves to a stray `brew install rust`,
# which has none of the cross-compilation targets rustup manages.
[[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/opt/rustup/bin" ]] &&
	path=("$HOMEBREW_PREFIX/opt/rustup/bin" $path)

# `cargo install` binaries (cargo-xwin, sqlx, ...).
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
