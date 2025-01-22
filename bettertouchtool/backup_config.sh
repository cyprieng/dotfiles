#!/bin/zsh

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

# Get Plist
cp ~/Library/Preferences/com.hegenberg.BetterTouchTool.plist "$BASEDIR/com.hegenberg.BetterTouchTool.plist"

# Remove old data
lastconfig=$(eza "$BASEDIR/library" | grep "btt_data_store" | grep "wal" | sort | tail -1 | sed 's/-wal$//')
for file in $BASEDIR/library/btt_data_store*(N); do
  if [[ $file != *"$lastconfig"* ]]; then
    rm "$file"
  fi
done
