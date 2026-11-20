#!/usr/bin/env bash
# Agent titles are often generic, so in Rex the agent names its pane itself and
# agent-state.sh shows that name on the tab. Injected at session start only in
# Rex, to keep other sessions free of it.
#
# Usage: rex-tab-context.sh <claude|codex|cursor>
#        Cursor reads the context from JSON, Claude Code and Codex from plain stdout.

flavor=$1

# Cursor also runs the Claude Code hooks; it gets its own context.
if [ -z "${REX_SESSION:-}" ] || { [ "$flavor" != "cursor" ] && [ -n "${CURSOR_INVOKED_AS:-}" ]; }; then
  [ "$flavor" = "cursor" ] && echo '{}'
  exit 0
fi

context=$(cat <<EOF
You're running in a Rex tab. Your FIRST tool call of the conversation must
name it, before any other tool call, whatever the request (question, review,
investigation, code). Skip it only if you answer without any tool call.

"\$HOME/.config/agents/agent-state.sh" $flavor name "<2-4 words>"

Name: 2 to 4 plain words naming the specific subject, plus the ticket or PR
number if any (e.g. "review PR 9935 sentry"). No quotes or apostrophes.
If the subject only becomes clear later (e.g. after reading the PR), rename
once more then. Otherwise rename again only if the task changes.
EOF
)

if [ "$flavor" = "cursor" ]; then
  jq -n --arg c "$context" '{additional_context: $c}'
else
  printf '%s\n' "$context"
fi
