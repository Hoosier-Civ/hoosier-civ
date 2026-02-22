-- Migration: add_onboarding_to_profiles
-- Adds onboarding-specific fields to the existing profiles table.

alter table public.profiles
  add column zip_code             text,
  add column district_id          text,
  add column interests            text[] not null default '{}',
  add column onboarding_completed boolean not null default false;
