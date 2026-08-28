#!/usr/bin/env bash
# Mark the pane as waiting only when Cursor is likely to show an approval prompt.
#
# beforeShellExecution / beforeMCPExecution fire on every tool call, even when
# approvalMode is "unrestricted" and nothing is shown to the user. Stay silent
# in that case; flag only in allowlist mode for commands/tools not on the list.

set -euo pipefail

mark_waiting() {
  "$HOME/.config/tmux/agent-state.sh" cursor waiting </dev/null
}

command -v jq &>/dev/null || exit 0

config="${HOME}/.cursor/cli-config.json"
[ -f "$config" ] || exit 0

approval_mode=$(jq -r '.approvalMode // "allowlist"' "$config")
# unrestricted / Run Everything: auto-approved, no user action needed
[ "$approval_mode" = "allowlist" ] || exit 0

input=$(cat)
event=$(echo "$input" | jq -r '.hook_event_name // empty')

shell_allowed() {
  local cmd=$1 pattern inner
  while IFS= read -r pattern; do
    case "$pattern" in
      Shell\(*\))
        inner=${pattern#Shell(}
        inner=${inner%)}
        if [ "$inner" = "**" ] || [ "$cmd" = "$inner" ] || [[ "$cmd" == "$inner"* ]]; then
          return 0
        fi
        ;;
    esac
  done < <(jq -r '.permissions.allow[]? // empty' "$config")
  return 1
}

mcp_allowed() {
  local tool=$1 pattern inner
  while IFS= read -r pattern; do
    case "$pattern" in
      Mcp\(*\))
        inner=${pattern#Mcp(}
        inner=${inner%)}
        # Patterns look like "server-name:tool_name"
        if [ "$inner" = "**" ] || [ "$inner" = "*:$tool" ] || [[ "$inner" == *":$tool" ]]; then
          return 0
        fi
        ;;
    esac
  done < <(jq -r '.permissions.allow[]? // empty' "$config")
  return 1
}

case "$event" in
  beforeShellExecution)
    cmd=$(echo "$input" | jq -r '.command // empty')
    [ -n "$cmd" ] || exit 0
    shell_allowed "$cmd" || mark_waiting
    ;;
  beforeMCPExecution)
    tool=$(echo "$input" | jq -r '.tool_name // empty')
    [ -n "$tool" ] || exit 0
    mcp_allowed "$tool" || mark_waiting
    ;;
esac

exit 0
