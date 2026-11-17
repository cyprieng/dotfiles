#!/bin/bash

set -eo pipefail

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

# /plist/dict/key is a key of the root dictionary, not a key nested inside a value
xmllint --nonet --xpath '/plist/dict/key/text()' "$BASEDIR/settings.plist" | while read -r key; do
	# plutil key paths split on dots
	value=$(plutil -extract "${key//./\\.}" xml1 -o - "$BASEDIR/settings.plist" 2>/dev/null) || continue
	defaults write com.superlogical.rex "$key" "$value"
done

echo "✓ Rex settings restored"
