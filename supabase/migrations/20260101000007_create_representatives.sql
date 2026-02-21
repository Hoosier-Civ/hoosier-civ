-- Migration: create_representatives
-- Cached per-user lookup from Google Civic Info API. Refreshed on demand.

create table public.representatives (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  name       text not null,
  chamber    text not null check (chamber in ('house', 'senate', 'us_house', 'us_senate')),
  district   text not null,
  phone      text,
  email      text,
  party      text,
  fetched_at timestamptz not null default now()
);

create index on public.representatives(user_id);

-- RLS
alter table public.representatives enable row level security;

create policy "Users can view own representatives"
  on public.representatives for select
  using (auth.uid() = user_id);

create policy "Users can insert own representatives"
  on public.representatives for insert
  with check (auth.uid() = user_id);

create policy "Users can update own representatives"
  on public.representatives for update
  using (auth.uid() = user_id);

create policy "Users can delete own representatives"
  on public.representatives for delete
  using (auth.uid() = user_id);
