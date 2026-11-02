#!/bin/bash
# Remove the gh-notifier launchd agent, its installed script and its state.
set -euo pipefail

label=local.gh-notifier
launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$label.plist" "$HOME/.local/bin/gh-notifier"
rm -rf "$HOME/.local/state/gh-notifier"
echo "gh-notifier uninstalled."
