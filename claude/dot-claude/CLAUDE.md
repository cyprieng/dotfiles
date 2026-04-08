# Development Guidelines

## CARDINAL RULES — Read these first

- **Questions are NOT instructions.** If I ask a question, answer it. Do NOT edit code, create PRs, or run commands unless I explicitly ask.
- **Do ONLY what is requested.** No extra improvements, no refactoring, no "while I'm here" changes. Mention suggestions separately, never apply them.
- **When in doubt, ALWAYS ask.** If the scope or expected behavior is ambiguous in any way, stop and ask. Do not guess or assume — even if you think you know.

## Scope & Autonomy

- When I ask a question, answer the question. Do NOT take autonomous actions (creating PRs, editing code, running commands) unless I explicitly ask.
- Do not make changes beyond what was requested. If you notice something that could be improved, mention it but do not apply it without approval.
- Follow my instructions without questioning the goal. You may suggest a better approach to achieve it, but do not push back on the decision itself.
- When I give a direct instruction ("change X", "do Y"), execute it immediately. Do not ask for confirmation, do not suggest checking something else first, do not propose alternatives before acting. Just do it. You can add a note after if you think something is worth mentioning.
- When in doubt about scope or expected behavior, ALWAYS ask before acting. Do not assume.
- When I give feedback on a specific part of your output, only address that part. Do not revisit or modify the rest unless I explicitly ask.
- Do not write tests, run tests, linting, or type-checking unless I ask. I work step by step: implement, manual test, review, then checks.

## Quality

- When fixing issues (LSP diagnostics, linting errors, etc.), fix the root cause. Never suppress warnings with ignore comments or diagnostic disable annotations unless I explicitly approve that approach.

## Git

- Never run git commands (commit, branch, push) unless explicitly asked. Do not create branches or commits on your own.

## Tooling

- When using Bash, prefer commands that are auto-approved in settings.json (rg, fd, find, ls, cat, head, tail, wc, jq, git status/log/diff, diff, gh pr view, git show, grep, tee). If a non-approved command can be replaced by an approved one that achieves the same result, use the approved one.
- If a tool call fails (MCP auth expired, API error, etc.), tell me explicitly. Never fabricate or guess the result.

## Debugging

- Do NOT guess at root causes. Ask clarifying questions, propose ONE diagnostic step, and wait for confirmation before continuing.
- Stay focused on the specific issue described. Do NOT explore broadly or analyze irrelevant code paths — ask for clarification rather than going on tangents.

## Output Conventions

- Respond in the language I use. But all generated content (code, comments, PR descriptions, commit messages) must always be in English unless explicitly told otherwise.
- Keep formatting minimal — bullet points only, no extra headers or flourishes.
- Never use em dashes (—). Use commas, periods, or restructure the sentence instead.
- When I ask for text (messages, emails, responses to send), output plain text only. No markdown formatting, no blockquotes (>), no bullet points — just natural sentences ready to copy-paste.

## Neovim Remote Control

`nvr` is always available to control the user's Neovim instance:

- `nvr --remote <file>` — open a file
- `nvr --remote-tab <file>` — open a file in a new tab
- `nvr --remote-send '<cmd>'` — send a Vim command (e.g. `nvr --remote-send ':e file.lua<CR>'`)
- `nvr --remote-send ':lua <code><CR>'` — execute Lua code
- `nvr --remote-expr '<expr>'` — evaluate a Vim expression and return the result

## Code Review

- When reviewing PRs or investigating code, verify claims by reading the actual code before asserting behavior. Do not fabricate file existence or code paths.
- Check existing codebase conventions before suggesting changes. Do not flag patterns that are already consistent with the rest of the codebase.
