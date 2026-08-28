#!/usr/bin/env bash
# Single source of truth for how an AI agent shows up in the tmux status line.
# Called from both the Claude Code and the Cursor CLI hooks.
#
# The state lives in pane options rather than in the window name, so it dies
# with the pane: killing the agent, the pane or Ghostty needs no cleanup hook,
# and `automatic-rename` is never turned off. The powerline window format
# aggregates @agent_state and @agent_title over all the panes of a window, so
# an agent stays visible from a sibling pane (nvim, a shell, ...).
#
# Usage: agent-state.sh <claude|cursor> <busy|waiting|done|title|clear>
#        with the hook payload on stdin.

[ -n "${TMUX_PANE:-}" ] || exit 0

flavor=$1
state=$2

set_option() { tmux set-option -p -t "$TMUX_PANE" "$1" "$2"; }
unset_option() { tmux set-option -pu -t "$TMUX_PANE" "$1"; }

if [ "$state" = "clear" ]; then
  unset_option @agent_state
  unset_option @agent_title
  tmux refresh-client -S
  exit 0
fi

if [ "$state" != "title" ]; then
  previous=$(tmux show-options -pqv -t "$TMUX_PANE" @agent_state)
  set_option @agent_state "$state"

  # Ring once when entering a state that wants attention. The bell is only an
  # attention ping now — the colour is what carries the state.
  if [ "$state" != "$previous" ] && { [ "$state" = "waiting" ] || [ "$state" = "done" ]; }; then
    tty=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}')
    [ -n "$tty" ] && printf '\a' >"$tty"
  fi
fi

# The title only ever changes on a turn boundary, so skip the lookup on the hot
# `waiting` path (it fires on every tool call awaiting approval).
if [ "$state" != "waiting" ] && command -v jq &>/dev/null && ! [ -t 0 ]; then
  payload=$(cat)

  # Claude keeps its AI-generated title in the session transcript as an
  # {"type":"ai-title"} entry, not in the hook payload.
  claude_title() {
    local transcript
    transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // empty')
    [ -n "$transcript" ] && [ -f "$transcript" ] || return
    tac "$transcript" 2>/dev/null | grep -m1 '"type":"ai-title"' | jq -r '.aiTitle // empty'
  }

  # Cursor keeps it in ~/.cursor/chats/*/<conversation_id>/meta.json, and may
  # write it just after the stop hook fires — retry briefly in that case.
  cursor_title() {
    local id meta title
    id=$(printf '%s' "$payload" | jq -r '.conversation_id // empty')
    [ -n "$id" ] || return
    for _ in 1 2 3 4 5; do
      meta=$(find "$HOME/.cursor/chats" -path "*/$id/meta.json" 2>/dev/null | head -1)
      [ -n "$meta" ] && title=$(jq -r '.title // empty' "$meta")
      [ -n "$title" ] && break
      [ "$state" = "done" ] || break
      sleep 0.2
    done
    printf '%s' "$title"
  }

  title=$("${flavor}_title")
  [ -n "$title" ] && set_option @agent_title "$title"
fi

tmux refresh-client -S
