Generate a commit message, branch name, and PR description for the current staged/unstaged changes.

- Read the git diff (staged + unstaged) against main
- Output exactly 3 sections, in this order:

**Branch name**
- Format: `type/short-description` (e.g. `feat/add-user-auth`, `fix/null-pointer-crash`)
- Lowercase, kebab-case, max 50 chars

**Commit message**
- Conventional commit format: `type(scope): description`
- Keep under 72 chars
- Focus on the "why", not the "what"

**PR description**
- Concise bullet points, no headers
- Write in English only

- Do NOT create commits, branches, or push anything
