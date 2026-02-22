# Task Breakdown

Convert a planned feature into approved GitHub issues with proper hierarchy, types, and metadata.

## Instructions

The user will name a feature (e.g. "onboarding", "bill tracking").

**Before doing anything else**, load the feature plan from the docs directory:

```
docs/features/<feature_name>.md
```

Use the Read tool to load this file. All sections (screens, data model, API integrations, gamification hooks, decisions) come from this document — do not rely solely on conversation history. If the file does not exist, tell the user it hasn't been planned yet and suggest running `/plan-feature [feature_name]` first.

---

## Phase 1 — Draft Task Breakdown

Produce a numbered list of concrete, independently-shippable tasks. Each task should:
- Be actionable by a single developer
- Map to a clear deliverable (a file, a table, a screen, a function)
- Reference which other tasks it depends on, if any

For HoosierCiv features, typical task categories are:
1. **Database** — Supabase table, RLS, Dart model, repository stub
2. **Backend** — Supabase Edge Functions
3. **State** — Cubit + state files
4. **Screens** — one task per screen or major widget
5. **Integration** — wiring router, auth, navigation
6. **Seed data** — Supabase seed rows (missions, badges)
7. **Test** — `flutter analyze`, `dart format .`, smoke test

Present the breakdown to the user and wait for approval. Incorporate any changes the user requests before proceeding to Phase 2.

---

## Phase 2 — Create GitHub Issues

Only proceed after the user explicitly approves the task list.

### Step 1 — Resolve GitHub metadata

Ask the user for (or infer from context):
- **Milestone** name (e.g. "MVP", "Phase 2")
- **Label** name (e.g. "feature: onboarding")
- **Issue type** for the parent issue (default: "Feature")
- **Issue type** for sub-issues (default: "Task")

Check what already exists before creating:

```bash
# Check milestones
gh api repos/{owner}/{repo}/milestones --jq '.[].title'

# Check labels
gh label list --repo {owner}/{repo}

# Check available issue types
gh api graphql -f query='
query {
  organization(login: "{org}") {
    issueTypes(first: 10) {
      nodes { id name }
    }
  }
}'
```

Create the milestone and label if they do not exist:

```bash
gh api repos/{owner}/{repo}/milestones --method POST --field title="{milestone}"
gh label create "{label}" --repo {owner}/{repo} --color "0052CC"
```

### Step 2 — Create the parent issue

```bash
gh issue create \
  --repo {owner}/{repo} \
  --title "feat: {feature name}" \
  --label "{label}" \
  --milestone "{milestone}" \
  --body "..."
```

Parent issue body should include:
- Overview paragraph
- Flow diagram or bullet summary
- Key decisions table (from the plan conversation)
- Sub-issues checklist (to be filled in as issues are created)

Then set the issue type via GraphQL:

```bash
gh api graphql -f query='
mutation {
  updateIssue(input: { id: "{node_id}", issueTypeId: "{feature_type_id}" }) {
    issue { number issueType { name } }
  }
}'
```

### Step 3 — Create sub-issues

Create one GitHub issue per approved task. Each sub-issue should include:
- `## Context` — parent issue reference (`Parent: #{number}`) and any dependencies (`Depends on: #{number}`)
- `## Work` — bullet list of concrete deliverables
- `## Acceptance Criteria` — checkboxes the implementer can verify

After all issues are created, use Python (more reliable than shell array indexing in zsh) to:
1. Set type "Task" on each sub-issue via GraphQL `updateIssue`
2. Link each sub-issue to the parent via REST:

```python
import subprocess, json

for issue in issues:
    # Set type
    subprocess.run(["gh", "api", "graphql", "-f", f"query=mutation {{ updateIssue(input: {{ id: \"{issue['node_id']}\", issueTypeId: \"{task_type_id}\" }}) {{ issue {{ number }} }} }}"], ...)

    # Link as sub-issue
    subprocess.run(["gh", "api", f"repos/{repo}/issues/{parent_number}/sub_issues",
                    "--method", "POST", "--field", f"sub_issue_id={issue['db_id']}"], ...)
```

Get database IDs via: `gh api repos/{owner}/{repo}/issues/{number} --jq '.id'`

### Step 4 — Add all issues to the GitHub Project

Detect the active project for the org:

```bash
gh project list --owner {org} --format json --jq '.projects[] | {number: .number, title: .title, url: .url}'
```

If multiple projects exist, ask the user which one to use. If only one exists, use it automatically.

Add every issue (parent + all sub-issues) to the project:

```bash
for i in {issue_numbers}; do
  gh project item-add {project_number} --owner {org} \
    --url "https://github.com/{owner}/{repo}/issues/$i"
done
```

All items will land in the **Todo** column by default.

---

## Phase 3 — Report

Print a summary table of all created issues:

| Issue | Title | Type |
|---|---|---|
| #N | feat: {feature} | Feature |
| #N+1 | Task 1 title | Task |
| ... | ... | ... |

Confirm milestone, label, sub-issue linking, and project board are all applied. Include the project URL in the report.

$ARGUMENTS
