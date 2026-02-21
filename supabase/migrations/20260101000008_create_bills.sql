-- Migration: create_bills
-- Indiana bills tracked in the app. Populated by the aggregate-news Edge Function
-- and manual seeding. Public read only.

create table public.bills (
  id              text primary key,  -- e.g. 'IN-HB-1234-2024'
  title           text not null,
  summary         text,
  status          text not null,
  session         text not null,
  sponsors        jsonb not null default '[]',
  last_action     text,
  last_action_date date,
  openstates_id   text unique,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index on public.bills(session);
create index on public.bills(status);
create index on public.bills(last_action_date desc);

create trigger bills_updated_at
  before update on public.bills
  for each row execute function public.handle_updated_at();

-- RLS
alter table public.bills enable row level security;

create policy "Bills are publicly readable"
  on public.bills for select
  using (true);
