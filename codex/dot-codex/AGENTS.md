# Neovim remote control

`nvr` is a zsh function that targets the user's Neovim instance in the same
tmux or Rex window. Use it to open files when requested:

- `nvr --remote <file>` — open a file in the current tab.
- `nvr --remote-tab <file>` — open a file in a new tab when requested.
- `nvr --remote-send '<keys>'` — send keys or a Vim command.
- `nvr --remote-expr '<expr>'` — evaluate a Vim expression.

If `nvr` is unavailable in a non-interactive shell, run it through
`zsh -lic 'nvr --remote <file>'`. If no Neovim server is running, report the
error and the file path.
