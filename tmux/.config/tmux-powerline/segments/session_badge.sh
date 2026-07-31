#!/usr/bin/env bash
# shellcheck shell=bash

# Compact session badge for the left status bar.

run_segment() {
  local session_name

  session_name=$(tmux display-message -p '#S')

  if [ ${#session_name} -gt 24 ]; then
    session_name="${session_name:0:23}…"
  fi

  echo "󰆍 ${session_name}"
}
