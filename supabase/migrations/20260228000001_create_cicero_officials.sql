-- Migration: create_cicero_officials
-- Normalized cache of officials from the Cicero API (shared, not user-scoped).
-- One row per Cicero official ID. Populated by the lookup-district Edge Function.
-- US Senators (etc.) are stored once and linked to many ZIP codes via zip_cicero_officials.

create table public.cicero_officials (
  -- Cicero's own immutable integer ID for this official record
  cicero_id           integer primary key,

  -- Name fields
  first_name          text not null,
  last_name           text not null,
  middle_initial      text,
  salutation          text,
  nickname            text,
  preferred_name      text,
  name_suffix         text,

  -- Office / district classification
  office_title        text,  -- office.title e.g. "Senator", "Governor", "Secretary of the Treasury"
  district_type       text,  -- office.district.district_type e.g. "NATIONAL_UPPER", "STATE_LOWER", "LOCAL"
  district_ocd_id     text,  -- office.district.ocd_id e.g. "ocd-division/country:us/state:in"
  district_state      text,  -- office.district.state e.g. "IN"
  district_city       text,  -- office.district.city (populated for LOCAL / LOCAL_EXEC officials)
  district_label      text,  -- office.district.label e.g. "Indiana", "Hamilton County"
  chamber_name        text,  -- office.chamber.name e.g. "Senate", "House"
  chamber_name_formal text,  -- office.chamber.name_formal e.g. "United States Senate"
  chamber_type        text,  -- office.chamber.type e.g. "UPPER", "LOWER", "EXEC"

  -- Personal / contact
  party               text,
  photo_url           text,  -- photo_origin_url
  website_url         text,  -- urls[0]
  web_form_url        text,

  -- Term dates
  term_start_date     date,  -- current_term_start_date
  term_end_date       date,  -- term_end_date

  -- Biography (from Cicero's notes array)
  bio                 text,  -- notes[0]: long-form biographical text
  birth_date          date,  -- notes[1]: ISO date string when present

  -- Rich data kept as JSONB to preserve full structure
  addresses           jsonb not null default '[]'::jsonb,
  -- Each element: { address_1, address_2, address_3, city, county, state, postal_code,
  --                 phone_1, fax_1, phone_2, fax_2 }

  email_addresses     jsonb not null default '[]'::jsonb,
  -- Array of email address strings

  committees          jsonb not null default '[]'::jsonb,
  -- Each element: { name, urls, position, committee_identifiers }

  identifiers         jsonb not null default '[]'::jsonb,
  -- Each element: { identifier_type, identifier_value }
  -- Known types: TWITTER, FACEBOOK, FACEBOOK-CAMPAIGN, FACEBOOK-OFFICIAL,
  --              INSTAGRAM, INSTAGRAM-CAMPAIGN, YOUTUBE, LINKEDIN,
  --              BIOGUIDE, FEC, CRP, VOTESMART, GOVTRACK, GOVTRACK-COMMITTEE

  -- Cache metadata
  cicero_valid_to     timestamptz,  -- mirrors Cicero's valid_to; used to know when to re-fetch this official
  cached_at           timestamptz not null default now()
);

-- No RLS writes needed — service role bypasses it.
-- Allow public SELECT so the app can read officials without auth overhead.
alter table public.cicero_officials enable row level security;

create policy "Anyone can read cicero_officials"
  on public.cicero_officials for select
  using (true);

-- Indexes for the most common query patterns
create index on public.cicero_officials (district_type);
create index on public.cicero_officials (district_ocd_id);
create index on public.cicero_officials (district_state);


-- ---------------------------------------------------------------------------
-- Join table: ZIP codes → officials (many-to-many)
--
-- A US Senator appears for every Indiana ZIP code.
-- A city councilor appears for just a handful.
-- Storing the relationship here avoids duplicating the large official row.
-- ---------------------------------------------------------------------------

create table public.zip_cicero_officials (
  zip_code  text    not null references public.district_zip_cache (zip_code) on delete cascade,
  cicero_id integer not null references public.cicero_officials (cicero_id)  on delete cascade,
  primary key (zip_code, cicero_id)
);

create index on public.zip_cicero_officials (zip_code);
create index on public.zip_cicero_officials (cicero_id);
