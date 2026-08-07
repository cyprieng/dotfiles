#!/usr/bin/env bash
set -uo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo 'dwt: gh CLI required (brew install gh && gh auth login)' >&2
  exit 1
fi

force_remove=false
for arg in "$@"; do
  case "$arg" in
    -D|--force|-f) force_remove=true ;;
    -h|--help)
      echo 'usage: git dwt [-D]  # remove worktrees with merged GitHub PRs'
      echo '  -D  force worktree remove (dirty/untracked files)'
      exit 0
      ;;
    *)
      echo "dwt: unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

default_branch=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
default_branch=${default_branch:-main}
git fetch origin "$default_branch" --quiet 2>/dev/null || true
git worktree prune --quiet 2>/dev/null || true

mapfile -t merged_pr_heads < <(gh pr list --state merged --limit 1000 --json headRefName --jq '.[].headRefName' 2>/dev/null || true)
mapfile -t merged_git < <(git branch --merged "origin/$default_branch" 2>/dev/null | sed 's/^[*+ ] //' || true)

current=$(git rev-parse --show-toplevel)
removed=0
failed=0

is_merged_branch() {
  local branch=$1
  local head

  for head in "${merged_pr_heads[@]}"; do
    [[ "$head" == "$branch" ]] && return 0
  done

  for head in "${merged_git[@]}"; do
    [[ "$head" == "$branch" ]] && return 0
  done

  return 1
}

remove_worktree() {
  local path=$1 branch=$2
  local err

  if [[ "$force_remove" == true ]]; then
    if ! err=$(git worktree remove -f "$path" 2>&1); then
      echo "dwt: skip $branch — ${err##*$'\n'}" >&2
      failed=$((failed + 1))
      return
    fi
  elif ! err=$(git worktree remove "$path" 2>&1); then
    echo "dwt: skip $branch — ${err##*$'\n'}" >&2
    failed=$((failed + 1))
    return
  fi

  if ! err=$(git branch -D "$branch" 2>&1); then
    echo "dwt: removed worktree but not branch $branch — ${err##*$'\n'}" >&2
    failed=$((failed + 1))
    return
  fi

  echo "dwt: removed $path [$branch]"
  removed=$((removed + 1))
}

mapfile -t candidates < <(
  path=''
  branch=''
  while IFS= read -r line; do
    case "$line" in
      worktree\ *) path="${line#worktree }"; branch='' ;;
      branch\ *) branch="${line#branch refs/heads/}" ;;
      detached) branch='' ;;
    esac

    [[ -n "$branch" ]] || continue
    case "$branch" in main|master) continue ;; esac
    [[ "$path" == "$current" ]] && continue
    is_merged_branch "$branch" || continue

    printf '%s\037%s\n' "$path" "$branch"
  done < <(git worktree list --porcelain) | sort -u
)

for entry in "${candidates[@]}"; do
  IFS=$'\037' read -r path branch <<< "$entry"
  remove_worktree "$path" "$branch"
done

echo "dwt: done — $removed removed, $failed failed"
[[ "$failed" -eq 0 ]]
