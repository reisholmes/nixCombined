#!/bin/sh
# Extract nix package names from PATH for oh-my-posh prompt display
# Parses /nix/store paths to show up to 3 unique package names

IFS=:  # Split PATH on colons
packages=""
count=0

for path_entry in $PATH; do
    case "$path_entry" in
        /nix/store/*)
            # Skip system profiles and terminal emulators to avoid false positives
            case "$path_entry" in
                */profiles/*) continue ;;  # Skip nix profile paths
                *ghostty*) continue ;;     # Skip ghostty terminal paths
            esac

            # Parse /nix/store/hash-name-version/bin -> name
            pkg_full="${path_entry#/nix/store/}"  # Remove /nix/store/ prefix
            pkg_full="${pkg_full#*-}"              # Remove hash prefix
            pkg_full="${pkg_full%%/*}"             # Remove /bin suffix

            # Strip documentation/development suffixes
            case "$pkg_full" in
                *-man) pkg_full="${pkg_full%-man}" ;;
                *-doc) pkg_full="${pkg_full%-doc}" ;;
                *-dev) pkg_full="${pkg_full%-dev}" ;;
            esac

            # Remove version numbers (e.g., -1.2.3)
            pkg_name="$pkg_full"
            case "$pkg_name" in
                *-[0-9]*)
                    # Strip version suffixes iteratively
                    temp="${pkg_name%-[0-9]*}"
                    while [ "$temp" != "$pkg_name" ]; do
                        pkg_name="$temp"
                        temp="${pkg_name%-[0-9]*}"
                    done
                    ;;
            esac

            # Skip duplicates
            case ",$packages," in
                *,"$pkg_name",*) continue ;;
            esac

            # Append to comma-separated list
            if [ -z "$packages" ]; then
                packages="$pkg_name"
            else
                packages="$packages,$pkg_name"
            fi

            count=$((count + 1))

            # Cap at 3 packages for readability
            if [ "$count" -ge 3 ]; then
                packages="$packages,..."
                break
            fi
            ;;
    esac
done

# Output packages found in PATH, or fall back to nix-shell variables
if [ -n "$packages" ]; then
    echo "$packages"
elif [ -n "$pname" ]; then
    echo "$pname"  # nix-shell package name variable
elif [ -n "$name" ]; then
    echo "$name"   # nix-shell name variable
elif [ -n "$IN_NIX_SHELL" ]; then
    echo "shell"   # Generic nix-shell indicator
fi
# Output nothing if not in a nix environment
