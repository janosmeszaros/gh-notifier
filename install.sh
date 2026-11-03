#!/bin/bash
# Install gh-notifier as a launchd agent that runs every 2 minutes.
# Safe to re-run: re-running also picks up a changed gh-notifier script.
set -euo pipefail

label=local.gh-notifier
here=$(cd "$(dirname "$0")" && pwd)
bin="$HOME/.local/bin/gh-notifier"
plist="$HOME/Library/LaunchAgents/$label.plist"
state_dir="$HOME/.local/state/gh-notifier"
app="$HOME/.local/share/gh-notifier/gh-notifier.app"
interval=120

command -v gh >/dev/null || { echo "gh not found. Install it with: brew install gh" >&2; exit 1; }
gh api 'notifications?per_page=1' >/dev/null 2>&1 \
  || { echo "gh can't read your GitHub notifications. Run: gh auth login" >&2; exit 1; }
if ! command -v terminal-notifier >/dev/null; then
  command -v brew >/dev/null || { echo "terminal-notifier not found and Homebrew isn't installed." >&2; exit 1; }
  brew install terminal-notifier
fi

# launchd starts jobs with a minimal PATH, so bake in where gh lives.
path="$(dirname "$(command -v gh)"):/usr/bin:/bin"

# Copy instead of pointing launchd at the checkout: a checkout under ~/Documents or
# ~/Desktop is privacy-protected and launchd's bash couldn't read it.
mkdir -p "$(dirname "$bin")" "$state_dir" "$(dirname "$plist")" "$(dirname "$app")"
install -m 755 "$here/gh-notifier" "$bin"

# macOS always takes a notification's icon from the app that sends it. So notifications
# come from a copy of terminal-notifier's app with GitHub's logo and its own bundle id.
# The logo is downloaded from GitHub rather than shipped with this repo.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/logo.png" 'https://github.com/github.png?size=512'
mkdir "$tmp/icon.iconset"
for s in 16 32 128 256 512; do
  sips -z $s $s "$tmp/logo.png" --out "$tmp/icon.iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s * 2)) $((s * 2)) "$tmp/logo.png" --out "$tmp/icon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
tn_app="$(dirname "$(dirname "$(readlink -f "$(command -v terminal-notifier)")")")/terminal-notifier.app"
rm -rf "$app"
cp -R "$tn_app" "$app"
chmod -R u+w "$app"
iconutil -c icns -o "$app/Contents/Resources/Terminal.icns" "$tmp/icon.iconset"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $label" -c "Set :CFBundleName gh-notifier" \
  "$app/Contents/Info.plist"
codesign --force --sign - "$app" 2>/dev/null

cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$bin</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$path</string>
  </dict>
  <key>StartInterval</key>
  <integer>$interval</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardErrorPath</key>
  <string>$state_dir/error.log</string>
</dict>
</plist>
EOF

domain="gui/$(id -u)"
launchctl bootout "$domain/$label" 2>/dev/null || true
launchctl bootstrap "$domain" "$plist"

# Launch the app through LaunchServices (`open`) once. Run straight from the shell, it
# never gets registered with macOS: it can't ask for notification permission and doesn't
# show up in System Settings → Notifications.
open -W -a "$app" --args -title "gh-notifier" -message "Installed. Click to open your GitHub notifications." \
  -open "https://github.com/notifications" -group gh-notifier-install \
  || echo "Couldn't launch $app. Check System Settings → Notifications → gh-notifier." >&2

echo "gh-notifier installed. It checks every $((interval / 60)) minutes. Errors go to $state_dir/error.log"
