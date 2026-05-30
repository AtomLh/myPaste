#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BIN="$PROJECT_DIR/build/myPaste.app/Contents/MacOS/myPaste"
PLIST="$HOME/Library/LaunchAgents/local.myPaste.plist"
LABEL="local.myPaste"

if [ ! -x "$APP_BIN" ]; then
    echo "Error: $APP_BIN not found."
    echo "Run scripts/make_app_bundle.sh first."
    exit 1
fi

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_BIN</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardOutPath</key>
    <string>/tmp/myPaste.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/myPaste.stderr.log</string>
</dict>
</plist>
EOF

# unload any old version
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

# load fresh
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "Installed: $PLIST"
echo "myPaste will auto-launch at every user login."
echo ""
echo "To uninstall: scripts/uninstall_launchagent.sh"
