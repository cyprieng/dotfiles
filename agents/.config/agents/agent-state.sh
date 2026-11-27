#!/usr/bin/env bash
# Single source of truth for how an AI agent shows up in tmux and Rex.
# Called from the Claude Code, Codex and Cursor CLI hooks; hands over to the
# script of the terminal the agent runs in.
#
# Usage: agent-state.sh <claude|codex|cursor> <busy|waiting|done|title|clear>
#        with the hook payload on stdin.
#        agent-state.sh <claude|codex|cursor> name <title>  (Rex only)

# Cursor also runs the Claude Code hooks; it is handled by its own hooks only.
[ "$1" != "cursor" ] && [ -n "${CURSOR_INVOKED_AS:-}" ] && exit 0

# exec keeps the hook's PID, so the Rex script can still find the agent above it
if [ -n "${TMUX_PANE:-}" ]; then
  exec "$(dirname "$0")/agent-state-tmux.sh" "$@"
elif [ -n "${REX_BLOCK:-}" ]; then
  exec "$(dirname "$0")/agent-state-rex.sh" "$@"
fi
