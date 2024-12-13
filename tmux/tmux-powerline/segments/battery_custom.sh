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
  echo "$(check_if_charging)$(get_battery_percent)%"
  return 0
}
