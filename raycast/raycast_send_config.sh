#!/bin/bash

set -eo pipefail

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

# Use apple script to open raycast and launch export
osascript <<EOF
tell application "System Events"
    key code 49 using command down
    delay 0.5
    keystroke "export"
    delay 0.2
    keystroke return
    delay 0.2
    keystroke return
    delay 0.5
    key code 5 using {command down, shift down}
    delay 0.5
    keystroke "$BASEDIR"
    delay 0.5
    keystroke return
    delay 0.5
    keystroke return
end tell
EOF

# Wait for export to be created
sleep 2

# Rename file
rm "$BASEDIR/"config.rayconfig
mv "$(find "$BASEDIR" -name "*.rayconfig" -maxdepth 1)" "$BASEDIR/"config.rayconfig 2>/dev/null

# Send using croc
croc send "$BASEDIR/"config.rayconfig
