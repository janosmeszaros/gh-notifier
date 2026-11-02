#!/bin/bash
# Install gh-notifier as a launchd agent that runs every 2 minutes.
# Safe to re-run: re-running also picks up a changed gh-notifier script.
set -euo pipefail

label=local.gh-notifier
here=$(cd "$(dirname "$0")" && pwd)
bin="$HOME/.local/bin/gh-notifier"
plist="$HOME/Library/LaunchAgents/$label.plist"
state_dir="$HOME/.local/state/gh-notifier"
interval=120

command -v gh >/dev/null || { echo "gh not found. Install it with: brew install gh" >&2; exit 1; }
gh api 'notifications?per_page=1' >/dev/null 2>&1 \
  || { echo "gh can't read your GitHub notifications. Run: gh auth login" >&2; exit 1; }
if ! command -v terminal-notifier >/dev/null; then
  command -v brew >/dev/null || { echo "terminal-notifier not found and Homebrew isn't installed." >&2; exit 1; }
  brew install terminal-notifier
fi

# launchd starts jobs with a minimal PATH, so bake in where gh and terminal-notifier live.
path="$(dirname "$(command -v gh)"):$(dirname "$(command -v terminal-notifier)"):/usr/bin:/bin"

# Copy instead of pointing launchd at the checkout: a checkout under ~/Documents or
# ~/Desktop is privacy-protected and launchd's bash couldn't read it.
mkdir -p "$(dirname "$bin")" "$state_dir" "$(dirname "$plist")"
install -m 755 "$here/gh-notifier" "$bin"

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

# Launch the app bundle through LaunchServices (`open`) once. Run straight from the shell,
# terminal-notifier never gets registered with macOS: it can't ask for notification
# permission and doesn't show up in System Settings → Notifications.
app="$(dirname "$(dirname "$(readlink -f "$(command -v terminal-notifier)")")")/terminal-notifier.app"
open -W -a "$app" --args -title "gh-notifier" -message "Installed. Click to open your GitHub notifications." \
  -open "https://github.com/notifications" -group gh-notifier-install \
  || echo "Couldn't launch $app. Check System Settings → Notifications → terminal-notifier." >&2

echo "gh-notifier installed. It checks every $((interval / 60)) minutes. Errors go to $state_dir/error.log"
