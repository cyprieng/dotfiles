# shellcheck shell=bash

get_battery_percent() {
  pmset -g batt | grep -o "[0-9][0-9]*\%" | rev | cut -c 2- | rev
}

check_if_charging() {
  if /usr/sbin/ioreg -c AppleSmartBattery -w0 | grep -q "\"ExternalConnected\" = Yes"; then
    echo "󰚥 "
  fi
}

run_segment() {
  battery_percent=$(get_battery_percent)

  # Show nothing if we dont have a battery
  if [ -z "$battery_percent" ]; then
    return 0
  fi

  echo "${TMUX_POWERLINE_SEPARATOR_LEFT_THIN} $(check_if_charging)$battery_percent%"
  return 0
}
