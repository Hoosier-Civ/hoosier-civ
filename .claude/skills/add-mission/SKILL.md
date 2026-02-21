---
name: add-mission
description: Define and scaffold a new civic mission for the HoosierCiv gamification system — produces Supabase seed JSON, Flutter widget notes, and Indy the Cardinal copy. Use when adding a mission to the app.
argument-hint: "[mission-description]"
disable-model-invocation: true
---

# Add Civic Mission

Define and scaffold a new civic mission for the HoosierCiv gamification system.

## Instructions

The user will describe a new mission (e.g. "Attend a town hall", "Email your senator").

1. Read `Indiana_Civic_App_Core_Civic_Actions.txt` to check if the mission fits an existing category.
2. Read `HoosierCiv_XP_Badge_System.txt` for canonical XP values and badge names.
3. Read `HoosierCiv_Flutter_MVP_Architecture.txt` for the `Mission` model shape.
4. Produce the following:

### Mission Definition (JSON — for seeding Supabase)
```json
{
  "id": "<slug>",
  "title": "<Mission Title>",
  "description": "<1–2 sentence user-facing description>",
  "category": "<Legislative | Voting | Community | Education>",
  "xp_reward": <number>,
  "completion_type": "<self_report | api_verified | photo_upload | quiz | gps_checkin | in_app_action>",
  "badge_awarded": "<Badge Name or null>",
  "streak_eligible": true,
  "difficulty": "<easy | medium | hard>",
  "phase": <1 | 2 | 3>
}
```

### XP Guidelines (from HoosierCiv_XP_Badge_System.txt)
- Easy (read/click/tap): 5–10 XP
- Medium (quiz, email): 15–20 XP
- Hard (call, attend, volunteer, photo upload): 25–30 XP

### Flutter Mission Card Scaffold
Generate a `MissionCard` widget variant or note how to configure the existing `mission_card.dart` for this mission type.

### Gamification Copy
Write Indy the Cardinal's celebration message (1–2 sentences, enthusiastic, Indiana-flavored) shown on mission completion.

## Output
- Supabase seed JSON
- Flutter widget notes
- Indy celebration copy
- Any new badge definition needed (use exact canonical badge names from HoosierCiv_XP_Badge_System.txt)

$ARGUMENTS
