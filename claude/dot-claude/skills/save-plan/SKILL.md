---
name: save-plan
description: >-
  Save the plan currently being discussed in the conversation to a markdown
  file in /tmp and open it in Neovim via nvr. Use when the user wants to
  persist the current plan/analysis/steps to a file they can edit, or mentions
  "save plan", "écris le plan", "dump plan to nvim".
---

Write the plan currently being discussed in the conversation to a markdown
file in `/tmp/`, then open it in the user's running Neovim instance via `nvr`.

## Steps

1. **Extract the plan content** from the current conversation. This is whatever
   plan, analysis, steps, or design you've been producing or refining with the
   user. Format as clean Markdown (headings, bullets, code blocks).

2. **Generate a short kebab-case description** (2-5 words) that summarises the
   plan's topic. Examples: `ubuntu-migration`, `auth-refactor`, `statusline-icons`.

3. **Build the filename** as `/tmp/plan-<description>-<YYYYMMDD-HHMM>.md`. Use
   `date +%Y%m%d-%H%M` for the timestamp.

4. **Write the file** with the Write tool — full Markdown content, no preamble
   ("Here is the plan…") and no closing summary.

5. **Open in Neovim** with:
   ```
   nvr --remote <file>
   ```
   This opens the file in a new buffer in the current tab. Do NOT use
   `--remote-tab`.

6. **Report** the absolute path back to the user in one short line. Nothing else.

## Constraints

- Do NOT ask the user to confirm the filename or description — pick sensible
  values and proceed.
- Do NOT create the file outside `/tmp/`.
- Do NOT modify Neovim configuration or run any command other than `nvr --remote`.
- If `nvr` fails (e.g. no Neovim server running), report the file path and the
  error verbatim so the user can open it manually.
