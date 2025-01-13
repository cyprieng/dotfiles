# shellcheck shell=bash

# Duration between updates in seconds.
TMUX_POWERLINE_SEG_SPOTIFY_UPDATE_PERIOD="10"

# Get spotify status using spotify_player
get_spotify_status() {
  local spotify_info
  spotify_info=$(timeout 2 /opt/homebrew/bin/spotify_player get key playback |
    jq -r 'if .item == null then 
                   "" 
               else 
                   (.item.name + " - " + .item.artists[0].name) 
               end')
  echo "${spotify_info:-}"
}

# Run segment
run_segment() {
  # Check if we have a temp file
  local tmp_file="${TMUX_POWERLINE_DIR_TEMPORARY}/temp_spotify.txt"
  if [ -f "$tmp_file" ]; then
    last_update=$(stat -f "%m" "${tmp_file}")
    time_now=$(date +%s)
    up_to_date=$(echo "(${time_now}-${last_update}) < ${TMUX_POWERLINE_SEG_SPOTIFY_UPDATE_PERIOD}" | bc)
    if [ "$up_to_date" -eq 1 ]; then
      # File is up to date -> return content
      __read_tmp_file
    fi
  fi

  # Update file
  get_spotify_status >"${tmp_file}"
  __read_tmp_file

  return 0
}

# Read temp file
__read_tmp_file() {
  if [ ! -f "$tmp_file" ]; then
    return
  fi
  cat "${tmp_file}"
  exit
}
