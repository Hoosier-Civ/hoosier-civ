# Add Civic Mission

Define and scaffold a new civic mission for the HoosierCiv gamification system.

## Instructions

The user will describe a new mission (e.g. "Attend a town hall", "Email your senator").

1. Read `Indiana_Civic_App_Core_Civic_Actions.txt` to check if the mission fits an existing category.
2. Read `HoosierCiv_Flutter_MVP_Architecture.txt` for the `Mission` model shape.
3. Produce the following:

### Mission Definition (JSON — for seeding Supabase)
```json
{
  "id": "<slug>",
  "title": "<Mission Title>",
  "description": "<1–2 sentence user-facing description>",
  "category": "<Legislative | Voting | Community | Education>",
  "xp_reward": <number>,
  "completion_type": "<self_report | api_verified | photo_upload | quiz>",
  "badge_awarded": "<Badge Name or null>",
  "streak_eligible": true,
  "difficulty": "<easy | medium | hard>"
}
```

### XP Guidelines
- Easy (read/click): 5–10 XP
- Medium (quiz, email): 15–20 XP
- Hard (call, attend, volunteer): 25–30 XP

### Flutter Mission Card Scaffold
Generate a `MissionCard` widget variant or note how to configure the existing `mission_card.dart` for this mission type.

### Gamification Copy
Write Indy the Cardinal's celebration message (1–2 sentences, enthusiastic, Indiana-flavored) shown on mission completion.

## Output
- Supabase seed JSON
- Flutter widget notes
- Indy celebration copy
- Any new badge definition needed

$ARGUMENTS
