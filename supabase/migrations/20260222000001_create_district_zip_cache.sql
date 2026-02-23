-- Migration: create_district_zip_cache
-- Shared ZIP→district lookup cache populated by the lookup-district Edge Function.
-- No user-scoped data; the Edge Function writes via service role (bypasses RLS).

create table public.district_zip_cache (
  zip_code      text primary key,
  district_id   text not null,
  representatives jsonb not null default '[]',
  cached_at     timestamptz not null default now()
);

-- RLS on — service role writes bypass it; no public read needed.
alter table public.district_zip_cache enable row level security;
