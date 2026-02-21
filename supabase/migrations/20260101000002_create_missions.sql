-- Migration: create_missions
-- Missions are app-managed (seeded), not user-created. Public read only.

create table public.missions (
  id              text primary key,  -- slug, e.g. 'call-legislator'
  title           text not null,
  description     text not null,
  category        text not null check (category in ('Legislative', 'Voting', 'Community', 'Education')),
  xp_reward       integer not null check (xp_reward > 0),
  completion_type text not null check (completion_type in (
    'self_report', 'api_verified', 'photo_upload', 'quiz', 'gps_checkin', 'in_app_action'
  )),
  badge_awarded   text,
  streak_eligible boolean not null default true,
  difficulty      text not null check (difficulty in ('easy', 'medium', 'hard')),
  phase           integer not null check (phase in (1, 2, 3)),
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);

-- RLS — missions are publicly readable; writes are restricted to service role
alter table public.missions enable row level security;

create policy "Missions are publicly readable"
  on public.missions for select
  using (true);
