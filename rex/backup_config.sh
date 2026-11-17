#!/bin/bash

set -eo pipefail

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

# The preferences domain also holds app state (window frames, last session, sync servers...).
# Everything is saved except these keys, so a new setting shows up without editing a list.
SKIP=(
	"NS"
	"Onboarding."
	"RexSync."
	"SUHasLaunchedBefore"
	"SULastCheckTime"
	"SUUpdateGroupIdentifier"
	"Workspace.lastFocusedSession"
	"Workspace.programActivitySeen"
	"Workspace.sidebarWidth"
	"rex.local-server.cached-route"
	"rex.sync.hosts-migrated"
)

PREFS=$(mktemp)
trap 'rm -f "$PREFS"' EXIT
defaults export com.superlogical.rex "$PREFS"
plutil -convert xml1 "$PREFS"

OUT="$BASEDIR/settings.plist"
plutil -create xml1 "$OUT"

# /plist/dict/key is a key of the root dictionary, not a key nested inside a value
xmllint --nonet --xpath '/plist/dict/key/text()' "$PREFS" | while read -r key; do
	for prefix in "${SKIP[@]}"; do
		[[ $key == "$prefix"* ]] && continue 2
	done
	# plutil key paths split on dots
	path=${key//./\\.}
	value=$(plutil -extract "$path" xml1 -o - "$PREFS" 2>/dev/null) || continue
	plutil -insert "$path" -xml "$value" "$OUT"
done

echo "✓ Rex settings saved to rex/settings.plist"
