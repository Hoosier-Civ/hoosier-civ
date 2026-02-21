-- Migration: create_badges
-- Badge definitions are app-managed (seeded). Public read only.

create table public.badges (
  id          text primary key,   -- slug, e.g. 'voter-verified'
  name        text not null unique,
  description text not null,
  icon_asset  text not null,      -- Flutter asset path, e.g. 'assets/badges/voter_verified.png'
  phase       integer not null check (phase in (1, 2, 3)),
  created_at  timestamptz not null default now()
);

-- RLS
alter table public.badges enable row level security;

create policy "Badges are publicly readable"
  on public.badges for select
  using (true);
