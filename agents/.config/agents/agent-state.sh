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
# Each agent labels its own pane, and rex-tabs.sh names the tabs from the pane
# labels, the way the tmux status line does.
#
# Usage: agent-state.sh <claude|codex|cursor> <busy|waiting|done|title|clear>
#        with the hook payload on stdin.
#        agent-state.sh <claude|codex|cursor> name <title>  (Rex only)

flavor=$1
state=$2

# Cursor also runs the Claude Code hooks; it is handled by its own hooks only.
[ "$flavor" != "cursor" ] && [ -n "${CURSOR_INVOKED_AS:-}" ] && exit 0

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

  # The pane label is the agent's title until the agent names itself with
  # `agent-state.sh <flavor> name <title>` (see rex-tab-context.sh), and goes
  # back to `shell` when the agent exits.
  label_pane() {
    # Marks a pane the agent named itself: keep that name (rex-tabs.sh removes it with the pane)
    local named="${TMPDIR:-/tmp}/rex-agent-named-${REX_BLOCK#block:}" pane
    case "$state" in
      # An empty label would give `Block <id>`, not the `shell` a pane starts with
      clear) pane=shell && rm -f "$named" ;;
      name) pane=$3 && : >"$named" ;;
      # Claude prefixes its title with a status glyph (✳ or a spinner)
      *) [ -e "$named" ] || pane=$(rex block call -s "$REX_SESSION" -b "$REX_BLOCK" title '{}' 2>/dev/null |
        jq -r '.title // empty' | sed -E 's/^[^[:alnum:]]+//') ;;
    esac
    [ -n "$pane" ] && rex api call -s "$REX_SESSION" session.set_block_label \
      "$(jq -nc --arg b "$REX_BLOCK" --arg l "$pane" '{block_id: $b, label: $l}')" >/dev/null 2>&1
  }

  [ "$flavor" = "cursor" ] && report_status
  case "$state" in
    busy | done | clear | name)
      command -v jq &>/dev/null || exit 0
      label_pane "$@"
      # Tab names follow pane labels, see rex-tabs.sh
      nohup "$(dirname "$0")/rex-tabs.sh" "$REX_SESSION" >/dev/null 2>&1 &
      ;;
  esac
  exit 0
fi

[ "$state" = "name" ] && exit 0

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
