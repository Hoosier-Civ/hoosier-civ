-- Migration: create_mission_completions

create table public.mission_completions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  mission_id  text not null references public.missions(id),
  completed_at timestamptz not null default now(),
  proof_url   text,
  created_at  timestamptz not null default now()
);

create index on public.mission_completions(user_id);
create index on public.mission_completions(mission_id);
create index on public.mission_completions(user_id, completed_at desc);

-- RLS
alter table public.mission_completions enable row level security;

create policy "Users can view own completions"
  on public.mission_completions for select
  using (auth.uid() = user_id);

create policy "Users can insert own completions"
  on public.mission_completions for insert
  with check (auth.uid() = user_id);
