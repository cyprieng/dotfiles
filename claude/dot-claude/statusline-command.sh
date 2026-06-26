#!/usr/bin/env bash
# Claude Code statusline: model | git branch | cwd basename | session cost
# Receives JSON on stdin from Claude Code; see https://docs.claude.com/en/docs/claude-code/statusline

set -u

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0')
ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty' | cut -d. -f1)

cwd_base=""
[ -n "$cwd" ] && cwd_base=$(basename "$cwd")

branch=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
        || git -C "$cwd" rev-parse --short HEAD 2>/dev/null \
        || true)
fi

# ANSI: bold + color, dim separators. Mirrors zsh prompt palette.
R=$'\e[0m'; B=$'\e[1m'; D=$'\e[2m'
CYAN=$'\e[36m'; MAGENTA=$'\e[35m'; YELLOW=$'\e[33m'; GREY=$'\e[90m'; GREEN=$'\e[32m'
SEP="${D}${GREY} · ${R}"

parts=()
[ -n "$model" ]    && parts+=("${GREY}󰚩${R} ${model}")
[ -n "$branch" ]   && parts+=("${MAGENTA}󰘬${R} ${B}${MAGENTA}${branch}${R}")
[ -n "$cwd_base" ] && parts+=("${CYAN}󰉋${R} ${B}${CYAN}${cwd_base}${R}")
[ -n "$ctx" ]      && parts+=("${GREEN}󰍛${R} ${B}${GREEN}${ctx}%${R}")
parts+=("${YELLOW}${R} ${B}${YELLOW}$(printf '$%.2f' "$cost")${R}")

out=""
for i in "${!parts[@]}"; do
  [ "$i" -gt 0 ] && out+="$SEP"
  out+="${parts[$i]}"
done
printf '%s' "$out"
