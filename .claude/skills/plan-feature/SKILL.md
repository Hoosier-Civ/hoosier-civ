---
name: plan-feature
description: Plan a new HoosierCiv feature end-to-end — produces user stories, screen list, data model, API needs, gamification hooks, and a phased implementation checklist. Run this before scaffold-feature or supabase-schema.
argument-hint: "[feature idea or description]"
disable-model-invocation: true
---

# Plan HoosierCiv Feature

Produce a complete implementation plan for a new HoosierCiv feature before any code is written.

## Instructions

The user will describe a feature idea (e.g. "bill tracking", "town hall locator", "voter registration status").

1. Read `Indiana_Civic_App_Core_Civic_Actions.txt` to see if this feature maps to an existing civic action category.
2. Read `HoosierCiv_Flutter_MVP_Architecture.txt` to understand existing screens, models, and routing — avoid duplicating what's already there.
3. Read `HoosierCiv_XP_Badge_System.txt` to identify gamification opportunities for this feature.

Then produce the following plan:

---

### 1. Problem & User Story

> **As a** [Indiana resident / young voter / civic newcomer],
> **I want to** [do something],
> **so that** [civic outcome].

Include 1–3 user stories. Be specific about the Indiana context.

### 2. Screens & Navigation

List every screen or bottom sheet this feature needs:

| Screen | Route name | Entry point | Notes |
|---|---|---|---|
| `FeatureScreen` | `/feature` | Bottom nav / deep link | ... |

### 3. Data Model

For each new Supabase table needed:

| Table | Key columns | RLS pattern |
|---|---|---|
| `table_name` | `id, user_id, ...` | user-owned / public read |

Flag any existing tables that need new columns rather than a new table.

### 4. API Integrations

List any external APIs this feature requires:

| API | Purpose | Existing service? |
|---|---|---|
| Google Civic Info | ... | yes / no |

If a new service is needed, note it for `/api-integration`.

### 5. Gamification Hooks

List every XP / badge / mission opportunity this feature creates. Use canonical values from `HoosierCiv_XP_Badge_System.txt`:

| Trigger | XP | Badge | Mission ID |
|---|---|---|---|
| User completes X | +10 | "Voter" | `vote_lookup` |

### 6. Implementation Checklist

Ordered steps to ship this feature, with the skill to invoke for each:

- [ ] **Database** — Run `/supabase-schema [entity]` for each new table
- [ ] **Missions** — Run `/add-mission [description]` for each gamification hook
- [ ] **Scaffold** — Run `/scaffold-feature [feature_name]` to generate Flutter files
- [ ] **API** — Run `/api-integration [service]` if a new external API is needed
- [ ] **Wire router** — Add route to GoRouter in `lib/router.dart`
- [ ] **Connect navigation** — Add entry point (bottom nav tab, card button, etc.)
- [ ] **Seed data** — Add any required Supabase seed rows (missions, badges)
- [ ] **Test** — `flutter analyze && dart format .`

### 7. Open Questions

List any decisions that need product or design input before implementation starts. For example:
- Is this MVP or a later phase?
- Does this require a new bottom nav tab or is it reachable from an existing screen?
- Are there privacy considerations (e.g. storing voter registration data)?

---

## Output

Produce all seven sections. Keep it scannable — use tables and bullets over prose. End with a clear recommendation on which checklist step to tackle first and which skill to invoke.

---

## Saving the Plan

After all open questions in section 7 are resolved (either in this conversation or follow-up), save the final plan to:

```
docs/features/<feature_name>.md
```

The saved file should include:
- All seven sections with final decisions filled in (not placeholders)
- A **Decisions** table capturing every open question and its resolved answer
- GitHub issue links in the Implementation Checklist if `/task-breakdown` has been run

Use the Write tool to create the file. Confirm the path to the user when done.

After confirming the save, ask the user:

> "Would you like to run `/task-breakdown [feature_name]` now to turn this plan into GitHub issues?"

Wait for their response before doing anything further.

$ARGUMENTS
