---
name: debug-github-actions
description: Debug failing GitHub Actions runs — reads logs, applies fixes, commits, pushes, and monitors until all jobs pass. Use when a GitHub Actions workflow is failing.
argument-hint: "[repo owner/name — defaults to current repo]"
disable-model-invocation: true
context: fork
agent: general-purpose
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# Debug GitHub Actions

Autonomously debug failing GitHub Actions runs until they pass.

## Setup

Detect the repo from the argument or fall back to the git remote:

```bash
# If $ARGUMENTS is provided, use it. Otherwise detect from git remote.
REPO="${ARGUMENTS:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
```

## Loop

Repeat the following until all jobs in the most recent run pass, or until you have
attempted 5 fix cycles with no progress (at which point stop and explain what's stuck).

### Step 1 — Find the most recent failing run

```bash
gh run list --repo "$REPO" --limit 5
```

Pick the most recent run with status `failure`. Note its run ID.

### Step 2 — Get the full error logs

```bash
gh run view <run-id> --repo "$REPO" --log-failed
```

Read the logs carefully. Identify:
- Which job failed
- Which step failed
- The exact error message
- The root cause (not just the symptom)

### Step 3 — Read the relevant files

Before making any change, read the file(s) that caused the error. Use Read, Glob, or
Grep to find and understand the current state of the code. Do not guess at fixes —
always read first.

### Step 4 — Apply the fix

Edit the file(s) to fix the root cause. Keep changes minimal and targeted.
Do not refactor surrounding code.

### Step 5 — Commit and push to main

```bash
git add <specific files only — never git add .>
git commit -m "<concise description of what was fixed and why>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push origin main
```

### Step 6 — Wait for the new run

```bash
# Wait up to 3 minutes for a new run to appear, then watch it
gh run list --repo "$REPO" --limit 3
gh run watch <new-run-id> --repo "$REPO" --exit-status
```

If the run passes, stop and report success with a summary of all fixes made.
If the run fails again, go back to Step 1 with the new run ID.

## Rules

- Always read files before editing — never make blind changes
- Fix root causes, not symptoms
- One focused commit per fix cycle — do not batch unrelated changes
- Never force push, never amend published commits
- Never commit secrets, `.env` files, or credentials
- If the same error repeats after 2 fix attempts, stop and explain why it cannot
  be automatically resolved (e.g. missing secret, external service issue, needs
  manual intervention)
- If a fix requires a secret to be added in GitHub, stop and tell the user exactly
  which secret to add and where

## Output

When done, report:
1. What was failing and why
2. Every fix applied (file changed, what changed, why)
3. Final run status (pass or still failing with reason)

$ARGUMENTS
