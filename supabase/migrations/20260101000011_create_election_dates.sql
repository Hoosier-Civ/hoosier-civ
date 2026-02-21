-- Migration: create_election_dates
-- Configurable list of valid election days. Used to gate the voter sticker mission.
-- Maintained by maintainers via Supabase dashboard or seeding.

create table public.election_dates (
  id             uuid primary key default gen_random_uuid(),
  election_date  date not null unique,
  description    text not null,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now()
);

-- RLS
alter table public.election_dates enable row level security;

create policy "Election dates are publicly readable"
  on public.election_dates for select
  using (true);
