# shellcheck shell=bash

generate_segmentrc() {
  read -r -d '' rccontents <<EORC
# Output the current playing song from spotify-player"
EORC
  echo "$rccontents"
}

get_spotify_status() {
  local spotify_info
  spotify_info=$(/opt/homebrew/bin/spotify_player get key playback |
    jq -r 'if .item == null then 
                   "" 
               else 
                   (.item.name + " - " + .item.artists[0].name) 
               end')
  echo "$spotify_info"
}

run_segment() {
  get_spotify_status
  return 0
}
