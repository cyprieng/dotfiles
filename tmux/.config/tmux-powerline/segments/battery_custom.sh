# shellcheck shell=bash

get_battery_percent() {
  pmset -g batt | grep -o "[0-9][0-9]*\%" | rev | cut -c 2- | rev
}

get_charging_icon() {
  if /usr/sbin/ioreg -c AppleSmartBattery -w0 | grep -q "\"ExternalConnected\" = Yes"; then
    echo "󰚥 "
  fi
}

get_battery_icon() {
  local percent=$1

  if [ "$percent" -ge 80 ]; then
    echo "  "
  elif [ "$percent" -ge 66 ]; then
    echo "   "
  elif [ "$percent" -ge 50 ]; then
    echo "  "
  elif [ "$percent" -ge 30 ]; then
    echo "  "
  else
    echo "  "
  fi
}

run_segment() {
  battery_percent=$(get_battery_percent)

  # Show nothing if we dont have a battery
  if [ -z "$battery_percent" ]; then
    return 0
  fi

  echo "${TMUX_POWERLINE_SEPARATOR_LEFT_THIN} $(get_charging_icon)$battery_percent%$(get_battery_icon "$battery_percent")"
  return 0
}
