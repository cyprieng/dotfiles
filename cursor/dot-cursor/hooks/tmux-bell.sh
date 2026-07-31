#!/usr/bin/env bash
# Ring the terminal bell on the tmux pane where Cursor CLI is running.

[ -n "$TMUX_PANE" ] || exit 0
tty=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_tty}' 2>/dev/null)
[ -n "$tty" ] && printf '\a' > "$tty"
