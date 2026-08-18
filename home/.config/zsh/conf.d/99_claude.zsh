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

	# Build claude command
	local cmd="cd '${project_dir}'"
	cmd+=" && claude"

	if [[ "$mode" == "yellow" ]]; then
		cmd+=" --dangerously-skip-permissions"
	fi

	if [[ "$resume" == true ]]; then
		cmd+=" --resume"
	fi

	if [[ -n "$model" ]]; then
		cmd+=" --model $model"
	fi

	if [[ "$print_mode" == true ]]; then
		cmd+=" --print"
	fi

	if [[ ${#extra_args[@]} -gt 0 ]]; then
		cmd+=" ${extra_args[*]}"
	fi

	# Launch in tmux
	if [[ -n "$TMUX" ]]; then
		# Already in tmux — create a new window
		tmux new-window -n "cc:${session_name}" "zsh -ic '${cmd}; zsh'"
	else
		# Not in tmux — create/attach a session
		tmux new-session -A -s "cc-${session_name}" "zsh -ic '${cmd}; zsh'"
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

	local base_cmd="cd '${project_dir}' && claude --dangerously-skip-permissions"

	if [[ -n "$TMUX" ]]; then
		# Create the lead window
		tmux new-window -n "cc:${session_name}"
		tmux send-keys "${base_cmd}" Enter

		# Split panes for teammates
		local i
		for i in $(seq 1 $workers); do
			if (( i % 2 == 1 )); then
				tmux split-window -h
			else
				tmux split-window -v
			fi
			tmux send-keys "${base_cmd}" Enter
		done

		# Even out the layout
		tmux select-layout tiled
		# Focus back on the lead (first pane)
		tmux select-pane -t 0
	else
		# Create a new tmux session with tiled panes
		tmux new-session -d -s "cc-${session_name}"
		tmux send-keys -t "cc-${session_name}" "${base_cmd}" Enter

		for i in $(seq 1 $workers); do
			tmux split-window -t "cc-${session_name}"
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
