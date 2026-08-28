---
name: pane-agent
description: >-
  Interview the user about a task, write a concise brief, then open a new
  tmux pane side-by-side and launch claude or cursor-agent in it with the
  brief as the initial prompt. Use when the user wants to delegate a task to
  a new agent instance in a new pane, or mentions "écris un brief et lance",
  "ouvre un pane avec ce brief", "lance claude/cursor dans un nouveau pane".
---

Turn a task idea into a brief, then hand it off to a fresh `claude` or
`cursor-agent` instance running in a new tmux pane next to the current one.

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

5. **Open a side-by-side tmux pane and launch the tool with the brief as its
   initial prompt argument:**

   ```bash
   tmux split-window -h -c "$PWD" "claude \"\$(cat '<brief-file>')\""
   ```

   Swap `claude` for `cursor-agent` if that tool was picked. Keep `-c "$PWD"`
   so the new pane starts in the current working directory.

6. **Report** the brief file path and which tool was launched, in one short
   line. Nothing else.

## Constraints

- Do NOT skip the clarifying-questions step, even under time pressure — a
  vague brief handed to a fresh agent wastes more time than the questions
  cost.
- Do NOT write the brief file anywhere outside `/tmp/`.
- Do NOT run any tmux command other than the single `split-window` above
  (no closing/killing panes, no resizing, no touching other windows).
- If `tmux split-window` fails (e.g. not inside a tmux session), report the
  brief file path and the error verbatim so the user can launch it manually.
