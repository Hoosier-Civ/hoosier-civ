# Feature Plan: Onboarding

**Status:** Issues created — [#1](https://github.com/Hoosier-Civ/hoosier-civ/issues/1)
**Milestone:** MVP
**Label:** feature: onboarding

---

## Overview

Implement the full first-run onboarding experience for HoosierCiv. Gates all P1 missions — users must complete onboarding before accessing the home feed.

## Flow

```
Welcome → ZIP entry → Interest selection → Email → Magic link → Home
```

---

## 1. Problem & User Stories

> **As a** first-time Indiana civic newcomer,
> **I want to** understand what HoosierCiv does on first launch,
> **so that** I know it's worth creating an account.

> **As a** new user,
> **I want to** enter my Indiana ZIP code,
> **so that** the app can show me my local representatives and relevant bills.

> **As a** new user,
> **I want to** pick my civic interests (voting, legislation, community),
> **so that** my mission feed feels relevant rather than generic.

---

## 2. Screens & Navigation

| Screen | Route | Entry | Notes |
|---|---|---|---|
| `OnboardingScreen` | `/onboarding` | App launch (first run only) | Welcome splash with Indy the Cardinal, "Let's Go" CTA — stub exists, needs real UI |
| `AddressVerificationScreen` | `/onboarding/address` | From OnboardingScreen | Indiana ZIP input, validation, `lookup-district` Edge Function call |
| `InterestSelectScreen` | `/onboarding/interests` | From AddressVerificationScreen | Icon + label card grid, multi-select |
| `AuthScreen` | `/onboarding/auth` | From InterestSelectScreen | Email input, Supabase magic link send |

After magic link confirmed → save `profiles` row + Hive flag → push to `/home`.

---

## 3. Data Model

**New table: `profiles`** (user-owned)

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid PK` | = `auth.uid()` |
| `zip_code` | `text` | Indiana ZIP |
| `district_id` | `text` | from `lookup-district` Edge Function |
| `interests` | `text[]` | selected category slugs |
| `onboarding_completed` | `bool default false` | |
| `created_at` | `timestamptz` | |

**Local Hive key:** `onboarding_complete` (bool) — checked on launch to skip onboarding without a network call.

**New state files:**
- `lib/features/onboarding/onboarding_cubit.dart`
- `lib/features/onboarding/onboarding_state.dart`

States: `OnboardingInitial → OnboardingAddressLoading → OnboardingAddressVerified → OnboardingInterestsSelected → OnboardingAuthPending → OnboardingComplete → OnboardingError`

---

## 4. API Integrations

| API | Purpose | Implementation |
|---|---|---|
| Google Civic Info API | ZIP → district ID + representatives | Server-side via `lookup-district` Supabase Edge Function — key never in Flutter binary |
| Supabase Auth | Magic link sign-up / session management | `supabase_flutter` package, `supabase.auth.signInWithOtp()` |

**Edge Function:** `supabase/functions/lookup-district/index.ts`
- Accepts `{ zip_code: string }`
- Checks `district_zip_cache` table (90-day TTL, configurable via `DISTRICT_CACHE_TTL_DAYS` secret)
- Falls back to Google Civic Info API on cache miss or stale hit
- Returns `{ district_id, representatives[] }`

**Cache table: `district_zip_cache`**

| Column | Type |
|---|---|
| `zip_code` | `text PK` |
| `district_id` | `text` |
| `representatives` | `jsonb` |
| `cached_at` | `timestamptz` |

---

## 5. Gamification Hooks

| Trigger | XP | Badge | Mission ID |
|---|---|---|---|
| Complete onboarding | +5 | none | `onboarding_complete` |

Completion type: `in_app_action`. Awarded exactly once per user via `GamificationCubit` when `OnboardingComplete` state is emitted.

**Indy copy:** "Welcome to Indiana's civic squad! Indy is so glad you're here. Let's make Hoosier history together!"

---

## 6. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Auth timing | Email / magic link as the **final** onboarding step |
| 2 | Address precision | **ZIP code only** — no full street address |
| 3 | Returning users | **Skip onboarding** — check Hive flag + Supabase session on launch |
| 4 | Interests UI | **Icon + label card grid** (2-column, multi-select) |

---

## 7. Implementation Checklist

- [ ] #2 — Create `profiles` Supabase table, model, and repository
- [ ] #3 — Create `lookup-district` Edge Function with ZIP cache
- [ ] #4 — Scaffold onboarding cubit and state
- [ ] #5 — Implement OnboardingScreen (welcome splash)
- [ ] #6 — Implement AddressVerificationScreen
- [ ] #7 — Implement InterestSelectScreen
- [ ] #8 — Implement email / magic link auth step
- [ ] #9 — Wire router and UserCubit to Supabase auth state
- [ ] #10 — Seed onboarding completion mission
- [ ] #11 — Test onboarding flow end-to-end
