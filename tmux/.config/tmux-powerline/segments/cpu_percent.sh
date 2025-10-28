# shellcheck shell=bash

# Run segment
run_segment() {
  top -e -l 1 | grep "CPU usage" | awk -F'[:,%]' '{printf " %d%%\n", ($2+$4)}'
}
