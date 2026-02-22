# Contributing to HoosierCiv

Thanks for helping build civic infrastructure for Indiana. This guide covers everything you need to run the app locally and submit contributions.

---

## Table of Contents

- [Contributing to HoosierCiv](#contributing-to-hoosierciv)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Project Overview](#project-overview)
  - [Environment Setup](#environment-setup)
    - [1. Clone the repo](#1-clone-the-repo)
    - [2. Install git hooks](#2-install-git-hooks)
    - [3. Flutter dependencies](#3-flutter-dependencies)
    - [4. Supabase (required)](#4-supabase-required)
    - [5. Firebase (optional for most work)](#5-firebase-optional-for-most-work)
      - [Option A: No Firebase (recommended for most contributors)](#option-a-no-firebase-recommended-for-most-contributors)
      - [Option B: Personal Firebase project](#option-b-personal-firebase-project)
      - [Option C: Firebase emulator](#option-c-firebase-emulator)
  - [Running the App](#running-the-app)
  - [What Requires Real Credentials](#what-requires-real-credentials)
  - [Code Style](#code-style)
  - [Branching Convention](#branching-convention)
  - [Submitting a PR](#submitting-a-pr)

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Flutter | >=3.0.0 | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| Dart | >=3.0.0 | Bundled with Flutter |
| Lefthook | latest | `brew install lefthook` |
| Supabase CLI | latest | `brew install supabase/tap/supabase` |
| Docker Desktop | latest | Required by Supabase local stack |
| Node.js + npm | >=18 | Only needed if testing Firebase emulator |
| Firebase CLI | latest | `npm install -g firebase-tools` (optional) |

---

## Project Overview

HoosierCiv uses two backend services:

| Service | Purpose | Local dev |
|---|---|---|
| **Supabase** | Auth, PostgreSQL database, Edge Functions (AI quizzes, news) | Full local stack via `supabase start` |
| **Firebase** | Push notifications (FCM) + Analytics only | Graceful no-op in debug; emulator optional |

Firebase is **not** the primary backend. Most feature work only requires Supabase running locally.

---

## Environment Setup

### 1. Clone the repo

```bash
git clone https://github.com/Hoosier-Civ/hoosier-civ.git
cd hoosier-civ
```

### 2. Install git hooks

HoosierCiv uses [Lefthook](https://github.com/evilmartians/lefthook) to enforce the [branch naming convention](#branching-convention) locally before a push reaches GitHub.

```bash
brew install lefthook
lefthook install
```

That's it — the `pre-push` hook is now active. If you try to push a branch with a non-conforming name you'll see exactly what's wrong and how to fix it before anything hits the remote.

### 3. Flutter dependencies

```bash
flutter pub get
```

### 4. Supabase (required)

Supabase runs a full local stack (Postgres, Auth, Edge Functions, Studio UI) via Docker.

**Start Docker Desktop first**, then:

```bash
supabase start
```

This prints your local credentials when ready:

```
API URL: http://localhost:54321
Studio:  http://localhost:54323
anon key: eyJ...
```

Copy `env.example.json` and fill in the local values:

```bash
cp env.example.json env.dev.json
```

Edit `env.dev.json`:

```json
{
  "SUPABASE_URL": "http://localhost:54321",
  "SUPABASE_ANON_KEY": "eyJ..."
}
```

`env.dev.json` is gitignored — never commit it.

**Edge Functions** (optional — only needed if working on AI quizzes or news aggregation):

```bash
cp .env.local.example .env.local   # if this file exists, otherwise create it
# Add your Anthropic API key:
# ANTHROPIC_API_KEY=sk-ant-...

supabase functions serve --env-file .env.local
```

See [`supabase/functions/README.md`](supabase/functions/README.md) for full Edge Functions docs.

### 5. Firebase (optional for most work)

Firebase is used only for **push notifications** (FCM) and **Analytics**. The app starts and runs without Firebase configured — the init is wrapped in a try/catch that silently skips it in dev.

**If you are not working on push notifications or analytics, skip this section entirely.**

#### Option A: No Firebase (recommended for most contributors)

No setup needed. The app runs fine. FCM calls will be skipped and Analytics events will be dropped silently in debug mode.

#### Option B: Personal Firebase project

If you need real FCM or Analytics:

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a free project.
2. Add an **Android app** with package name `com.hoosierciv.hoosierciv` and download `google-services.json`. Place it at `android/app/google-services.json`.
3. Add an **iOS app** with bundle ID `com.hoosierciv.hoosierciv` and download `GoogleService-Info.plist`. Place it at `ios/Runner/GoogleService-Info.plist`.
4. Enable **Cloud Messaging** and **Analytics** in the Firebase console.

Both files are gitignored. See the `.example` stubs in those directories for the expected structure.

#### Option C: Firebase emulator

Use this if you want to test push notification delivery end-to-end without a real Firebase project.

**Install the CLI and log in:**

```bash
npm install -g firebase-tools
firebase login
```

**Initialize emulators (one-time):**

```bash
firebase init emulators
```

Select only what you need — for HoosierCiv that's **Pub/Sub** and/or **Firebase Hosting** for the emulator UI. Skip Firestore, Functions, and Auth (those live in Supabase).

**Start the emulator:**

```bash
firebase emulators:start
```

Emulator UI is available at `http://localhost:4000`.

**Send a test push notification** via the emulator REST API:

```bash
curl -X POST http://localhost:9099/v1/projects/YOUR_PROJECT_ID/messages:send \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_FCM_TOKEN",
      "notification": { "title": "Test", "body": "Hello from the emulator!" }
    }
  }'
```

> Note: iOS simulators do not support push notifications. Use a physical device or Android emulator with Google Play Services for FCM testing.

---

## Running the App

```bash
flutter run --dart-define-from-file=env.dev.json
```

For a specific platform:

```bash
flutter run -d android --dart-define-from-file=env.dev.json
flutter run -d ios --dart-define-from-file=env.dev.json
```

---

## What Requires Real Credentials

| Feature | Credentials needed | Where to get them |
|---|---|---|
| Supabase local | Auto-generated by `supabase start` | Printed in terminal |
| AI quizzes / news Edge Functions | `ANTHROPIC_API_KEY` | [console.anthropic.com](https://console.anthropic.com) |
| Google Civic Info API | `GOOGLE_CIVIC_API_KEY` | [Google Cloud Console](https://console.cloud.google.com) |
| OpenStates API | `OPENSTATES_API_KEY` | [openstates.org/api](https://openstates.org/api/register/) |
| Firebase FCM/Analytics | `google-services.json` + `GoogleService-Info.plist` | Your personal Firebase project |

Most contributors only need the Supabase local stack and optionally an Anthropic key for quiz/news work.

---

## Code Style

- **State management:** flutter_bloc (Cubit pattern). Keep business logic out of widgets.
- **Linting:** `flutter_lints` is configured. Run `flutter analyze` before submitting.
- **Formatting:** `dart format .` — CI will reject unformatted code.
- **Generated files:** `*.g.dart` files are gitignored. Run `dart run build_runner build` to regenerate after modifying Hive models.

---

## Branching Convention

Branch names are validated automatically on PR open. Branches that don't follow the pattern will fail the check.

| Type | Pattern | When to use |
|---|---|---|
| Feature | `feat/issue-{number}-{short-description}` | New functionality tied to a GitHub issue |
| Bug fix | `fix/issue-{number}-{short-description}` | Bug fix tied to a GitHub issue |
| Chore | `chore/{short-description}` | Deps, config, tooling — no issue required |
| Docs | `docs/{short-description}` | Documentation only — no issue required |

**Examples:**

```bash
git checkout -b feat/issue-2-profiles-table
git checkout -b feat/issue-6-interest-select-screen
git checkout -b fix/issue-9-router-redirect-loop
git checkout -b chore/upgrade-flutter-dependencies
```

The issue number in the branch name is what drives Kanban automation — when you push a branch, the linked issue automatically moves to **In Progress** on the project board.

---

## Submitting a PR

1. Pick an issue from the [project board](https://github.com/orgs/Hoosier-Civ/projects/1) and self-assign it
2. Create a branch following the [naming convention](#branching-convention): `git checkout -b feat/issue-{number}-{description}`
3. Make your changes, run `flutter analyze` and `dart format .`
4. Open a pull request against `main` — the issue will move to **In Review** automatically
5. Once merged, the issue closes and moves to **Done** automatically

Please do not commit `env.dev.json`, `google-services.json`, `GoogleService-Info.plist`, or any file containing real API keys.
