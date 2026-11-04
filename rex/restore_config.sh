#!/bin/bash

set -eo pipefail

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

while read -r key; do
  # plutil key paths split on dots
  value=$(plutil -extract "${key//./\\.}" xml1 -o - "$BASEDIR/settings.plist" 2>/dev/null) || continue
  defaults write com.superlogical.rex "$key" "$value"
done < "$BASEDIR/settings.keys"

echo "✓ Rex settings restored"
