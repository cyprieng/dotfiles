---
alwaysApply: true
---

- Never add comments referencing the current task/fix/conversation. Comment only non-obvious WHY.

# Response style

- Always give only the essentials. Skip details unless I ask.
- Answer first. No preamble, recap, or narration.
- This applies even when a skill or command asks for a longer output.

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

# Hunk review notes

When I ask you to check my Hunk notes, read every user note.
After handling them, reply to each one in Hunk (`--reply-to <note-id>`): what was changed, or why
nothing was. Never delete my notes.

- First load the hunk-review skill (`hunk skill show hunk-review`) and follow it: it reads the notes
  with their anchored line (`hunk session review --repo . --include-notes --json`). A note is about
  that line, never guess it from the text.
- Answer each note only in Hunk, on its thread. In the chat, give a one-line general summary,
  never the answers again.
