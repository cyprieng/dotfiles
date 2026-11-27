#!/usr/bin/env bash
# How an AI agent shows up in Rex, called by agent-state.sh.
#
# The state is reported with the Program Status Protocol (OSC 7501); Claude Code
# and Codex emit it natively, so only Cursor needs it.
# Each agent labels its own pane, and rex-tabs.sh names the tabs from the pane
# labels, the way the tmux status line does.
#
# Usage: agent-state-rex.sh <claude|codex|cursor> <busy|waiting|done|title|clear>
#        agent-state-rex.sh <claude|codex|cursor> name <title>

flavor=$1
state=$2

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
    *) [ -e "$named" ] || pane=$(rex block call -s "$REX_BLOCK" -b "$REX_BLOCK" title '{}' 2>/dev/null |
      jq -r '.title // empty' | sed -E 's/^[^[:alnum:]]+//') ;;
  esac
  [ -n "$pane" ] && rex api call -s "$REX_BLOCK" session.set_block_label \
    "$(jq -nc --arg b "$REX_BLOCK" --arg l "$pane" '{block_id: $b, label: $l}')" >/dev/null 2>&1
}

[ "$flavor" = "cursor" ] && report_status
case "$state" in
  busy | done | clear | name)
    command -v jq &>/dev/null || exit 0
    label_pane "$@"
    # Tab names follow pane labels, see rex-tabs.sh
    nohup "$(dirname "$0")/rex-tabs.sh" "$REX_BLOCK" >/dev/null 2>&1 &
    ;;
esac
exit 0
