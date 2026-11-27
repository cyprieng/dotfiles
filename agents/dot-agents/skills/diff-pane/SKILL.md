---
name: diff-pane
description: >-
  Open the Hunk diff of the work under review in a new tmux or Rex pane next to
  the current one: the right repo or worktree, compared against the right base
  branch. Use when the user wants to see or review the diff in Hunk, or mentions
  "ouvre le diff", "ouvre hunk", "montre-moi le diff", "diff pane".
---

Open `hunk` on the changes the user wants to review, in a shell pane split to
the right of the current one. The pane runs the user's interactive zsh, so the
`hd` / `hD` functions from their `.zshrc` are available there.

## Steps

1. **Pick the directory**: the git root of the repo or worktree holding the
   work (`git -C <dir> rev-parse --show-toplevel`). When the work happened in a
   worktree, use that worktree, not the main checkout.

2. **Pick the command**, from that directory. First decide what is under
   review: only the work not yet committed, or the whole branch.
   - `hd`, the uncommitted changes, when they touch a branch already committed
     or pushed (a fix or an addition to an existing PR): the review is about
     that change only, whatever the branch. Also on the default branch
     (`master` or `main`).
   - `hD`, the whole branch from its parent, only when the branch itself is the
     work under review: a new branch, or a PR being reviewed as a whole.
   - In doubt: uncommitted changes on a branch that already has a PR mean `hd`.

   For `hD`, find the parent branch:
     - the branch this one was created from, if known from the conversation;
     - else the PR base: `gh pr view --json baseRefName -q .baseRefName`;
     - else the default branch.
   - Parent is the default branch: `hD`. Any other parent: `hD <parent>`, with
     the branch name as it exists on `origin`.

   `hD` fetches the parent and diffs from its merge-base, uncommitted changes
   included, so only what the branch adds shows up.

3. **Open the pane and run the command in it.** Pick the multiplexer from the
   environment:

   - **`$TMUX` is set** (checked first: a tmux started from Rex inherits the
     Rex variables):

     ```bash
     pane=$(tmux split-window -h -c "<dir>" -P -F '#{pane_id}')
     tmux send-keys -t "$pane" -l "<command>"
     tmux send-keys -t "$pane" Enter
     ```

   - **Otherwise, `$REX_BLOCK` is set:**

     ```bash
     block=$(rex split -s "$REX_BLOCK" -b "$REX_BLOCK" --split=right -c "<dir>" --json | jq -r '.block_ids[0]')
     rex send -s "$REX_BLOCK" -b "$block" "<command>"
     rex send-key -s "$REX_BLOCK" -b "$block" enter
     ```

   - **Neither is set:** don't open anything; give the user the `cd <dir> && <command>`
     line to run.

4. **Report** in one line: the directory and the command.

## Constraints

- Always open a new pane when invoked, even if a Hunk session already runs on
  that directory.

- Never touch the repo: no checkout, pull, commit or stash. `hD` only fetches.
- Do NOT run any tmux or rex command other than the split and the keys sent to
  the new pane (no closing, killing or resizing panes).
- If the split fails, report the error verbatim with the line to run manually.
