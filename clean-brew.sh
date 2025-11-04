#!/bin/bash

# Path to your Brewfiles
BREWFILE="Brewfile"
BREWFILE_EXTRA="Brewfile-extra"

echo "Loading installed packages..."
# Get all explicitly installed formulae (leaves)
installed_formulae=$(brew leaves)

# Get all installed casks
installed_casks=$(brew list --cask)

echo "Parsing Brewfiles..."
# Concatenate both Brewfiles (if Brewfile-extra exists)
if [ -f "$BREWFILE_EXTRA" ]; then
    combined_brewfile=$(cat "$BREWFILE" "$BREWFILE_EXTRA")
    echo "Found both Brewfile and Brewfile-extra"
else
    combined_brewfile=$(cat "$BREWFILE")
    echo "Found only Brewfile"
fi

# Extract formulae from combined Brewfiles (handle both simple names and tap/formula format, strip args)
brewfile_formulae=$(echo "$combined_brewfile" | grep '^brew ' | sed 's/brew ["'\'']\([^"'\'']*\)["'\''].*/\1/' | awk -F',' '{print $1}' | tr -d '"' | tr -d "'" | sed 's/^brew //' | tr '[:upper:]' '[:lower:]')

# Extract casks from combined Brewfiles (handle both simple names and tap/cask format, strip args)
brewfile_casks=$(echo "$combined_brewfile" | grep '^cask ' | sed 's/cask ["'\'']\([^"'\'']*\)["'\''].*/\1/' | awk -F',' '{print $1}' | tr -d '"' | tr -d "'" | sed 's/^cask //' | tr '[:upper:]' '[:lower:]')

# Combine all brewfile packages (lowercase)
all_brewfile_packages="$brewfile_formulae"$'\n'"$brewfile_casks"

# Function to check if a package is in the Brewfile
is_in_brewfile() {
    local package=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    local package_name_only=$(echo "$package" | sed 's/.*\///')

    # Check full package name or just the name after the last slash
    echo "$all_brewfile_packages" | grep -qiE "^${package}$|/${package_name_only}$|^${package_name_only}$"
}

# Collect packages not in Brewfile
packages_to_remove=()

echo "Checking formulae..."
while IFS= read -r formula; do
    [ -z "$formula" ] && continue
    if ! is_in_brewfile "$formula"; then
        packages_to_remove+=("formula:$formula")
    fi
done <<<"$installed_formulae"

echo "Checking casks..."
while IFS= read -r cask; do
    [ -z "$cask" ] && continue
    if ! is_in_brewfile "$cask"; then
        packages_to_remove+=("cask:$cask")
    fi
done <<<"$installed_casks"

# Check if there are packages to remove
if [ ${#packages_to_remove[@]} -eq 0 ]; then
    echo "No packages to remove. Everything matches your Brewfile!"
    exit 0
fi

# Use fzf to select packages to uninstall (multi-select with Tab)
echo "Select packages to uninstall (use Tab to select multiple, Enter to confirm):"
selected=$(printf '%s\n' "${packages_to_remove[@]}" | fzf --multi --height=40% --border --header="Tab: select/deselect | Enter: confirm")

# Check if user selected anything
if [ -z "$selected" ]; then
    echo "No packages selected. Exiting."
    exit 0
fi

# Uninstall selected packages
echo ""
echo "Uninstalling selected packages..."
while IFS= read -r item; do
    type=$(echo "$item" | cut -d: -f1)
    package=$(echo "$item" | cut -d: -f2)

    if [ "$type" = "formula" ]; then
        echo "Uninstalling formula: $package"
        brew uninstall "$package"
    elif [ "$type" = "cask" ]; then
        echo "Uninstalling cask: $package"
        brew uninstall --cask "$package"
    fi
done <<<"$selected"

echo ""
echo "Done!"
