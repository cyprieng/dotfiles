#!/usr/bin/env bash
# Names the tabs of a Rex session after the agents in them, as the tmux status
# line does: agents only label their own pane (agent-state.sh), and this listener
# derives every tab name from the session's current panes each time its layout
# changes, so moving, closing or renaming a pane is picked up at once.
#
# A tab shows the label of its newest agent pane (block IDs sort by creation).
# A tab without agent gets its default name back only when it shows a name this
# listener gave it or the name of an agent living elsewhere: a tab renamed by
# hand is left alone.
#
# Usage: rex-tabs.sh <block>
#        started by agent-state.sh on every hook with the agent's block; a second
#        instance for the same session exits at once, and the listener stops with
#        its session.

[ -n "$1" ] && command -v jq &>/dev/null || exit 1
# Rex no longer exports REX_SESSION; the lock needs the session ID, not a block ID
session=$(REX_BLOCK=$1 rex whoami --json 2>/dev/null | jq -r '.session_id // empty')
[ -n "$session" ] || exit 1
tmp=${TMPDIR:-/tmp}
lock="$tmp/rex-tabs-${session#session:}.pid"

if ! (set -C && echo $$ >"$lock") 2>/dev/null; then
  kill -0 "$(cat "$lock" 2>/dev/null)" 2>/dev/null && exit 0
  rm -f "$lock"
  (set -C && echo $$ >"$lock") 2>/dev/null || exit 0
fi

# Tab names this listener set, by window ID
owned='{}'

name_tabs() {
  local blocks windows plan
  blocks=$(rex block ls -s "$session" --json 2>/dev/null) || return
  windows=$(rex window ls -s "$session" --json 2>/dev/null) || return
  # An agent still on its generic title ("Claude Code") doesn't count until it names itself
  plan=$(jq -nc --argjson b "$blocks" --argjson w "$windows" --argjson owned "$owned" '
    [$b.blocks[] | select(.label | test("^(shell|Block [0-9a-f]{8}|claude code|codex|cursor agent)$"; "i") | not)] as $agents
    | [$w.windows[]
      | .window_id as $id | .label as $label
      | ([$agents[] | select(.window_id == $id)] | sort_by(.block_id) | last | .label) as $title
      | if $title then {$id, $label, want: $title}
        elif $owned[$id] == $label or any($agents[]; .label == $label) then {$id, $label, want: ""}
        else empty end]
    | {set: [.[] | select(.want != .label) | [.id, .want]],
       owned: [.[] | select(.want != "") | {key: .id, value: .want}] | from_entries}')
  owned=$(jq -c .owned <<<"$plan")
  jq -r '.set[] | @tsv' <<<"$plan" | while IFS=$'\t' read -r window title; do
    rex api call -s "$session" session.set_window_label \
      "$(jq -nc --arg w "$window" --arg l "$title" '{window_id: $w, label: $l}')" >/dev/null 2>&1
  done
}

# `rex events` outlives a closed session, `rex wait` doesn't
exec 3< <(exec rex events -s "$session" --json 2>/dev/null)
events=$!
rex wait "$session" >/dev/null 2>&1 && kill "$events" 2>/dev/null &
waiter=$!
trap 'kill "$events" "$waiter" 2>/dev/null; rm -f "$lock"' EXIT

name_tabs
while read -r -u 3 event; do
  # A move or a close comes as a burst of events: rename once it settles
  changed=
  while :; do
    case $event in
      *'"type":"session_view_changed"'*) changed=1 ;;
      *'"type":"block_closed"'*)
        [[ $event =~ \"block_id\":\"block:([^\"]+)\" ]] && rm -f "$tmp/rex-agent-named-${BASH_REMATCH[1]}"
        ;;
    esac
    read -r -t 0.2 -u 3 event || break
  done
  [ -n "$changed" ] && name_tabs
done
