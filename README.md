# gh-notifier

Short macOS desktop notifications for GitHub pull request activity: review requests,
mentions, comments and activity on your own PRs. It's a lighter alternative to GitHub's
email notifications. Click a notification to open the PR in your browser.

```
octo-org/octo-repo
review requested
fix: retry the upload when the connection drops
```

## Requirements

- macOS
- [GitHub CLI](https://cli.github.com/), logged in (`gh auth login`)
- [terminal-notifier](https://github.com/julienXX/terminal-notifier). `install.sh` installs it
  with Homebrew if it's missing.

## Install

```sh
./install.sh
```

You get a test notification right away. If macOS asks, allow notifications for
**terminal-notifier**. If nothing appears, turn them on under
System Settings → Notifications → terminal-notifier.

To update after changing or pulling a new `gh-notifier`, run `./install.sh` again.

## Uninstall

```sh
./uninstall.sh
```

## How it works

A launchd agent runs `gh-notifier` every 2 minutes. Each run:

1. Reads your unread GitHub notifications with `gh api notifications` and keeps only the pull
   request ones. CI runs and issues are left out.
2. Shows a notification for each PR that is new or has new activity since the last run.
   A newer notification for the same PR replaces the older one.
3. Like GitHub's PR inbox page, it only counts open PRs. Activity on merged or closed PRs,
   including the merge itself, doesn't produce a notification.

On the first run it only records what's already unread, so you don't get flooded.
Once you read an item on GitHub, it no longer counts. New activity on that PR makes it
unread again, and you get a new notification.

GitHub decides which events create notifications. Change that under
[Settings → Notifications](https://github.com/settings/notifications) and by watching or
unwatching repos.

## Files

| Path | What |
| --- | --- |
| `~/.local/bin/gh-notifier` | installed copy of the script |
| `~/Library/LaunchAgents/local.gh-notifier.plist` | launchd agent |
| `~/.local/state/gh-notifier/seen` | items seen on the last run |
| `~/.local/state/gh-notifier/error.log` | errors |

## Troubleshooting

- Run it by hand to see errors: `~/.local/bin/gh-notifier`
- Check the agent: `launchctl print gui/$(id -u)/local.gh-notifier | grep -E 'state|last exit'`
- To change the 2-minute interval, edit `interval` in `install.sh` and re-run it.

## License

MIT. See [LICENSE](LICENSE).
