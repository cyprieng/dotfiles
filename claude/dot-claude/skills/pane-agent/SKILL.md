---
name: pane-agent
description: >-
  Interview the user about a task, write a concise brief, then open a new
  tmux or Rex pane side-by-side and launch claude or cursor-agent in it with
  the brief as the initial prompt. Use when the user wants to delegate a task
  to a new agent instance in a new pane, or mentions "écris un brief et lance",
  "ouvre un pane avec ce brief", "lance claude/cursor dans un nouveau pane".
---

Turn a task idea into a brief, then hand it off to a fresh `claude` or
`cursor-agent` instance running in a new pane next to the current one, in
whichever multiplexer the current session runs in (tmux or Rex).

## Steps

1. **Ask only if genuinely unclear.** The user will be sitting in the new
   pane interacting with the agent live, so this isn't a spec to get
   right up front — just enough to kick off with a sensible starting point.
   If the request is already clear, skip straight to writing the brief. Only
   ask when something is truly ambiguous (e.g. which of two repos/files, or
   the request is too vague to act on at all) — one or two quick questions
   at most, not a scoping interview.

2. **Write the brief.** Once the need is clear, write a short, self-contained
   brief (plain text, a few sentences to a short paragraph — this becomes a
   CLI argument, not a document). It must give a fresh agent with zero
   context enough to start working: the goal, relevant paths/files if known,
   and any constraints gathered in step 1. No preamble, no meta-commentary.

3. **Save the brief** to `/tmp/brief-<slug>-<YYYYMMDD-HHMM>.md` (slug =
   2-4 kebab-case words summarizing the task; timestamp via
   `date +%Y%m%d-%H%M`).

4. **Pick the tool.** Default to `claude`. Use `cursor-agent` only if the
   user explicitly asked for cursor.

5. **Open a side-by-side shell pane and type the launch command into it,**
   with the brief as the tool's initial prompt argument. The pane runs a
   regular shell, so quitting the agent drops back to a prompt instead of
   closing the pane, and the command stays in the shell history. Pick the
   multiplexer from the environment:

   - **`$TMUX` is set** (checked first: a tmux started from Rex inherits the
     Rex variables):

     ```bash
     pane=$(tmux split-window -h -c "$PWD" -P -F '#{pane_id}')
     tmux send-keys -t "$pane" -l "claude \"\$(cat '<brief-file>')\""
     tmux send-keys -t "$pane" Enter
     ```

   - **Otherwise, `$REX_SESSION` is set:**

     ```bash
     block=$(rex split -s "$REX_SESSION" -b "$REX_BLOCK" --split=right -c "$PWD" --json | jq -r '.block_ids[0]')
     rex send -s "$REX_SESSION" -b "$block" "claude \"\$(cat '<brief-file>')\""
     rex send-key -s "$REX_SESSION" -b "$block" enter
     ```

   - **Neither is set:** don't open anything; report the brief file path so
     the user can launch it manually.

   Swap `claude` for `cursor-agent` if that tool was picked. Keep the
   working directory option (`-c "$PWD"`) so the new pane starts in the
   current working directory. The command is typed right after the split,
   while the shell is still starting; the terminal buffers it until the
   prompt reads it.

6. **Report** the brief file path and which tool was launched, in one short
   line. Nothing else.

## Constraints

- Do NOT skip the clarifying-questions step, even under time pressure — a
  vague brief handed to a fresh agent wastes more time than the questions
  cost.
- Do NOT write the brief file anywhere outside `/tmp/`.
- Do NOT run any tmux or rex command other than the split and the keys sent
  to the new pane above (no closing/killing panes, no resizing, no touching
  other windows).
- If the split fails, report the brief file path and the error verbatim so
  the user can launch it manually.
