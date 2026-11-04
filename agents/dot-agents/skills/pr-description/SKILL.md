---
name: pr-description
description: Generate a concise English PR description for the current branch and copy it to the clipboard.
---

Generate a PR description for the current branch.

- Read the git diff against main
- Write in English only
- Use concise text, no headers
- Copy result to clipboard with `pbcopy`
- Do NOT create commits or branches
