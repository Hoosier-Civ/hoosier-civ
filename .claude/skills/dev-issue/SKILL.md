---
name: dev-issue
description: Create a correctly-named branch for a GitHub issue, then implement all the work described in that issue.
argument-hint: "<issue-number>"
agent: general-purpose
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Dev Issue

Given an issue number, create the correct branch and implement the work.

## Instructions

The argument is an issue number, e.g. `3`.

---

### Step 1 — Fetch the issue

```bash
gh issue view {number} --repo $(gh repo view --json nameWithOwner -q .nameWithOwner) --json number,title,body,labels,issueType
```

Extract:
- **title** — used to generate the branch slug
- **body** — contains the Work and Acceptance Criteria sections to implement
- **issueType.name** — `"Feature"` → `feat/`, `"Bug"` → `fix/`
- **labels** — fall back to label names if issueType is absent: a `bug` label → `fix/`, otherwise `feat/`

---

### Step 2 — Derive the branch name

**Prefix rules** (in priority order):
1. `issueType.name == "Bug"` → `fix`
2. Any label named `bug` → `fix`
3. Anything else → `feat`

**Slug rules:**
- Strip any conventional-commit prefix from the title (`feat:`, `fix:`, `chore:`, `docs:` followed by a space)
- Lowercase the remainder
- Replace any run of non-alphanumeric characters with a single hyphen
- Trim leading/trailing hyphens
- Truncate to 40 characters, trimming at a word boundary (don't cut mid-word)

**Final branch name:** `{prefix}/issue-{number}-{slug}`

Examples:
- Issue #3 "feat: Create lookup-district Edge Function" → `feat/issue-3-create-lookup-district-edge-function`
- Issue #9 "fix: Router redirect loop on cold launch" → `fix/issue-9-router-redirect-loop-on-cold-launch`

---

### Step 3 — Check current branch state

```bash
git status --short
git branch --show-current
```

- If already on the correct branch, skip branch creation and note it.
- If there are uncommitted changes, stop and tell the user to stash or commit them first.
- Otherwise, create and switch to the new branch:

```bash
git checkout -b {branch-name}
```

---

### Step 4 — Understand the work

Parse the issue body. Issues created by `/task-breakdown` follow this structure:

```
## Context
Parent: #N
Depends on: #N (if applicable)

## Work
- bullet list of deliverables

## Acceptance Criteria
- [ ] checkbox items
```

Read any files mentioned in the Work section before writing code. Use Glob and Grep to locate relevant existing files. Understand the patterns in place before adding new code.

Also check `docs/features/` for the parent feature plan — it provides broader context for decisions.

---

### Step 5 — Implement the work

Complete every item in the **Work** section and satisfy every checkbox in the **Acceptance Criteria**.

Follow HoosierCiv conventions:
- **State management:** flutter_bloc Cubit pattern. No business logic in widgets.
- **Data layer:** `lib/data/models/` for models, `lib/data/repositories/` for repositories.
- **Supabase migrations:** `supabase/migrations/` with timestamp prefix `YYYYMMDDHHMMSS_`.
- **Edge Functions:** `supabase/functions/{name}/index.ts` using Deno.
- **Tests:** `test/` mirroring `lib/` structure. Write unit tests for any new models, cubits, or pure logic.
- **No files without a reason:** prefer editing existing files over creating new ones.
- After writing Dart code, run `flutter analyze` and fix any issues.
- After writing Dart code, run `dart format .`

---

### Step 6 — Report

When the work is complete, print a summary:

```
## Issue #{number} — {title}

Branch: {branch-name}

### Completed
- [x] Each work item ticked off

### Files changed
- path/to/file — what changed

### Next steps
- Any manual steps (e.g. run supabase db push, test on device)
- Suggested: open a PR with `gh pr create`
```

$ARGUMENTS
