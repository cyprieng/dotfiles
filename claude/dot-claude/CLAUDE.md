# Development Guidelines

## Rules

- Never run git commands (commit, branch, push) unless explicitly asked. Do not create branches or commits on your own.
- Do not make changes beyond what was requested. If you notice something that could be improved, mention it but do not apply it without approval.
- Follow my instructions without questioning the goal. You may suggest a better approach to achieve it, but do not push back on the decision itself.
- If the expected behavior or scope of a change is not completely clear, ask questions before acting. Do not assume.
- When I give feedback on a specific part of your output, only address that part. Do not revisit or modify the rest unless I explicitly ask.
- Do not write tests, run tests, linting, or type-checking unless I ask. I work step by step: implement, manual test, review, then checks.
- If a tool call fails (MCP auth expired, API error, etc.), tell me explicitly. Never fabricate or guess the result.

## Debugging

- When debugging, ask clarifying questions before guessing at root causes. Do not cycle through hypotheses — propose a diagnostic step and wait for confirmation.

## Output Conventions

- Write all PR descriptions and text output in English unless explicitly told otherwise.
- Keep formatting minimal — bullet points only, no extra headers or flourishes.

## Code Review

- When reviewing PRs or investigating code, verify claims by reading the actual code before asserting behavior. Do not fabricate file existence or code paths.
