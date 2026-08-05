#!/usr/bin/env bash
# Deprecated: install.sh is now multi-distribution (apt / dnf / yum / pacman).
# Kept only so old bookmarks keep working.
echo "install_multiOS.sh has been merged into install.sh — running it instead."
exec "$(dirname -- "${BASH_SOURCE[0]}")/install.sh" "$@"
