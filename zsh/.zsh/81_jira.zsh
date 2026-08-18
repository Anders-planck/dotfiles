# Jira API token, if present. Kept out of the repo — see ~/.config/zsh/secrets.zsh.
[[ -r "$HOME/.tokens/jira" ]] && export JIRA_API_TOKEN="$(<"$HOME/.tokens/jira")"
