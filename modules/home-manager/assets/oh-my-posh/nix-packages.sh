#!/bin/sh
# Extract nix package names from PATH
# This script parses PATH to find nix store entries and extracts package names

# Split PATH by : and extract nix packages
IFS=:
packages=""
count=0

for path_entry in $PATH; do
    # Only process /nix/store/ paths that aren't profile paths
    case "$path_entry" in
        /nix/store/*)
            case "$path_entry" in
                */profiles/*) continue ;;
            esac

            # Extract package name from path
            # Format: /nix/store/hash-name-version/bin -> name
            pkg_full="${path_entry#/nix/store/}"
            pkg_full="${pkg_full#*-}"  # Remove hash
            pkg_full="${pkg_full%%/*}" # Remove /bin or other suffix

            # Remove -man, -doc, -dev suffixes
            case "$pkg_full" in
                *-man) pkg_full="${pkg_full%-man}" ;;
                *-doc) pkg_full="${pkg_full%-doc}" ;;
                *-dev) pkg_full="${pkg_full%-dev}" ;;
            esac

            # Extract just name without version (remove -X.Y.Z pattern)
            pkg_name="$pkg_full"
            # Try to remove version pattern: -number.anything
            case "$pkg_name" in
                *-[0-9]*)
                    # Keep removing from the last dash if it starts with a number
                    temp="${pkg_name%-[0-9]*}"
                    while [ "$temp" != "$pkg_name" ]; do
                        pkg_name="$temp"
                        temp="${pkg_name%-[0-9]*}"
                    done
                    ;;
            esac

            # Check if already added (simple substring check)
            case ",$packages," in
                *,"$pkg_name",*) continue ;;
            esac

            # Add to list
            if [ -z "$packages" ]; then
                packages="$pkg_name"
            else
                packages="$packages,$pkg_name"
            fi

            count=$((count + 1))

            # Limit to 3 packages
            if [ "$count" -ge 3 ]; then
                packages="$packages,..."
                break
            fi
            ;;
    esac
done

# Output result only if we have packages or are in a nix-shell
if [ -n "$packages" ]; then
    echo "$packages"
elif [ -n "$pname" ]; then
    echo "$pname"
elif [ -n "$name" ]; then
    echo "$name"
elif [ -n "$IN_NIX_SHELL" ]; then
    # We're in a nix-shell but couldn't determine packages
    echo "shell"
fi
# Otherwise output nothing (not in a nix environment)
