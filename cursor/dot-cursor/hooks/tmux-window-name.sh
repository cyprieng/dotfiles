#!/usr/bin/env bash
# Renames the current tmux window to Cursor's AI-generated conversation title
# (the same one shown in the CLI session list). That title lives in
# ~/.cursor/chats/*/<conversation_id>/meta.json, not in the hook payload.

[ -n "$TMUX_PANE" ] || exit 0
command -v jq &>/dev/null || exit 0

input=$(cat)
conversation_id=$(echo "$input" | jq -r '.conversation_id // empty')
[ -n "$conversation_id" ] || exit 0

find_title() {
  local meta
  meta=$(find "${HOME}/.cursor/chats" -path "*/${conversation_id}/meta.json" 2>/dev/null | head -1)
  [ -n "$meta" ] && [ -f "$meta" ] || return 1
  jq -r '.title // empty' "$meta"
}

title=$(find_title)

# On stop, Cursor may write the title just after the hook fires — retry briefly.
if [ -z "$title" ] && [ "$(echo "$input" | jq -r '.hook_event_name // empty')" = "stop" ]; then
  for _ in 1 2 3 4 5; do
    sleep 0.2
    title=$(find_title)
    [ -n "$title" ] && break
  done
fi

[ -n "$title" ] || exit 0

# tmux 3.7+ rejects window names containing a period (used as the
# window.pane separator in target parsing).
title=${title//./}

window=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}')
tmux set-window-option -t "$window" automatic-rename off
tmux rename-window -t "$window" "$title"
