-- Migration: create_xp_events
-- Records every XP grant. Unique index prevents duplicate grants per source.

create table public.xp_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  source      text not null,      -- e.g. 'call-legislator', 'article_tap', 'article_read', 'quiz'
  source_ref  text,               -- article URL or mission_id — used for deduplication
  amount      integer not null check (amount > 0),
  created_at  timestamptz not null default now()
);

create index on public.xp_events(user_id);
create index on public.xp_events(user_id, created_at desc);

-- Prevent duplicate XP: one grant per user per source per source_ref
create unique index xp_events_dedup_idx
  on public.xp_events(user_id, source, source_ref)
  where source_ref is not null;

-- RLS
alter table public.xp_events enable row level security;

create policy "Users can view own XP events"
  on public.xp_events for select
  using (auth.uid() = user_id);

create policy "Users can insert own XP events"
  on public.xp_events for insert
  with check (auth.uid() = user_id);
