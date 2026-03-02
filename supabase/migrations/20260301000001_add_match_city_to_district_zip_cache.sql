-- Migration: add_match_city_to_district_zip_cache
-- Stores the Cicero candidate.match_city so cache hits can return the city
-- without hitting Cicero again.

alter table public.district_zip_cache
  add column match_city text;
