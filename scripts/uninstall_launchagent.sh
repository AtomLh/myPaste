#!/usr/bin/env bash
set -euo pipefail

LABEL="local.myPaste"
PLIST="$HOME/Library/LaunchAgents/local.myPaste.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST"
killall myPaste 2>/dev/null || true

echo "Uninstalled $LABEL."
