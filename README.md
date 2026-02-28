# HoosierCiv

A mobile civic engagement app for Indiana residents — built for Gen Z and Millennials who want to participate in democracy without the friction.

HoosierCiv turns everyday civic actions (calling your legislator, checking your voter registration, reading a bill) into a gamified experience with XP, badges, streaks, and Indy the Cardinal as your guide.

---

## Target Audience

Indiana residents aged 18–45 who are civically curious but not yet civically active. The app meets them where they are: short missions, instant rewards, and zero political jargon.

---

## Tech Stack

| Layer            | Technology                                      |
|------------------|-------------------------------------------------|
| Mobile           | Flutter (iOS + Android)                         |
| State management | flutter_bloc (Cubit)                            |
| Backend          | Supabase (auth, PostgreSQL, Edge Functions)     |
| Civic data       | Cicero API (officials), OpenStates API (bills)  |
| News             | Google News RSS                                 |
| AI (quizzes)     | Anthropic Claude API (Haiku)                    |
| ML (on-device)   | tflite_flutter (voter sticker detection)        |
| Notifications    | Firebase Cloud Messaging                        |
| Analytics        | Firebase Analytics                              |
| Local cache      | hive                                            |
| Social sharing   | share_plus (native share sheet)                 |

---

## MVP Screens (Phase 1)

1. Onboarding — Indiana ZIP verification, representative lookup
2. Home — Daily missions, XP bar, streak counter, Indy mascot
3. Call Your Legislator — Pre-written talking points, one-tap dialer
4. Check Voter Registration — Indiana portal link, completion confirm
5. Bill Detail + RSS — Bill summary, news feed, Claude-generated quiz
6. Profile — Badges, XP history, streak record

---

## Documentation

| Document | Description |
|---|---|
| [`supabase/functions/README.md`](supabase/functions/README.md) | Edge Functions overview, local dev quickstart, and deployment |
| [`HoosierCiv_Flutter_MVP_Architecture.txt`](HoosierCiv_Flutter_MVP_Architecture.txt) | Folder structure, data models, services, packages, gamification engine |
| [`HoosierCiv_XP_Badge_System.txt`](HoosierCiv_XP_Badge_System.txt) | All XP values, badge definitions, level formula, streak rules |
| [`HoosierCiv_Technical_Decisions.txt`](HoosierCiv_Technical_Decisions.txt) | Auth, APIs, ML, caching, privacy — every implementation decision |
| [`HoosierCiv_Phase_Roadmap.txt`](HoosierCiv_Phase_Roadmap.txt) | Phase 1/2/3 scope and feature breakdown |
| [`Indiana_Civic_App_Core_Civic_Actions.txt`](Indiana_Civic_App_Core_Civic_Actions.txt) | All missions with XP, difficulty, phase, and completion type |
| [`Indiana_Civic_App_Voter_Verification_Flow.txt`](Indiana_Civic_App_Voter_Verification_Flow.txt) | Voter sticker photo verification flow with ML and EXIF details |
| [`Indiana_Civic_App_Bill_News_RSS.txt`](Indiana_Civic_App_Bill_News_RSS.txt) | Bill news feed, Claude quiz generation, article XP rules |
