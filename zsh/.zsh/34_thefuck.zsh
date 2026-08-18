if type thefuck &> /dev/null; then
    # `thefuck --alias` takes ~900 ms (Python interpreter startup), which would
    # be paid on every single shell. Cache it — see 04_evalcache.zsh.
    _evalcache thefuck --alias
fi
