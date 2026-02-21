-- Migration: create_user_badges
-- Junction table. Unique constraint ensures badges are earned once permanently.

create table public.user_badges (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null references auth.users(id) on delete cascade,
  badge_id  text not null references public.badges(id),
  earned_at timestamptz not null default now(),
  unique (user_id, badge_id)
);

create index on public.user_badges(user_id);
create index on public.user_badges(user_id, earned_at desc);

-- RLS
alter table public.user_badges enable row level security;

create policy "Users can view own badges"
  on public.user_badges for select
  using (auth.uid() = user_id);

create policy "Users can insert own badges"
  on public.user_badges for insert
  with check (auth.uid() = user_id);
