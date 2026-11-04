#!/usr/bin/env bash
# Single source of truth for how an AI agent shows up in tmux and Rex.
# Called from the Claude Code, Codex and Cursor CLI hooks.
#
# The state lives in pane options rather than in the window name, so it dies
# with the pane: killing the agent, the pane or Ghostty needs no cleanup hook,
# and `automatic-rename` is never turned off. The powerline window format
# aggregates @agent_state and @agent_title over all the panes of a window, so
# an agent stays visible from a sibling pane (nvim, a shell, ...).
#
#
# Outside tmux, in Rex, the state is reported with the Program Status Protocol
# (OSC 7501) instead; Claude Code and Codex emit it natively, so only Cursor needs it.
# Rex has no per-pane options, so the agent's own pane title becomes the tab
# label instead, keeping it visible whichever pane of the tab has the focus.
#
# Usage: agent-state.sh <claude|codex|cursor> <busy|waiting|done|title|clear>
#        with the hook payload on stdin.

flavor=$1
state=$2

if [ -z "${TMUX_PANE:-}" ]; then
  [ -n "${REX_BLOCK:-}" ] || exit 0

  report_status() {
    local status pid tty
    case "$state" in
      busy) status="state=working" ;;
      waiting) status="state=blocked:kind=permission" ;;
      done) status="state=done" ;;
      clear) status="state=clear" ;;
      *) return ;;
    esac
    # Hooks run without a controlling terminal; the agent above them has one.
    pid=$PPID
    while [ "${pid:-1}" -gt 1 ]; do
      tty=$(ps -o tty= -p "$pid" | tr -d ' ')
      case "$tty" in
        "" | "?" | "??") ;;
        *)
          printf '\033]7501;%s:app=cursor-agent\033\\' "$status" >"/dev/$tty"
          return
          ;;
      esac
      pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
    done
  }

  # Unlike a tmux pane option, a tab label outlives the agent, so the label set
  # here is remembered: it is only replaced or removed while it is still ours,
  # and a tab renamed by hand is left alone.
  name_tab() {
    command -v jq &>/dev/null || return
    local window file mine label title
    window=$(rex whoami --json 2>/dev/null | jq -r '.window_id // empty')
    [ -n "$window" ] || return
    file="${TMPDIR:-/tmp}/rex-agent-tab-${window#window:}"
    mine=$(cat "$file" 2>/dev/null)
    label=$(rex window ls -s "$REX_SESSION" --json 2>/dev/null |
      jq -r --arg w "$window" '.windows[] | select(.window_id == $w) | .label')

    if [ "$state" = "clear" ]; then
      # An empty label restores the default, which shows the focused pane title
      [ -n "$mine" ] && [ "$label" = "$mine" ] &&
        rex api call -s "$REX_SESSION" session.set_window_label "{\"window_id\":\"$window\",\"label\":\"\"}" >/dev/null
      rm -f "$file"
      return
    fi

    [ -n "$mine" ] && [ "$label" = "$mine" ] || [[ "$label" =~ ^Window\ [0-9a-f]{8}$ ]] || return
    # Claude prefixes its title with a status glyph (✳ or a spinner)
    title=$(rex block call -s "$REX_SESSION" -b "$REX_BLOCK" title '{}' 2>/dev/null |
      jq -r '.title // empty' | sed -E 's/^[^[:alnum:]]+//')
    [ -n "$title" ] && [ "$title" != "$label" ] || return
    rex window rename -s "$REX_SESSION" "$window" "$title" >/dev/null && printf '%s' "$title" >"$file"
  }

  [ "$flavor" = "cursor" ] && report_status
  case "$state" in
    busy | done | clear) name_tab ;;
  esac
  exit 0
fi

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

  # Codex publishes its conversation title directly to the terminal.
  codex_title() {
    tmux display-message -p -t "$TMUX_PANE" '#{pane_title}' 2>/dev/null |
      sed -E 's/^[^[:alnum:]]+//'
  }

  title=$("${flavor}_title")
  [ -n "$title" ] && set_option @agent_title "$title"
fi

tmux refresh-client -S
