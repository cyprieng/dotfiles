#!/bin/bash

set -eo pipefail

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

# The preferences domain also holds app state (window frames, last session, sync servers...),
# so only the settings listed in settings.keys are saved
PREFS=$(mktemp)
trap 'rm -f "$PREFS"' EXIT
defaults export com.superlogical.rex "$PREFS"

OUT="$BASEDIR/settings.plist"
plutil -create xml1 "$OUT"
while read -r key; do
  # plutil key paths split on dots
  path=${key//./\\.}
  value=$(plutil -extract "$path" xml1 -o - "$PREFS" 2>/dev/null) || continue
  plutil -insert "$path" -xml "$value" "$OUT"
done < "$BASEDIR/settings.keys"

echo "✓ Rex settings saved to rex/settings.plist"
