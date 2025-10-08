#!/bin/bash

MAX_RETRIES=3
retries=0

while [ "$retries" -le "$MAX_RETRIES" ]; do
  # Get the current pane ID at the start
  start_pane_id=$(tmux display-message -p "#{pane_id}")

  # Get the command running in that specific pane
  current_cmd=$(tmux display-message -p -F "#{pane_current_command}")

  if [ "$current_cmd" = "nvim" ]; then
    tmux set-option -p @pane-is-vim 1
  else
    tmux set-option -p @pane-is-vim 0
  fi

  # Get the current pane ID at the end
  end_pane_id=$(tmux display-message -p "#{pane_id}")

  # If the pane ID didn't change, we're done
  if [ "$start_pane_id" = "$end_pane_id" ]; then
    break
  fi

  # Otherwise, increment retry counter and try again
  retries=$((retries + 1))
done

if [ "$retries" -gt "$MAX_RETRIES" ]; then
  exit 1
fi
