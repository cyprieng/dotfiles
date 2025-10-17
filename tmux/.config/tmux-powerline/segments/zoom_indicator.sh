#!/usr/bin/env bash

# Displays a zoom indicator when a pane is zoomed
run_segment() {
  # Check if current pane is zoomed
  if [ "$(tmux display-message -p '#{window_zoomed_flag}')" = "1" ]; then
    echo "🔍 ZOOM"
  else
    return
  fi
}
