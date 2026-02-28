-- Migration: update_district_zip_cache
-- Drop the denormalized representatives blob now that official data lives in
-- cicero_officials + zip_cicero_officials.
-- Add geocoding columns from Cicero's candidate response so we can surface
-- the matched address and coordinates to the client if needed.

alter table public.district_zip_cache
  drop column representatives;

alter table public.district_zip_cache
  add column match_addr  text,           -- Cicero candidate.match_addr
  add column geocode_lat double precision, -- Cicero candidate.y (latitude)
  add column geocode_lon double precision; -- Cicero candidate.x (longitude)
