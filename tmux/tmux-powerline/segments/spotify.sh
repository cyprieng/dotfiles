# shellcheck shell=bash

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

run_segment() {
  get_spotify_status
  return 0
}
