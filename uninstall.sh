#!/bin/bash
# Remove the gh-notifier launchd agent, its installed script and its state.
set -euo pipefail

label=local.gh-notifier
launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
app="$HOME/.local/share/gh-notifier/gh-notifier.app"
[[ -d "$app" ]] && /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$app"
rm -f "$HOME/Library/LaunchAgents/$label.plist" "$HOME/.local/bin/gh-notifier"
rm -rf "$HOME/.local/state/gh-notifier" "$HOME/.local/share/gh-notifier"
echo "gh-notifier uninstalled."
