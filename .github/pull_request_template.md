## What does this PR do?

<!-- Brief description of the change and why it's needed -->

## Type of change

- [ ] Bug fix
- [ ] New feature — Phase 1 (MVP)
- [ ] New feature — Phase 2 / Phase 3
- [ ] Infrastructure / database change
- [ ] Documentation
- [ ] Refactor / cleanup

## Testing

- [ ] `flutter test` passes locally
- [ ] `dart analyze --fatal-infos` passes with no errors
- [ ] Manually tested on iOS Simulator
- [ ] Manually tested on Android Emulator
- [ ] If IaC change: `tofu plan` output reviewed and pasted below

<details>
<summary>tofu plan output (if applicable)</summary>

```
paste here
```
</details>

## Checklist

- [ ] No secrets, API keys, or credentials committed
- [ ] No hardcoded strings (use constants file or l10n)
- [ ] RLS policy added/updated if a new Supabase table or access pattern introduced
- [ ] Migration file created if schema changed
- [ ] `seed.sql` updated if new reference data added (missions, badges)
- [ ] XP values match `HoosierCiv_XP_Badge_System.txt`
- [ ] Badge names match canonical names in `HoosierCiv_XP_Badge_System.txt`
- [ ] Feature is gated to correct phase (`is_active = false` if Phase 2/3)
