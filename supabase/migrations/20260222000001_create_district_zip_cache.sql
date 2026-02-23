-- Migration: create_district_zip_cache
-- Shared ZIP→district lookup cache populated by the lookup-district Edge Function.
-- No user-scoped data; the Edge Function writes via service role (bypasses RLS).

create table public.district_zip_cache (
  zip_code      text primary key,
  district_id   text not null,
  representatives jsonb not null default '[]'::jsonb,
  cached_at     timestamptz not null default now()
);

alter table public.district_zip_cache
  add constraint district_zip_cache_zip_code_format_chk
  check (zip_code ~ '^[0-9]{5}$');
-- RLS on — service role writes bypass it; no public read needed.
alter table public.district_zip_cache enable row level security;
