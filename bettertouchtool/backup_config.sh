#!/bin/zsh

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

# Get Plist
cp ~/Library/Preferences/com.hegenberg.BetterTouchTool.plist "$BASEDIR/Library/Preferences/com.hegenberg.BetterTouchTool.plist"

# Remove old data
BTT_DIR="$BASEDIR/Library/Application Support/BetterTouchTool"
lastconfig=$(ls "$BTT_DIR" | grep "btt_data_store" | grep -v "tmp_backup" | grep -- "-wal$" | sort | tail -1 | sed 's/-wal$//')
[[ -n $lastconfig ]] || { echo "No BTT data store found, skipping cleanup"; exit 1; }
for file in "$BTT_DIR"/btt_data_store*(N); do
  if [[ $file != *"$lastconfig"* ]]; then
    rm "$file"
  fi
done
