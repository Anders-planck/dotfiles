# =============================================
# Claude Code — shell helpers
# =============================================

# Quick alias: Claude in yellow mode (bypass permissions)
alias cc='claude --dangerously-skip-permissions'

# Claude in a dedicated tmux window with full options
# Usage: ccs [options] [session-name]
#   -n, --normal     Normal mode (no bypass)
#   -r, --resume     Resume last conversation
#   -m, --model      Model to use (opus, sonnet, haiku)
#   -p, --print      Print mode (non-interactive)
#   -d, --dir        Working directory (default: current)
#   -h, --help       Show help
function ccs() {
	local session_name=""
	local project_dir="$(pwd)"
	local mode="yellow"
	local resume=false
	local model=""
	local print_mode=false
	local extra_args=()

	while [[ $# -gt 0 ]]; do
		case $1 in
			-n|--normal)   mode="normal"; shift ;;
			-y|--yellow)   mode="yellow"; shift ;;
			-r|--resume)   resume=true; shift ;;
			-m|--model)    model="$2"; shift 2 ;;
			-p|--print)    print_mode=true; shift ;;
			-d|--dir)      project_dir="$2"; shift 2 ;;
			-h|--help)     _ccs_help; return 0 ;;
			-*)            extra_args+=("$1"); shift ;;
			*)             session_name="$1"; shift ;;
		esac
	done

	# Auto-generate session name from git repo or directory
	if [[ -z "$session_name" ]]; then
		local repo_name
		repo_name=$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null)
		session_name="${repo_name:-$(basename "$project_dir")}"
	fi

	# Build the claude argv, then quote it exactly once.
	#
	# This used to be `local cmd="cd '${project_dir}'"` with hand-written single
	# quotes, nested inside another single-quoted string handed to tmux — which
	# runs it through /bin/sh. Any apostrophe or space in the path closed the
	# quote early, so `~/Dev/Anders' Projects` broke the function outright and a
	# directory named `a'$(...)'b` executed its own contents. Same flaw in the
	# unquoted `--model $model` and `${extra_args[*]}`.
	#
	# ${(q@)...} is zsh's own quoting, applied per array element: it escapes for
	# exactly one round of shell parsing, which is what tmux gives us. The @ is
	# load-bearing — plain ${(q)argv} inside a join flattens the array first and
	# escapes the separators too, producing one unrunnable command name.
	local -a argv
	argv=(claude)
	[[ "$mode" == "yellow" ]] && argv+=(--dangerously-skip-permissions)
	[[ "$resume" == true ]] && argv+=(--resume)
	[[ -n "$model" ]] && argv+=(--model "$model")
	[[ "$print_mode" == true ]] && argv+=(--print)
	(( ${#extra_args[@]} )) && argv+=("${extra_args[@]}")

	local cmd="${(j: :)${(q@)argv}}; zsh"

	# Launch in tmux. -c sets the working directory, so the path never has to
	# survive a trip through the shell at all.
	if [[ -n "$TMUX" ]]; then
		tmux new-window -c "$project_dir" -n "cc:${session_name}" zsh -ic "$cmd"
	else
		tmux new-session -A -s "cc-${session_name}" -c "$project_dir" zsh -ic "$cmd"
	fi
}

# Claude Agent Team: opens lead + N teammate panes
# Usage: ccteam [options] [session-name]
#   -w, --workers N  Number of teammate panes (default: 2)
#   -d, --dir        Working directory
#   -h, --help       Show help
function ccteam() {
	local session_name=""
	local project_dir="$(pwd)"
	local workers=2

	while [[ $# -gt 0 ]]; do
		case $1 in
			-w|--workers)  workers="$2"; shift 2 ;;
			-d|--dir)      project_dir="$2"; shift 2 ;;
			-h|--help)     _ccteam_help; return 0 ;;
			-*)            shift ;;
			*)             session_name="$1"; shift ;;
		esac
	done

	if [[ -z "$session_name" ]]; then
		local repo_name
		repo_name=$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null)
		session_name="${repo_name:-$(basename "$project_dir")}-team"
	fi

	# Same quoting rule as ccs: -c gives tmux the directory, so it never travels
	# through a shell. send-keys types into a live shell, so what it types must be
	# valid input — ${(q)} makes it so even for a path with spaces or quotes.
	local base_cmd="claude --dangerously-skip-permissions"

	if [[ -n "$TMUX" ]]; then
		# Create the lead window
		tmux new-window -c "$project_dir" -n "cc:${session_name}"
		tmux send-keys "${base_cmd}" Enter

		# Split panes for teammates
		local i
		for i in $(seq 1 $workers); do
			if (( i % 2 == 1 )); then
				tmux split-window -c "$project_dir" -h
			else
				tmux split-window -c "$project_dir" -v
			fi
			tmux send-keys "${base_cmd}" Enter
		done

		# Even out the layout
		tmux select-layout tiled
		# Focus back on the lead (first pane)
		tmux select-pane -t 0
	else
		# Create a new tmux session with tiled panes
		tmux new-session -d -s "cc-${session_name}" -c "$project_dir"
		tmux send-keys -t "cc-${session_name}" "${base_cmd}" Enter

		for i in $(seq 1 $workers); do
			tmux split-window -c "$project_dir" -t "cc-${session_name}"
			tmux send-keys "${base_cmd}" Enter
			tmux select-layout -t "cc-${session_name}" tiled
		done

		tmux select-pane -t "cc-${session_name}":0.0
		tmux attach -t "cc-${session_name}"
	fi
}

# Help functions
function _ccs_help() {
	cat <<'EOF'
ccs — Claude Code Session (tmux)

Usage: ccs [options] [session-name]

Options:
  -n, --normal     Normal mode (with permission prompts)
  -y, --yellow     Yellow mode / bypass permissions (default)
  -r, --resume     Resume last conversation
  -m, --model M    Model: opus, sonnet, haiku
  -p, --print      Print mode (non-interactive, pipe-friendly)
  -d, --dir DIR    Working directory (default: current)
  -h, --help       Show this help

Examples:
  ccs                     # Yellow mode, auto-named from git repo
  ccs my-project          # Named session
  ccs -r                  # Resume last conversation
  ccs -m haiku            # Use haiku model
  ccs -n -d ~/work/api    # Normal mode in specific dir
EOF
}

function _ccteam_help() {
	cat <<'EOF'
ccteam — Claude Agent Team (tmux split panes)

Usage: ccteam [options] [session-name]

Options:
  -w, --workers N  Number of teammate panes (default: 2)
  -d, --dir DIR    Working directory (default: current)
  -h, --help       Show this help

Examples:
  ccteam                  # 1 lead + 2 workers, auto-named
  ccteam my-feature       # Named team session
  ccteam -w 3             # 1 lead + 3 workers
  ccteam -w 1 -d ~/api    # Minimal team in specific dir

Note: Agent Teams require CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
      (already configured in ~/.claude/settings.json)
EOF
}
