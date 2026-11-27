#!/usr/bin/env bash
# Agent titles are often generic, so in Rex the agent names its pane itself and
# agent-state.sh shows that name on the tab. Injected at session start only in
# Rex, to keep other sessions free of it.
#
# Usage: rex-tab-context.sh <claude|codex|cursor>
#        Cursor reads the context from JSON, Claude Code and Codex from plain stdout.

flavor=$1

# Cursor also runs the Claude Code hooks; it gets its own context.
if [ -z "${REX_BLOCK:-}" ] || { [ "$flavor" != "cursor" ] && [ -n "${CURSOR_INVOKED_AS:-}" ]; }; then
  [ "$flavor" = "cursor" ] && echo '{}'
  exit 0
fi

context=$(cat <<EOF
You're running in a Rex tab. Name it once you know the subject: right away if
the request states it, otherwise right after the first read that reveals it
(ticket, finding, PR, file). Never before. Skip it if you answer without any
tool call.

"\$HOME/.config/agents/agent-state.sh" $flavor name "<2-4 words>"

Name: 2 to 4 plain words saying what the work is about, for a human scanning
tabs (e.g. "zendesk ticket html injection", "hotel cancel refund bug"). Name the
subject, not the kind of task ("PR review", "finding check" say nothing). No
ticket or PR numbers, no quotes or apostrophes. Rename when the subject gets
clearer or changes, not for wording tweaks.
EOF
)

if [ "$flavor" = "cursor" ]; then
  jq -n --arg c "$context" '{additional_context: $c}'
else
  printf '%s\n' "$context"
fi
