#!/usr/bin/env bash
# Renames the current tmux window to Claude's AI-generated conversation
# title (the same one shown in `claude --resume`), when one exists.
# That title lives in the session transcript as a {"type":"ai-title"}
# entry, not in the hook payload itself. Otherwise leaves tmux's own
# automatic-rename untouched.

[ -n "$TMUX_PANE" ] || exit 0
command -v jq &>/dev/null || exit 0

transcript=$(jq -r '.transcript_path // empty')
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

title=$(tac "$transcript" 2>/dev/null | grep -m1 '"type":"ai-title"' | jq -r '.aiTitle // empty')
[ -n "$title" ] || exit 0

# tmux 3.7+ rejects window names containing a period (used as the
# window.pane separator in target parsing).
title=${title//./}

window=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}')
tmux set-window-option -t "$window" automatic-rename off
tmux rename-window -t "$window" "$title"
